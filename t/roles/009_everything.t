#!/usr/bin/perl

use Modern::Perl;

=head1 SYNOPSIS

Basically a load test

=cut

use Data::Dump qw( dump );
use Test::More tests => 2;
use Wunder::Framework::Test::Roles::Everything;

require_ok( 'Wunder::Framework::Test::Roles::Everything' );
my $everything = Wunder::Framework::Test::Roles::Everything->new;
ok( $everything, "got an object" );

