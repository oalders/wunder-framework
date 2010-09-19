#!/usr/bin/perl

use Modern::Perl;
use Data::Dump qw( dump );
use DateTime;
use Test::More tests => 13;

require_ok( 'Wunder::Framework::Billing' );

my $billing = Wunder::Framework::Billing->new();
isa_ok( $billing, 'Wunder::Framework::Billing' );

my $rate = 10;

my $start_date = DateTime->now();
my $result     = $billing->prorate(
    start_date   => $start_date,
    monthly_rate => $rate,
    months       => 1,
);

##############################################################################
#
# Pretend today is the 1st
#
##############################################################################

my $day_one = $start_date->clone->truncate( to => 'month' );
my $no_prorate = $billing->prorate(
    start_date   => $day_one,
    monthly_rate => $rate,
    months       => 1,
);

ok( !$no_prorate->{'months'},     "0 months" );
ok( $no_prorate->{'amount'} == 0, "no amount" );
cmp_ok( $no_prorate->{'next_payment'}->ymd,
    'eq', $day_one->ymd, "next payment is on 1st of next month" );

##############################################################################
#
# Pretend today is the 2nd
#
##############################################################################

my $pre_rollover
    = $start_date->clone->truncate( to => 'month' )->add( days => 1 );
my $prorate = $billing->prorate(
    start_date   => $pre_rollover,
    monthly_rate => $rate,
    rollover_day => 15,
    months       => 1,
);

cmp_ok( $prorate->{'months'}, '>', 0, "month greater than 0" );
cmp_ok( $prorate->{'months'}, '<', 1, "month less than 1" );
ok( $prorate->{'amount'} > 0, "amount greater than 0" );
ok( $prorate->{'amount'} < $rate,
    "amount less than $rate ($prorate->{'amount'})" );

$pre_rollover->truncate( to => 'month' )->add( months => 1 );

cmp_ok( $prorate->{'next_payment'}->ymd,
    'eq', $pre_rollover->ymd, "next payment is on 1st of next month" );

##############################################################################
#
# Pretend today is the 20th
#
##############################################################################

my $post_rollover
    = $start_date->clone->truncate( to => 'month' )->add( days => 20 );

my $prorate_post = $billing->prorate(
    start_date   => $post_rollover,
    monthly_rate => $rate,
    rollover_day => 15,
    months       => 1,
);

cmp_ok( $prorate_post->{'months'}, '>', 1, "month greater than 1" );
ok( $prorate_post->{'amount'} > $rate,
    "amount greater than $rate ($prorate_post->{'amount'})" );

$post_rollover->truncate( to => 'month' )->add( months => 2 );

cmp_ok( $prorate_post->{'next_payment'}->ymd,
    'eq', $post_rollover->ymd, "next payment is on 1st of month after next" );

=head1 AUTHOR

    Olaf Alders
    CPAN ID: OALDERS
    WunderCounter.com
    olaf@wundersolutions.com
    http://www.wundercounter.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
