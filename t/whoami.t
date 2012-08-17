#!/usr/bin/env perl

use Test::More;
use Modern::Perl;
use Wunder::Framework::Bundle;

new_ok( 'Wunder::Framework::Bundle' );

my $wf = Wunder::Framework::Bundle->new;

foreach my $method ( 'stream', 'path' ) {
    diag( "$method: " . $wf->$method );
}


done_testing();
