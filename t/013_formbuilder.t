#!/usr/bin/perl

use Modern::Perl;
use Test::More tests => 4;

require_ok('Wunder::Framework::Tools::FormBuilder');

my $fb = Wunder::Framework::Tools::FormBuilder->new();
isa_ok ( $fb, "Wunder::Framework::Tools::FormBuilder" );

ok( $fb->wf->best_geo, "can get a geo object" );
isa_ok( $fb->wf->best_geo, "Geo::IP");

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
