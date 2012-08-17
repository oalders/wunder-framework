#!/usr/bin/env perl

use Modern::Perl;

=head1 SYNOPSIS

We can't expect the paid library to be installed on every machine, so the
->geo method shouldn't fail on undef

=cut

use Data::Dump qw( dump );
use Test::More;
use Wunder::Framework::Test::Roles::Geo;

my $roles = Wunder::Framework::Test::Roles::Geo->new;

my $geo = $roles->geo;

diag( "Is paid Geo::IP library not installed?" ) if !$geo;

ok( $roles->geo_lite, "got geo lite object" );
ok( $roles->best_geo, "got the best geo object" );

isa_ok( $roles->geo_lite, 'Geo::IP' );
isa_ok( $roles->best_geo, 'Geo::IP' );
if ( -e '/usr/share/GeoIP/GeoIPOrg.dat' ) {
    isa_ok( $roles->geo_org, 'Geo::IP' );
}
else {
    diag "GeoIP Org db does not exist";
}

done_testing();
