package Wunder::Framework::Roles::DBI;

use Moose::Role;

#requires 'config';

use Carp qw( croak );
use Config::General;
use DBI;
use Find::Lib;
use Hash::Merge;
use Modern::Perl;

=head1 SYNOPSIS

Roles required for database interaction

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

sub dbh {

    my $self       = shift;
    my $connection = $self->_validate_connection( @_ );

    my $db = $self->config->{'db'}->{$connection};

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

sub schema {

    my $self       = shift;
    my $connection = $self->_validate_connection( @_ );

    $self->{'__wf_schema'} = {} if !$self->{'__wf_schema'};
    my $cache = $self->{'__wf_schema'};

    if ( !exists $cache->{$connection} ) {

        my $db = $self->config->{'db'}->{$connection};

        $cache->{$connection} = $db->{'namespace'}
            ->connect( $db->{dsn}, $db->{user}, $db->{pass}, $db->{attrs} );

        croak "could not connect" if !$cache->{$connection};

    }

    return $cache->{$connection};

}

sub _validate_connection {

    my $self = shift;
    my $name = shift || $self->config->{'schema'}->{'default'};

    if ( !$name ) {
        croak "no schema name supplied and no default set";
    }
    elsif ( !exists $self->config->{'db'}->{$name} ) {
        croak "bad schema name supplied: $name";
    }

    return $name;

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

1;
