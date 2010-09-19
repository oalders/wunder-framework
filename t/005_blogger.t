#!/usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use Test::More tests => 2;

require_ok('Wunder::Framework::Blogger');

my $blogger = Wunder::Framework::Blogger->new();
isa_ok ($blogger, 'Wunder::Framework::Blogger' );


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
