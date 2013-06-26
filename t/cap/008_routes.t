#!/usr/bin/perl

use Modern::Perl;
use Test::More skip_all => "missing new method -- maybe test it via Super?";

require_ok( 'Wunder::Framework::Routes' );

my $routes = Wunder::Framework::Routes->new();
isa_ok( $routes, 'Wunder::Framework::Routes' );

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
