#!/usr/bin/env perl

use Modern::Perl;
use Find::Lib '../lib';

use Wunder::Framework::Tools::MySQL;
my $tools = Wunder::Framework::Tools::MySQL->new();

$tools->make_grants;

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
