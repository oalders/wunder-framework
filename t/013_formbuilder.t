#!/usr/bin/env perl

use Modern::Perl;
use Test::More;

use Wunder::Framework::Tools::FormBuilder;
use Wunder::Framework::CAP::Super;

new_ok( 'Wunder::Framework::Tools::FormBuilder' );

my $fb = Wunder::Framework::Tools::FormBuilder->new();
isa_ok( $fb, "Wunder::Framework::Tools::FormBuilder" );

ok( $fb->wf->best_geo, "can get a geo object" );
isa_ok( $fb->wf->best_geo, "Geo::IP" );

ok( !$fb->encode_this,     "encode_this should default to false" );
ok( $fb->encode_this( 1 ), "encode_this now on" );

my $cap = Wunder::Framework::CAP::Super->new;
ok( $cap->fb->encode_this, "encoding on in super" );

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
