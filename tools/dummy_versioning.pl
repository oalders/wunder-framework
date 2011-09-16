#!/usr/bin/env perl

=head1 SYNOPSIS

Sometimes you need to mark all db patches as applied -- like in the case
where you've copied over a database to a new instance name.

=cut

use Modern::Perl;
use Try::Tiny;

use Wunder::Framework::Versioning;

my $versioning  = Wunder::Framework::Versioning->new_with_options;
my $schema_name = shift @ARGV;

die "usage: dummy_versioning.pl $schema_name" if !$schema_name;

my $files = $versioning->get_change_files( $schema_name );

foreach my $file ( @{$files} ) {
    try { $versioning->log_version( $versioning->dbh( $schema_name), $file ); };
}

1;
