#!/usr/bin/perl

use Modern::Perl;

=head1 SYNOPSIS

We can't expect the paid library to be installed on every machine, so the
->geo method shouldn't fail on undef

=cut

use Data::Dump qw( dump );
use Test::More tests => 4;
use Wunder::Framework::Test::Roles::Geo;

my $test = Wunder::Framework::Test::Roles::Geo->new;

my $geo = $test->geo;

diag( "Is paid Geo::IP library not installed?" ) if !$geo;

#ok( $test->geo, "got geo object" );
ok( $test->geo_lite, "got geo lite object" );
ok( $test->best_geo, "got the best geo object" );

#isa_ok( $test->geo, 'Geo::IP' );
isa_ok( $test->geo_lite, 'Geo::IP' );
isa_ok( $test->best_geo, 'Geo::IP' );