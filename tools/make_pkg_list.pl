#!/usr/bin/env perl

use Modern::Perl;

use Perl6::Junction qw( any );

`dpkg -l > installed.packages`;

my @pkgs = ( );

my @ignore = ( );

open(FILE, "installed.packages");
    LINE:
    while (<FILE>) {
        next LINE unless /^ii  /;

        my $line = $_;
        chomp $line;
        $line =~ s/^ii  //;
        $line =~ s/\s.*//g;

        next LINE if ( any( @ignore ) eq $line );

        push @pkgs, $line;
    }
close(FILE);

open (INSTALL, ">apt_install.sh");
    foreach my $pkg ( @pkgs ) {
        print INSTALL "apt-get -y install $pkg\n" if $pkg;
    }
close (INSTALL);

my $pkgs = join " ", @pkgs;
open (INSTALL, ">apt_install_one_line.sh");
    print INSTALL "apt-get -y install $pkgs\n" if $pkgs;
close (INSTALL);

print scalar @pkgs . " pkgs found\n";

