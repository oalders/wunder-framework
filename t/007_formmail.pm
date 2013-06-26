#!/usr/bin/perl

use Modern::Perl;
use Test::More tests => 2;

require_ok( 'Wunder::Framework::FormMail' );

my $formmail = Wunder::Framework::FormMail->new();
isa_ok( $formmail, 'Wunder::Framework::FormMail' );

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
