package Wunder::Framework::Roles::MySQL;

use Moose::Role;
use Wunder::Framework::Tools::Toolkit qw( forcearray );

=head1 SYNOPSIS

Simple of way setting up basic user perms.  READ user has LOCK TABLES
perms so that it can back up replicated dbs with mysqldump.  Generally
you'll run this script after setting up a site (and a config file) but
before you try accessing the database.

=head2 make_grants

This was adapted from a script, so rather than returning a data structure,
this method simply prints out a set of SQL grants which can be copy/pasted
and used as a quick way to set up grants for read, write, root and replication
users.

=cut

my %sql = (
    read => " SELECT, CREATE TEMPORARY TABLES, EXECUTE, LOCK TABLES ",
    root =>
        " SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ",
    write =>
        " SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, LOCK TABLES ",
    replication => " SUPER, REPLICATION CLIENT ",
);

sub make_grants {

    my $self = shift;
    print "\n\n";
    my $config = $self->config->{'db'};

    foreach my $type ( keys %sql ) {

        print "/* $type */\n\n";

        foreach my $db ( keys %{$config} ) {

            next if $db !~ m{_$type\z} && $db ne $type && $db !~ m{\A$type\_};
            next if $type eq 'write' and $db =~ m{write_root};
            my @hosts = forcearray( $config->{$db}->{from_host} );
            foreach my $from_host ( @hosts ) {
                print
                    qq[GRANT $sql{ $type } ON $config->{$db}->{database}.* to '$config->{$db}->{user}'\@'$from_host' IDENTIFIED BY '$config->{$db}->{pass}';\n];
            }
        }

        print "\nFLUSH PRIVILEGES;\n\n\n";
    }

    return;
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
