package Wunder::Framework::Billing;

use Moose;
use Modern::Perl;

use Math::Round qw( nearest );
use Wunder::Framework::Tools::Toolkit qw( zeropad moneypad );
use Wunder::Framework::Billing::Prorate;

has 'monthly_rate' => ( isa => 'Num', is => 'ro', required => 1 );
has 'months'       => ( isa => 'Num', is => 'ro', required => 1 );
has 'rollover_day' => ( isa => 'Num', is => 'ro', required => 1 );
has 'start_date' => ( isa => 'DateTime', is => 'ro', required => 1 );

=head2 prorate

Assumes that the initial payment is due today and that the following payment
must be moved to the 1st if it is not already scheduled for this date.

IF $today < $rollover_day THEN bill prorated for this month.
IF $today >=$rollover day THEN bill prorated for this month + 1 additional
month

Returns a read-only Wunder::Framework::Billing::Prorate object if prorating is
required.   Otherwise returns undef.

=cut

sub prorate {

    my $self = shift;

    my $start_date   = $self->start_date;
    my $next_payment = $start_date->clone;
    my $partial      = 0;

    return if $start_date->day == 1;

    # all subsequent payments will be, at the very earliest, on the 1st of
    # the following month.
    $next_payment->truncate( to => 'month' )->add( months => 1 );

    my $last_day = DateTime->last_day_of_month(
        year  => $start_date->year,
        month => $start_date->month,
    )->day;

    $partial = ( $last_day - ( $start_date->day - 1 ) ) / $last_day;

    ## bill for the extra days and set base for next payment to the first
    ## of next month
    if (   $self->months == 1
        && $start_date->day > $self->rollover_day )
    {
        $next_payment->add( months => 1 );
        $partial += 1;
    }

    # if we're looking at 6 or 12 months, default to a period slightly
    # less than the original term so that the client is not charged more
    # than she had been expecting to pay
    elsif ( $partial > 0 ) {
        my $additional_months = $self->months - 1;
        $next_payment->add( months => $additional_months );
        $partial += $additional_months;
    }

    return Wunder::Framework::Billing::Prorate->new(
        amount       => moneypad( $partial * $self->monthly_rate ),
        months       => $partial,
        monthly_rate => $self->monthly_rate,
        next_payment => $next_payment,
        rollover_day => $self->rollover_day,
        start_date   => $start_date,
    );

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
