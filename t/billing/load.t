#!/usr/bin/perl

use Modern::Perl;
use Data::Dump qw( dump );
use Data::Printer;
use DateTime;
use Math::Round qw( nearest );
use Test::More;
use Wunder::Framework::Tools::Toolkit qw( moneypad );

require_ok( 'Wunder::Framework::Billing' );

my $rate       = 10;
my $start_date = DateTime->now();

my $billing = Wunder::Framework::Billing->new(
    monthly_rate => $rate,
    months       => 1,
    rollover_day => 15,
    start_date   => $start_date,
);
isa_ok( $billing, 'Wunder::Framework::Billing' );

##############################################################################
#
# Pretend today is the January 1st
#
##############################################################################

my $day_one = $start_date->clone->truncate( to => 'year' );
my $no_prorate = Wunder::Framework::Billing->new(
    monthly_rate => $rate,
    months       => 1,
    rollover_day => 15,
    start_date   => $day_one,
)->prorate;

ok( !$no_prorate, "should return undef" );

##############################################################################
#
# Pretend today is January 2nd
#
##############################################################################

my $rollover_day = 15;
foreach my $days ( 1 .. 14 ) {

    my $pre_rollover
        = $day_one->clone->truncate( to => 'year' )->add( days => $days );

    my $prorate = Wunder::Framework::Billing->new(
        monthly_rate => $rate,
        months       => 1,
        rollover_day => $rollover_day,
        start_date   => $pre_rollover,
    )->prorate;

    diag( "start_date is : " . $prorate->start_date->ymd );

    cmp_ok( $prorate->months, '>', 0, "month greater than 0" );
    cmp_ok( $prorate->months, '<', 1, "month less than 1" );
    ok( $prorate->amount > 0, "amount greater than 0" );
    ok( $prorate->amount < $rate,
        "amount less than $rate " . $prorate->amount );

    my $partial = ( 31 - ( $pre_rollover->day - 1 ) ) / 31;
    diag( "partial: $partial" );

    my $rate = moneypad( $prorate->monthly_rate * $partial );
    cmp_ok( $prorate->amount, '==', $rate,
        "amount is exactly correct: " . $prorate->amount );

    $pre_rollover->truncate( to => 'month' )->add( months => 1 );

    cmp_ok( $prorate->next_payment->ymd,
        'eq', $pre_rollover->ymd, "next payment is on 1st of next month" );

}

##############################################################################
#
# Pretend today is the 20th
#
##############################################################################

foreach my $days ( 15 .. 30 ) {

    my $post_rollover
        = $start_date->clone->truncate( to => 'year' )->add( days => $days );

    my $prorate = Wunder::Framework::Billing->new(
        start_date   => $post_rollover,
        monthly_rate => $rate,
        rollover_day => 15,
        months       => 1,
    )->prorate;

    diag( "start_date is : " . $prorate->start_date->ymd );

    cmp_ok( $prorate->months, '>', 1, "month greater than 1" );
    ok( $prorate->amount > $rate,
        "amount greater than $rate " . $prorate->amount );

    my $partial = ( 31 - ( $post_rollover->day - 1 ) ) / 31;
    ++$partial;
    diag( "partial: $partial" );

    my $rate = moneypad( $prorate->monthly_rate * $partial );
    cmp_ok( $prorate->amount, '==', $rate,
        "amount is exactly correct: " . $prorate->amount );

    $post_rollover->truncate( to => 'month' )->add( months => 2 );

    cmp_ok( $prorate->next_payment->ymd,
        'eq', $post_rollover->ymd,
        "next payment is on 1st of month after next" );

}

done_testing();

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
