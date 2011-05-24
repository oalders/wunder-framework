#!/usr/bin/perl

use Modern::Perl;
use Test::More;
use Wunder::Framework::Tools::Toolkit;

use Wunder::Framework::Tools::Toolkit
    qw( capitalize commify dt_pad get_dt suggest_password suggest_passwd zeropad moneypad round );

my $number = zeropad( number => 22 );
cmp_ok( $number, 'eq', '22', "zeropad returned $number for 22" );

$number = zeropad( number => 22, limit => 4 );
cmp_ok( $number, 'eq', '0022', "zeropad returned $number for 22" );

$number = zeropad( number => 22, limit => 3 );
cmp_ok( $number, 'eq', '022', "zeropad returned $number for 22" );

$number = zeropad( number => 22, limit => 2 );
cmp_ok( $number, 'eq', '22', "zeropad returned $number for 22" );

$number = zeropad( number => 22, limit => 1 );
cmp_ok( $number, 'eq', '22', "zeropad returned $number for 22" );

my $dt = get_dt();
isa_ok( $dt, 'DateTime', "get_dt returns a DateTime object" );

my $capitalize = capitalize( "this guy here" );
cmp_ok( $capitalize, 'eq', 'This Guy Here', "got $capitalize" );

my $commad = commify( 10000 );
cmp_ok( $commad, 'eq', '10,000', "got $commad" );

my $password = suggest_password;
ok( $password, "got random password from suggest_password: " . $password );

$password = suggest_passwd;
ok( $password, "got random password from sugggest_passwd: " . $password );

my $dt_pad = dt_pad( 7 );
cmp_ok( $dt_pad, 'eq', '07', "dt_pad returns $dt_pad" );

my $round = round( 3.33333333, 4 );
cmp_ok( $round, '==', 3.3333, "round returns 3.3333" );

$round = round( 3.3333333 );
cmp_ok( $round, '==', 3.33, "round returns 3.33" );

cmp_ok( moneypad( 0.5 ),   'eq', '0.50', moneypad( 0.5 ) );
cmp_ok( moneypad( 0.50 ),  'eq', '0.50', moneypad( 0.50 ) );
cmp_ok( moneypad( 0.500 ), 'eq', '0.50', moneypad( 0.500 ) );

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
