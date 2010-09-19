#!/usr/bin/perl

use Modern::Perl;
use Data::Dump qw( dump );
use Find::Lib '../lib';

=head1 SYNOPSIS

The difference between this script and using a single shell command would be
that this gives you the flexibility of changing the database login info
without having to update the same info in your backup crons

Usage: perl dump_db.pl schema_name

=cut

use Wunder::Framework::Versioning;

my $super  = Wunder::Framework::Versioning->new();
my $config = $super->config->{'db'};

my $schema_name = shift @ARGV;

if ( !$schema_name ) {
    print "Usage: perl dump_db.pl schema_name\n";
    print "Your schema names are: \n";

    schema_names();
    die;
}

if ( !exists $config->{ $schema_name } ) {
    print "Invalid schema name.\n";

    schema_names();
    die;
}

$super->snapshot( $schema_name );



sub schema_names {

    foreach my $name ( keys %{ $config } ) {
        print "$name\n";
    }

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
