#!/usr/bin/perl

use Modern::Perl;
use Data::Dump qw( dump );
use Test::More qw( no_plan );

require_ok('Wunder::Framework::Test::Roles::DBI');

my $base = Wunder::Framework::Test::Roles::DBI->new();

my @connections = reverse keys %{$base->config->{'db'}};
#@connections = 'wundercounterlog_read';

foreach my $conn ( @connections ) {
    next if $conn eq 'slave';

    my $db  = $base->config->{'db'}->{$conn};
    my $dbh = $base->dbh( $conn );

    isa_ok ($dbh, 'DBI::db', "$conn");

    SKIP: {

        skip 'not every connection needs a namespace', 2  unless ( exists $db->{'namespace'} );

        require_ok( $db->{'namespace'} );
        my $schema = $base->schema( $conn );
        isa_ok( $schema, 'DBIx::Class');
    }

}
