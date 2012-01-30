#!/usr/bin/perl

use Modern::Perl;
use Data::Printer;
use Test::More qw( no_plan );
use Try::Tiny;

require_ok('Wunder::Framework::Test::Roles::DBI');

my $base = Wunder::Framework::Test::Roles::DBI->new();

my @connections = reverse keys %{$base->config->{'db'}};

foreach my $conn ( @connections ) {
    next if $conn eq 'slave';

    diag 'checking ' . $conn;

    my $db  = $base->config->{'db'}->{$conn};
    diag p $db if $ENV{DEBUG};
    my $dbh;

    try { $dbh = $base->dbh( $conn ) };

    isa_ok ($dbh, 'DBI::db', "$conn");

    SKIP: {

        skip 'not every connection needs a namespace ' . p $db, 2  unless ( exists $db->{'namespace'} );

        require_ok( $db->{'namespace'} );
        my $schema = $base->schema( $conn );
        isa_ok( $schema, 'DBIx::Class');
    }

}
