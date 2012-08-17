#!/usr/bin/env perl

use Modern::Perl;
use Data::Printer;
use Test::More;
use Wunder::Framework::DBI;

new_ok( 'Wunder::Framework::DBI' );
my $d = Wunder::Framework::DBI->new;

diag $d->stream;

done_testing;
