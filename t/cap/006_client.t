#!/usr/bin/perl

use Modern::Perl;
use Test::More skip_all => "have to find a way to deal with schema in examples";

require_ok('Wunder::Framework::Client');

my $client = Wunder::Framework::Client->new();
isa_ok ($client, 'Wunder::Framework::Client' );

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
