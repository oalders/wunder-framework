package Wunder::Framework::Billing;

use Moose;
use MooseX::Params::Validate;

extends qw( Wunder::Framework::CAP::Super );

use Math::Round qw( nearest );
use Modern::Perl;
use Params::Validate qw( validate SCALAR );
use Wunder::Framework::Tools::Toolkit qw( zeropad moneypad );

=head2 prorate( rollover_day => 15, start_date => $datetime )

Assumes that the initial payment is due today and that the following payment
must be moved to the 1st if it is not already scheduled for this date.

IF $today < $rollover_day THEN bill prorated for this month.
IF $today >=$rollover day THEN bill prorated for this month + 1 additional
month

Returns
{
    next_payment    => $datetime,
    prorated_amount => $x, # before tax
}

=cut

sub prorate {

    my $self = shift;

    my %rules = (
        monthly_rate => { isa => 'Num', },
        months       => { isa => 'Num', },
        rollover_day => {
            isa      => 'Str',
            optional => 1,
            default  => $self->config->{'billing'}->{'rollover_day'} || 15,
        },
        round => { optional => 1, default => 1, isa => 'Num', },
        start_date => { isa => 'DateTime', },
    );

    my %args = validated_hash( \@_, %rules );

    my $start_date   = $args{'start_date'};
    my $next_payment = $start_date->clone;
    my $partial      = 0;

    if ( $start_date->day != 1 ) {

        # all subsequent payments will be, at the very earliest, on the 1st of
        # the following month.
        $next_payment->truncate( to => 'month' )->add( months => 1 );

        my $last_day = DateTime->last_day_of_month(
            year  => $start_date->year,
            month => $start_date->month,
        )->day;

        $partial = ( $last_day - $start_date->day ) / $last_day;

        ## bill for the extra days and set base for next payment to the first
        ## of next month
        if (   $args{'months'} == 1
            && $start_date->day > $args{'rollover_day'} )
        {
            $next_payment->add( months => 1 );
            $partial += 1;
        }

        # if we're looking at 6 or 12 months, default to a period slightly
        # less than the original term so that the client is not charged more
        # than she had been expecting to pay
        elsif ( $partial > 0 ) {
            my $additional_months = $args{'months'} - 1;
            $next_payment->add( months => $additional_months );
            $partial += $additional_months;
        }

        $partial = nearest( 0.01, $partial ) if $args{'round'};

    }

    return {
        amount       => moneypad( $partial * $args{'monthly_rate'} ),
        months       => $partial,
        monthly_rate => $args{'monthly_rate'},
        next_payment => $next_payment,
        start_date   => $start_date,
        rollover_day => $args{'rollover_day'},
        }

}

=head1 AUTHOR

    Olaf Alders
    CPAN ID: OALDERS
    WunderCounter.com
    olaf@wundersolutions.com
    http://www.wundercounter.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
