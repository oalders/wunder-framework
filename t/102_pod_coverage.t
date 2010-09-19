#!/usr/bin/perl

use Modern::Perl;
use Check::ISA;
use Find::Lib;
use Test::More qw( no_plan );

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@;

chdir( Find::Lib::base . "/.." );
my @modules = all_modules();

chdir( "lib" );

foreach my $module ( @modules ) {
    if ( $module =~ m{::Schema::}xms ) {
        require_ok( $module );
        my $table = $module->new;
        if ( obj( $table, "DBIx::Class" ) ) {
        SKIP: {
                skip "auto generated files don't need POD", 1;
                next;
            }
            next;
        }
    }
    pod_coverage_ok( $module );
}

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
