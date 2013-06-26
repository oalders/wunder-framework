#!/usr/bin/perl

use Modern::Perl;

use Data::Dumper;
use Scalar::Util qw( reftype );
use Test::More tests => 8;

require_ok( 'Wunder::Framework::Tools::FormBuilder' );

my $builder = Wunder::Framework::Tools::FormBuilder->new();
isa_ok( $builder, 'Wunder::Framework::Tools::FormBuilder' );

my $date_menu = $builder->get_date_menu( name => "date" );
ok( $date_menu, "returned date menu" );

#print $date_menu;

my $menu = $builder->get_timestamp_menu( name => "time" );
ok( $menu, "returned timestamp menu" );

ok( $builder->expiration_month, "got an expiration month menu" );

#diag ( $builder->expiration_month );

ok( $builder->expiration_year, "got an expiration year menu" );

#diag ( $builder->expiration_year );

ok( $builder->region_menu( 'CA' ), "creates region menu" );

#diag( $builder->region_menu('CA') );

$builder->ip( '64.37.82.100' );
my $country = $builder->get_user_country();
ok( $country, "gets user country: " . $country );

#print $menu;

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
