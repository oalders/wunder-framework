#!/usr/bin/perl

use Modern::Perl;
use Find::Lib '../lib';

=head1 SYNOPSIS

Try to find all of the dependencies for a code distribution.  This script
should be run on a system where all of the required modules are already
installed.  It will then provide a shell script which can be run at the
command line to install all of these modules on a different machine.

Usage: perl install_deps.pl > install_required.sh

=cut

use Wunder::Framework::Tools::Build::CPAN;

my $cpan = Wunder::Framework::Tools::Build::CPAN->new;
say join "\n", $cpan->find_deps;

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
