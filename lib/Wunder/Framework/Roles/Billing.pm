package Wunder::Framework::Roles::Billing;

use Moose::Role;
use Modern::Perl;

use Business::PayPal::API qw( ExpressCheckout GetTransactionDetails );
use DateTime;
use DateTime::Format::ISO8601;
use Params::Validate qw( validate SCALAR );
use Wunder::Framework::Tools::Toolkit qw( zeropad );

has pp => (
    is         => 'ro',
    lazy_build => 1,
);


sub _build_pp {

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


sub update_paypal_txn {

    my $self = shift;

    my %rules = (
        auth_currency => { type => SCALAR },
        invoice       => { type => SCALAR },
        txn_id        => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );
    my $config = $self->config;
    my $tz = $config->{time_zone};

    my $api = $config->{'payment_source'}->{'paypal'}->{'api'};

    my $pp = $self->get_pp;
    my %txn = $pp->GetTransactionDetails( TransactionID => $args{'txn_id'} );

    my $txn_dt
        = DateTime::Format::ISO8601->parse_datetime( $txn{'PaymentDate'} );
    $txn_dt->set_time_zone( $tz ) if $tz;

    my $stamp_dt
        = DateTime::Format::ISO8601->parse_datetime( $txn{'Timestamp'} );
    $stamp_dt->set_time_zone( $tz ) if $tz;

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

=head1 SYNOPSIS

The various roles required for billing (in general) and via PayPal

=head2 get_pp

Returns an Business::PayPal::API::ExpressCheckout object

=head2 new_invoice( $client )

Provides a brand new invoice to the caller, with a new invoice number.

=head2 paypal_return

PayPal will return the user to this page after they have confirmed their
shipping info etc.

parent.location='new url"; window.close();

=head2 update_paypal_txn

Given a PayPal txn, update it in the transaction table. "invoice" param
requires invoiceid.

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
