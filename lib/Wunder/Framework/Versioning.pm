package Wunder::Framework::Versioning;

use Moose;
use Modern::Perl;

with 'MooseX::Getopt';

with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::DBI';
with 'Wunder::Framework::Roles::DateTime';

=head1 SYNOPSIS

A (hopefully) flexible db versioning system, based on the DBIx::Class
module of similar name.

=cut

use Carp qw( croak );
use Data::Dump qw( dump );
use File::Tools qw( mkpath );
use IO::File;
use Params::Validate qw( validate_pos HASHREF SCALAR );
use Try::Tiny;

=head2 fresh_install

If this is a fresh deployment, we don't want to ignore SQL patch files from
any instance.

perl versioning.pl --fresh_install

=cut

has 'fresh_install' => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 upgrade

Perform all of the basic upgrade tasks.  This module really doesn't need
a lot of methods

=cut

sub upgrade {

    my $self        = shift;
    my $schema_name = shift;

    die "db name required" unless $schema_name;

    # versioning table installed?
    $self->check_versioning( $schema_name );

    my $db = $self->config->{'db'}->{$schema_name};
    my $dt = $self->dt;
    my $backup_dir
        = $self->path . "/db/backup/pre_upgrade/$schema_name/" . $dt->ymd;

    $self->check_dir( $backup_dir );

   # see http://perldoc.perl.org/functions/require.html to explain "eval" here
    ## no critic (ProhibitStringyEval)
    eval "require $db->{'namespace'}";    ## no critic
    ## use critic

    my $schema  = $self->schema( $schema_name );
    my $changes = $self->get_change_files( $schema_name );

CHANGE:
    foreach my $file ( @{$changes} ) {

        print "checking $file...\t";

       # older files won't have the _ naming conventions for stuff dev files
       # also ignore files from the same stream, as they are already installed
        my $ignore = '_' . $self->stream . '.sql';

        if (   ( $self->stream eq 'dev' && $file !~ m{_} )
            || ( !$self->fresh_install && $file =~ m{$ignore}xms ) )
        {
            print "belongs to this stream -- skipping\n";
            next CHANGE;
        }

        my $install
            = $schema->resultset( 'Versioning' )->find( { file => $file } );

        if ( $install ) {
            print "is already installed\n";
            next CHANGE;
        }

        my $backup_file = "$backup_dir/$file" . '_' . $self->dt->hms( '-' );

        $self->back_up( $db, $backup_file, 'upgrade' );
        $self->do_sql( $self->dbh( $schema_name ), $file );
        $self->log_version( $self->dbh( $schema_name ), $file );

        say "----> successfully installed";
    }

    return 1;

}

=head2 check_dir( $dir )

To be used in setup -- create a dir if it does not exist.

=cut

sub check_dir {

    my $self = shift;
    my $dir  = shift;

    die "no dir name" unless $dir;

    unless ( -e $dir ) {
        mkpath( "$dir" );
        die $! unless -e $dir;
    }

    return;

}

=head2 check_versioning

If this site is not set up for versioning, set up the correct
MySQL table...

=cut

sub check_versioning {

    my $self        = shift;
    my $schema_name = shift;
    my $dbh         = $self->dbh( $schema_name );

    return $self->can_version( $dbh );

}

=head2 can_version( $dbh )

Returns true if a versioning table exists (either pre-existing or just
created)

=cut

sub can_version {

    my $self   = shift;
    my $dbh    = shift;
    my $tables = $dbh->selectall_arrayref( "SHOW TABLES LIKE 'versioning'" );

    if ( scalar @{$tables} > 0 ) {
        return 1;
    }
    else {
        my $create = qq[
            CREATE TABLE `versioning` (
            `versioningid` int(11) NOT NULL auto_increment,
            `file` varchar(100) NOT NULL,
            `installed` datetime NOT NULL,
            PRIMARY KEY  (`versioningid`),
            UNIQUE KEY `file` (`file`)
            )
        ];

        return $dbh->do( $create );

    }

}

=head2 log_version( $dbh, $file )

Marks a change file as "installed".

=cut

sub log_version {

    my $self = shift;
    my $dbh  = shift;
    my $file = shift;

    my $insert = qq[
        INSERT INTO versioning
        SET
        file = '$file',
        installed = now()
    ];

    return $dbh->do( $insert );

}

=head2 back_up( $db, $file, upgrade|snapshot )

Perform a backup, if necessary.  In some cases, it just won't be necessary to
perform a full backup first.  However, in the cases where it *is* beneficial,
we'll likely want to get a snapshot of a slave machine in order to avoid
tying up the master unnecessarily.

A backup on upgrade will look at the dump_on_upgrade options, which will
generally specify some tables to ignore when creating backups (like session
tables or log tables with a lot of data which you don't care all that much
about in an upgrade context).

A backup on snapshot will look at the dum_on_snapshot options, where you could
specificy similar options, if desired.  Having said that, you *probably* care
about all of your data in a snapshot in order for it to be effective.

=cut

sub back_up {

    my $self = shift;
    my @args = validate_pos(
        @_,
        { type => HASHREF },
        { type => SCALAR },
        { type => SCALAR },
    );

    my $db     = shift @args;
    my $file   = shift @args;
    my $action = shift @args;

    # not every schema requires upgrades on backup
    return 0 if ( $action eq 'upgrade' && !exists $db->{'dump_on_upgrade'} );

    # but upgrade dumps do require some configuration
    if (   $action eq 'upgrade'
        && exists $db->{'dump_on_upgrade'}
        && $db->{'dump_on_upgrade'}
        && !exists $db->{'dump'} )
    {
        croak "set up your dump params";
    }

    my $cfg = $db;

    # upgrades always run by default on the write_root schema, but we don't
    # always want to dump from the master, so in for upgrade dumps we need
    # to jump through some hoops.  For snapshots we can specify any schema,
    # so this isn't necessary in that case.

    if ( $action eq 'upgrade' && exists $db->{'dump'}->{'dump_from'} ) {

        my $from = $db->{'dump'}->{'dump_from'};

        # check to ensure it's a valid schema
        $self->dbh( $from );
        $cfg = $self->config->{'db'}->{$from};
    }

    my $dump = " mysqldump --skip-add-drop-table ";
    $dump .= qq{ -u $cfg->{'user'} -p"$cfg->{'pass'}" };
    $dump .= " -h $cfg->{'host'}  $db->{'database'} ";

    if ( $action eq 'upgrade'
        && exists $db->{'dump'}->{'options'} )
    {
        $dump .= " $db->{'dump'}->{'options'} ";
    }
    elsif ( $action eq 'snapshot'
        && exists $db->{'dump'}->{'snapshot_options'} )
    {
        $dump .= " $db->{'dump'}->{'snapshot_options'} ";
    }

    if ( exists $db->{'dump'}->{'file_suffix'} ) {
        $file .= '_' . $db->{'dump'}->{'file_suffix'};
    }
    $file .= '.sql';

    $dump .= " > $file ";

    print "backing up via: $dump\n";

    my $result = `$dump`;
    croak "mysqldump failed: $result " if $result =~ m{\w};

    return;
}

=head2 snapshot( $schema_name )

Creates a snapshot of data, mostly useful for backup purposes.  Data will
be created in:

db/backup/snapshot/schema_name/YYYY-MM-DD_HH:MM:SS.sql

=cut

sub snapshot {

    my $self        = shift;
    my @args        = validate_pos( @_, { type => SCALAR } );
    my $schema_name = shift @args;

    die "bad schema name" if !exists $self->config->{'db'}->{$schema_name};

    my $dt         = $self->dt;
    my $backup_dir = $self->path . "/db/backup/snapshot/$schema_name";

    $self->check_dir( $backup_dir );

    my $file = $backup_dir . '/' . $dt->ymd . '_' . $dt->hms;

    return $self->back_up( $self->config->{'db'}->{$schema_name},
        $file, 'snapshot' );

}

=head2 do_sql( $dbh, $file )

Run the SQL queries

=cut

sub do_sql {

    my $self = shift;
    my $dbh  = shift;
    my $file = shift;

    local $dbh->{AutoCommit} = 0;
    local $dbh->{RaiseError} = 1;

    my $fh = IO::File->new( $file, "r" );
    if ( defined $fh ) {

        try {
            my $sql = undef;
            while ( $_ = $fh->getline ) {
                $sql .= $_;
            }
            undef $fh;

            my @queries = split /;/, $sql;

            foreach my $query ( @queries ) {

                next if $query !~ m{\w};

                my $result = $dbh->do( $query );
                print "ERROR in $file -- $result : \n$query\n" if !$result;

            }
            $dbh->commit;
        }
        catch {
            $dbh->rollback;
            die "Problem with $file. Transaction aborted because $_";
        };
    }

    return;

}

=head2 upgrade_all

Use this method if the generic versioning upgrades are good enough for you.
Will upgrade any db schema containing the string '_write_root'

=cut

sub upgrade_all {

    my $self = shift;

    foreach my $name ( sort keys %{ $self->config->{'db'} } ) {
        next if $name !~ /write_root\z/;

        print "Starting $name...\n";
        $self->upgrade( $name );
    }

    return;

}

=head2 get_change_files

Returns an ARRAYREF of file names with SQL change patches.

=cut

sub get_change_files {

    my $self        = shift;
    my $schema_name = shift;

    my $change_dir = $self->path . "/db/changes/$schema_name";
    $self->check_dir( $change_dir );

    chdir $change_dir || croak "cannot chdir $!";

    my @changes = glob( "*.sql" );
    return \@changes;

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
