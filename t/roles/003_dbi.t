use Test::Most;
use Wunder::Framework::Test::Roles::DBI;

my $test = Wunder::Framework::Test::Roles::DBI->new;

ok( $test->config, "got config" );

foreach my $name ( keys %{ $test->config->{'db'} } ) {
    next if $name eq 'slave';

    my $db = $test->config->{'db'}->{$name};

SKIP: {
        skip 'not every connection needs a namespace', 2
            if ( !exists $db->{'namespace'} );

        next if $db->{disabled};

        use_ok( $db->{'namespace'} );
        require_ok( $db->{'namespace'} );
        my $schema = $test->schema( $name );
        isa_ok( $schema, 'DBIx::Class' );
        isa_ok( $test->dbh( $name ), 'DBI::db', "got dbh for $name" );
    }

}

done_testing();
