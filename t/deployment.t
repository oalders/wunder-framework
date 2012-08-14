#!/usr/bin/env perl

use Modern::Perl;
use Data::Printer;
use Test::More;
use Wunder::Framework::Deployment;

new_ok( 'Wunder::Framework::Deployment' );
my $d = Wunder::Framework::Deployment->new;

diag $d->stream;

done_testing;
