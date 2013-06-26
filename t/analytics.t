#!/usr/bin/env perl

use Test::More;
use Wunder::Framework::Analytics qw( ip2host );

is( ip2host( '208.67.222.222' ), 'resolver1.opendns.com' );
is( ip2host( '208.67.220.220' ), 'resolver2.opendns.com' );

done_testing();
