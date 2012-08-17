#!/usr/bin/env perl

use Modern::Perl;
use DateTime;
use Test::More;
use Wunder::Framework::Billing::Prorate;

my $prorate = Wunder::Framework::Billing::Prorate->new(
    amount => 150,
    months => 1.5,
    monthly_rate => 100,
    next_payment => DateTime->now->add( months => 1 ),
    start_date => DateTime->now,
    rollover_day => 15,
);

ok( $prorate, "got a prorating object" );

done_testing();
