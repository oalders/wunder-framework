package Wunder::Framework::Billing;

use Moose;
use MooseX::Params::Validate;

extends qw( Wunder::Framework::CAP::Super );

use Business::PayPal::API qw( ExpressCheckout GetTransactionDetails );
use Data::Dump qw( dump );
use DateTime;
use DateTime::Format::ISO8601;
use Math::Round qw( nearest );
use Modern::Perl;
use Params::Validate qw( validate SCALAR );
use Wunder::Framework::Tools::Toolkit qw( zeropad moneypad );

=head2 new_invoice( $client )

Provides a brand new invoice to the caller, with a new invoice number.

=cut

sub new_invoice {

    my $self   = shift;
    my $client = shift;
    my $config = $self->config;
    my $number = $client->create_related( 'invoice_number', {} );

    my $inv_conf = $config->{'invoice'};

    if ( $number->invoice_numberid < $inv_conf->{'start'} ) {
        $number->invoice_numberid( $inv_conf->{'start'} );
        $number->update;
    }

    my $invoice_number = $inv_conf->{'prefix'}
        . zeropad(
        number => $number->invoice_numberid,
        limit  => $inv_conf->{'pad_digits'},
        );

    my $invoice
        = $client->create_related( 'invoice', { number => $invoice_number } );

    return $invoice;

}

=head2 get_pp

Returns an Business::PayPal::API::ExpressCheckout object

=cut

sub get_pp {

    my $self = shift;
    my $api  = $self->config->{'payment_source'}->{'paypal'}->{'api'};

    ## see Business::PayPal::API documentation for parameters
    my $pp = Business::PayPal::API->new(
        Username  => $api->{'username'},
        Password  => $api->{'password'},
        Signature => $api->{'signature'},
        sandbox   => $api->{'sandbox'},
    );

    return $pp;
}

=head2 update_paypal_txn

Given a PayPal txn, update it in the transaction table. "invoice" param
requires invoiceid.

=cut

sub update_paypal_txn {

    my $self = shift;

    my %rules = (
        auth_currency => { type => SCALAR },
        invoice       => { type => SCALAR },
        txn_id        => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );
    my $config = $self->config;

    my $api = $config->{'payment_source'}->{'paypal'}->{'api'};

    my $pp = $self->get_pp;
    my %txn = $pp->GetTransactionDetails( TransactionID => $args{'txn_id'} );

    my $txn_dt
        = DateTime::Format::ISO8601->parse_datetime( $txn{'PaymentDate'} );
    $txn_dt->set_time_zone( 'America/Chicago' );

    my $stamp_dt
        = DateTime::Format::ISO8601->parse_datetime( $txn{'Timestamp'} );
    $stamp_dt->set_time_zone( 'America/Chicago' );

    my $invoice = $self->schema->resultset( 'Invoice' )
        ->find( { invoiceid => $args{'invoice'} } );

    my $attrs = {
        date          => $stamp_dt,
        installation  => $txn{'Receiver'},
        company_name  => $txn{'PayerBusiness'},
        name          => "$txn{'FirstName'} $txn{'LastName'}",
        address       => $txn{'Street1'},
        postal_code   => $txn{'PostalCode'},
        country_code  => $txn{'Country'},
        email         => $txn{'Payer'},
        auth_amount   => $txn{'GrossAmount'},
        auth_currency => $args{'auth_currency'},
        txn_time      => $txn_dt,
        type          => $txn{'PaymentType'},
        status        => $txn{'PaymentStatus'},
        fee           => $txn{'FeeAmount'},
        fee_currency  => $args{'auth_currency'},
        source        => 'paypal',
    };

    my $txn = $invoice->find_or_create_related( 'transaction',
        { txn_id => $args{'txn_id'} } );
    $txn->update( $attrs );

    return $txn;

}

=head2 paypal_return

PayPal will return the user to this page after they have confirmed their
shipping info etc.

parent.location='new url"; window.close();

=cut

sub paypal_return {

    my $self   = shift;
    my $config = $self->config;
    my $pp     = $self->get_pp;
    my %details
        = $pp->GetExpressCheckoutDetails( $self->query->param( 'token' ) );

    my $invoice = $self->schema->resultset( 'Invoice' )
        ->find( { number => $details{'InvoiceID'} } );

    return if !$invoice;

    ## now ask PayPal to xfer the money
    my %payinfo = $pp->DoExpressCheckoutPayment(
        OrderTotal    => $invoice->amount,
        PaymentAction => 'Sale',
        PayerID       => $details{PayerID},
        Token         => $details{Token},
    );

    if ( !exists $payinfo{'Errors'} ) {

        my $txn = $self->update_paypal_txn(
            auth_currency => $config->{'base_currency'},
            invoice       => $invoice->invoiceid,
            txn_id        => $payinfo{'TransactionID'},
        );

        if ( $txn->status eq 'Completed' ) {
            $invoice->status( 'Paid' );
            $invoice->update;
        }

    }

    return \%payinfo;

}

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
