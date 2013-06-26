#!/usr/bin/perl

use Modern::Perl;

use Data::Dump qw( dump );
use Test::More tests => 4;
use Wunder::Framework::Test::Roles::Deployment;

my $test = Wunder::Framework::Test::Roles::Deployment->new;

ok( $test->stream, "got stream: " . $test->stream );
ok( $test->path,   "got path: " . $test->path );
ok( $test->site,   "got site: " . $test->site );
ok( $test->config, "got config" );

if ( scalar keys %{ $test->config } == 0 ) {
    diag( "The config appears to be empty" );
}
