#!/usr/bin/env perl

use Modern::Perl;

=head1 SYNOPSIS

Test billing roles

=cut

use Data::Dump qw( dump );
use Test::More;
use Wunder::Framework::Test::Roles::Billing;

new_ok( 'Wunder::Framework::Test::Roles::Billing' );

my $billing = Wunder::Framework::Test::Roles::Billing->new;

my $pp = $billing->pp;
isa_ok( $pp, 'Business::PayPal::API' );

done_testing();
