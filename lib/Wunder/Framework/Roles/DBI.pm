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

        my $self = shift;
        my $name = $self->_validate_connection( @_ );

        if ( !exists $cache->{$name} ) {

            if ( $self->_fixtures_enabled ) {
                $self->_set_up_fixtures( $name );
            }
            my $db = $self->_db_config->{$name};

            confess 'namespace required' if !$db->{namespace};

            # remove need to "use" namespace first (especially in tests)
            ## no critic (ProhibitStringyEval)
            eval "require $db->{namespace}";
            ## use critic

            $cache->{$name}
                = $db->{'namespace'}
                ->connect( $db->{dsn}, $db->{user}, $db->{pass},
                $db->{attrs} );

            confess "could not connect" if !$cache->{$name};

        }

        return $cache->{$name};
    }
}

sub db_name {

    my $self = shift;
    my $name = $self->_validate_connection( shift );
    return $self->_db_config->{$name}->{database};

}

sub _validate_connection {
    my $self = shift;
    my $name = shift || $self->config->{'schema'}->{'default'};

    if ( !$name ) {
        confess "no schema name supplied and no default set";
    }
    elsif ( !exists $self->_db_config->{$name} ) {
        confess "bad schema name supplied: $name";
    }

    return $name;
}

sub _set_up_fixtures {
    my $self = shift;
    my $name = shift;

    my $base_name = $name;
    $base_name =~ s{(read|write|write_root)\z}{};

    my $db_config = $self->_db_config->{$name};

    confess 'Fixture config missing' if !$db_config;
    confess 'Are you sure this is a fixture db?'
        if $db_config->{database} !~ m{\A(test_|memory)};

    my $select
        = qq[select count(*) from mysql.db where Db = '$db_config->{database}'];

    my ( $exists )
        = $self->dbh( $base_name . 'master' )->selectrow_array( $select );

    return if $exists;

    my $master = $base_name . 'master';
    $self->dbh( $master )->do( 'CREATE DATABASE ' . $db_config->{database} );
    $self->_fixture_dbs->{ $db_config->{database} } = $master;


    # this is what i really wanted to do
    #$self->schema( $base_name . 'write_root' )->deploy;
    #return;

    my @ddl = read_file( $self->path . '/' . $db_config->{ddl_path} );
    my @sql;

    # whatever. it's brittle, but it works for now.
    foreach my $line ( @ddl ) {
        next if $line =~ m{\A/};
        push @sql, $line;
    }
    my $ddl = join q{}, @sql;
    my @statements = split m{;}, $ddl;

    foreach my $statement ( @statements ) {
        $self->dbh( $base_name . 'write_root' )->do( $statement );
    }
    return;
}

before 'DESTROY' => sub {
    my $self = shift;

    return unless $self->_fixtures_enabled;
    my $dbs = $self->_fixture_dbs;

    foreach my $db ( keys %{$dbs} ) {

        if ( $db !~ m{\Atest_} ) {
            confess 'not dropping live db: ' . $db;
        }
        $self->dbh( $dbs->{$db} )->do( 'DROP DATABASE ' . $db );
    }
};

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

=cut

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

