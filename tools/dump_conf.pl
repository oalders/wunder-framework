#!/usr/bin/env perl

use Modern::Perl;
use Data::Printer;
use Find::Lib '../lib';
use Wunder::Framework::Bundle;

=head1 DESCRIPTION

Print out full config for this stream.

=cut

my $wf = Wunder::Framework::Bundle->new;
print p $wf->config;    # STDOUT

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
