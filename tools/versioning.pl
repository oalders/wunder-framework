#!/usr/bin/env perl

use Modern::Perl;

=head1 SYNOPSIS

Use this script to apply database change patches to your instance.  The change
files are found in db/changes/schema_name

=cut

use Find::Lib '../lib';

use Wunder::Framework::Versioning;

my $versioning = Wunder::Framework::Versioning->new_with_options;
my @schemas    = sort keys %{ $versioning->config->{'db'} };

my @upgrade = ();
foreach my $name ( @schemas ) {
    push @upgrade, $name if $name =~ /write_root\z/;
}

foreach my $schema_name ( @upgrade ) {
    print "Starting $schema_name...\n";
    $versioning->upgrade( $schema_name );
}

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
