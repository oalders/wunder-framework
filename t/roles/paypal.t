#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Wunder::Framework::Test::Roles::PayPal;
my $t = Wunder::Framework::Test::Roles::PayPal->new;

SKIP: {
    skip 'PayPal config missing', 2,
        unless exists $t->config->{payment_source}->{paypal}->{api};

    ok( $t, "got paypal object" );
    isa_ok( $t->pp, "Business::PayPal::API" );

}

done_testing();
