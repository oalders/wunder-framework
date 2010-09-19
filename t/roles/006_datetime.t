#!/usr/bin/perl

use Modern::Perl;

use Data::Dump qw( dump );
use Test::More tests => 5;

require_ok( 'Wunder::Framework::Test::Roles::DateTime' );

my $test = Wunder::Framework::Test::Roles::DateTime->new;
isa_ok( $test->dt, "DateTime" );
isa_ok( $test->dt( epoch => time() ), "DateTime" );
my $tz = $test->dt->time_zone->name;

cmp_ok( $tz, 'eq', $test->time_zone, "got $tz for time zone");

my $toronto = 'America/Toronto';
$test->time_zone( $toronto );

$tz = $test->dt->time_zone->name;

cmp_ok( $tz, 'eq', $toronto, "got $toronto for time zone");
