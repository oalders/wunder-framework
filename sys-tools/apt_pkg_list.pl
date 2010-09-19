#!/usr/bin/perl

use Modern::Perl;
use Find::Lib;

chdir( Find::Lib::base() . "/output" ) || die "cannot chdir";

`dpkg -l > installed.packages`;

my @pkgs = undef;

open(FILE, "installed.packages");
    LINE:
    while (<FILE>) {
        next LINE unless /^ii  /;

        my $line = $_;
        chomp $line;
        $line =~ s/^ii  //;
        $line =~ s/\s.*//g;
        push @pkgs, $line;
    }
close(FILE);

open (INSTALL, ">apt_install.sh");
    foreach my $pkg ( @pkgs ) {
        print INSTALL "apt-get install $pkg\n" if $pkg;
    }
close (INSTALL);


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
