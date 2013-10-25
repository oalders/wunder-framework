package Wunder::Framework::Roles::DBI;

use strict;
use warnings;

use Moose::Role;

use Carp qw( confess );
use Devel::SimpleTrace;
use DBI;
use DDP;
use File::Slurp qw( read_file );
use Hash::Merge;

has _db_config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_db_config',
);

has _fixture_dbs => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub { {} },
);

has _fixtures_enabled => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_fixtures_enabled',
);

sub _build_db_config {
    my $self = shift;
    return $self->config->{db} unless $self->_fixtures_enabled;

    my $config     = $self->config->{fixtures};
    my $merge      = Hash::Merge->new( 'RIGHT_PRECEDENT' );
    my $connection = delete $config->{connection};
    my @suffix     = ( 'master', 'read', 'write', 'write_root' );

    foreach my $schema_handle ( keys %{$connection} ) {

        my $db_template = $connection->{$schema_handle};
        $db_template->{database} = $db_template->{database} . '_' . $$;

        my %suffix = map { $_ => delete $db_template->{$_} } @suffix;

        foreach my $suffix ( @suffix ) {
            my $full_name = $schema_handle . '_' . $suffix;
            my $override = $suffix{$suffix} || {};

            $config->{$full_name} = $merge->merge( $db_template, $override );
            $config->{$full_name}->{dsn} .= sprintf(
                'dbi:%s:database=%s;host=%s',
                $config->{$full_name}->{db_type},
                $config->{$full_name}->{database},
                $config->{$full_name}->{host}
            );
        }
    }

    return $config;
}

sub _build_fixtures_enabled {
    my $self = shift;
    return ( $ENV{HARNESS_ACTIVE} && $self->config->{fixtures} ) ? 1 : 0;
}

sub dbh {

    my $self       = shift;
    my $connection = $self->_validate_connection( @_ );

    my $db = $self->_db_config->{$connection};
    if ( $db->{namespace} ) {
        return $self->schema( $connection )->storage->dbh;
    }

    # 99% of code will never reach this point
    $self->{'__wf_db'} = {} if !$self->{'__wf_db'};
    my $cache = $self->{'__wf_db'};

    if ( exists $cache->{$connection}
        && !eval { $cache->{$connection}->do( 'SELECT 1' ) } )
    {
        delete $cache->{$connection};
    }

    if ( !exists $cache->{$connection} ) {
        $cache->{$connection}
            = DBI->connect( $db->{dsn}, $db->{user}, $db->{pass},
            $db->{attrs} )
            or die "Can't connect $DBI::errstr";
        $self->{'__wf_db'} = $cache;
    }

    return $cache->{$connection};

}

{
    my $cache;

    sub schema {

        my $self          = shift;
        my $schema_handle = $self->_validate_connection( @_ );

        if ( !exists $cache->{$schema_handle} ) {

            if ( $self->_fixtures_enabled ) {
                $self->_set_up_fixture_db( $schema_handle );
            }
            my $db = $self->_db_config->{$schema_handle};

            confess 'namespace required' if !$db->{namespace};

            # remove need to "use" namespace first (especially in tests)
            ## no critic (ProhibitStringyEval)
            eval "require $db->{namespace}";
            ## use critic

            $cache->{$schema_handle}
                = $db->{'namespace'}
                ->connect( $db->{dsn}, $db->{user}, $db->{pass},
                $db->{attrs} );

            confess "could not connect" if !$cache->{$schema_handle};

        }

        return $cache->{$schema_handle};
    }
}

sub db_name {

    my $self          = shift;
    my $schema_handle = $self->_validate_connection( shift );
    return $self->_db_config->{$schema_handle}->{database};

}

sub _validate_connection {
    my $self = shift;
    my $schema_handle = shift || $self->config->{'schema'}->{'default'};

    if ( !$schema_handle ) {
        confess "no schema name supplied and no default set";
    }
    elsif ( !exists $self->_db_config->{$schema_handle} ) {
        confess "bad schema name supplied: $schema_handle";
    }

    return $schema_handle;
}

sub _set_up_fixture_db {
    my $self          = shift;
    my $schema_handle = shift;

    my $base_name = $schema_handle;
    $base_name =~ s{(read|write|write_root)\z}{};

    my $db_config = $self->_db_config->{$schema_handle};

    confess 'Fixture config missing' if !$db_config;
    if ( $db_config->{database} !~ m{\A(test_|memory)} ) {
        p $db_config;
        confess 'Are you sure this is a fixture db?';
    }

    return if $self->_fixture_dbs->{ $db_config->{database} };

    # this is actually necessary, despite the line above
    my $select = qq[SHOW DATABASES LIKE '$db_config->{database}'];

    my $exists
        = $self->dbh( $base_name . 'master' )->selectrow_arrayref( $select );

    return if $exists->[0];

    my $master = $base_name . 'master';
    $self->dbh( $master )->do( 'CREATE DATABASE ' . $db_config->{database} );
    $self->_fixture_dbs->{ $db_config->{database} } = $master;

    # this is what i really wanted to do
    #$self->schema( $base_name . 'write_root' )->deploy;
    #return;

    my $ddl_path
        = substr( $db_config->{ddl_path}, 0, 1 ) eq '/'
        ? $db_config->{ddl_path}
        : $self->path . '/' . $db_config->{ddl_path};

    my $ddl = read_file( $ddl_path );
    my @statements = split m{;\n}, $ddl;

    foreach my $statement ( @statements ) {
        $self->dbh( $base_name . 'write_root' )->do( $statement );
    }
    return;
}

sub DEMOLISH {
    my $self = shift;

    return unless $self->_fixtures_enabled;
    my $dbs = $self->_fixture_dbs;

    foreach my $db ( keys %{$dbs} ) {

        if ( $db !~ m{\Atest_} ) {
            confess 'not dropping live db: ' . $db;
        }
        $self->dbh( $dbs->{$db} )->do( 'DROP DATABASE ' . $db );
    }
}

1;

=head1 SYNOPSIS

Roles required for database interaction

=head2 db_name( $schema_name )

Return the name of the database used for a configured connection.  Returns
db_name for default schema if no schema name is supplied

=head2 dbh

dbh lazy loading.  pings the server.  if connection has dropped, it will
establish a new connection.  keeping this in mind, it's better to do

$self->dbh->do("select ...")

than

my $dbh = $self->dbh;

and later:

$dbh->do("select ...")

The first bit of code will test the connection first, whereas the second bit
assumes that the connection is still there, which is not always a valid
assumption.

=head2 schema

DBIx::Class lazy loading

=head2 DEMOLISH

Drop any fixture databases at object teardown.

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

