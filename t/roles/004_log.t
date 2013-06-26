#!/usr/bin/perl

use Modern::Perl;

use Data::Dump qw( dump );
use Test::More tests => 3;

require_ok( 'Wunder::Framework::Test::Roles::Log' );

my $log = Wunder::Framework::Test::Roles::Log->new;
isa_ok( $log->logger_object, "Log::Log4perl::Logger" );

ok( $log->logger( "log something" ), "can log to file" );
