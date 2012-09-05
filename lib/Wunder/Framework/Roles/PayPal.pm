package Wunder::Framework::Roles::PayPal;

use Moose::Role;
use Business::PayPal::API;

has 'pp' => ( is => 'rw', lazy_build => 1 );

=head2 get_pp

Returns an Business::PayPal::API::ExpressCheckout object

=cut

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

1;
