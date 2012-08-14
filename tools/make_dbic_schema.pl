#!/usr/bin/env perl

=head2 SYNOPSIS

Use this script to add update DBIC schema table definitions.  Generally there will be
a module in lib/dev/YourModule/Schema.pm which gives you some choices for running
this script.

=head2 USAGE

perl wunder-tools/make_dbic_schema.pl  --constraint table_name --debug

=cut

use Data::Dump qw( dump );
use DBIx::Class::Schema::Loader qw( make_schema_at );
use Find::Lib '../lib/dev', '../lib';
use Getopt::Long::Descriptive;
use IO::Prompt;
use Modern::Perl;

use Wunder::Framework::Bundle;

my ( $opt, $usage ) = describe_options(
    'my-program %o <some-arg>',
    [ 'all|a',        "display all schemas in config" ],
    [ 'constraint=s', "table name regex" ],
    [ 'debug',        "print debugging info" ],
    [   'overwrite_modifications',
        'overwrite modifications (helpful in case of checksum mismatch)'
    ],
    [ 'naming=s',       'v4|current', ],
    [ 'use_namespaces', '1|0' ],
    [ 'components=s', 'default Result components split by ,'],
    [ 'moose', '1|0'],
    [],
    [ 'help', "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

my $base    = Wunder::Framework::Bundle->new();
my $config  = $base->config;
my @schemas = keys %{ $config->{'db'} };

my @menu = ();
foreach my $name ( @schemas ) {
    push @menu, $name if ( $opt->all || $name =~ /write\z/ );
}

# backwards compatibility for older naming schemes
if ( scalar @menu == 0 ) {
    foreach my $name ( @schemas ) {
        push @menu, $name;
    }
}

my $update_schema = prompt(
    "Which schema would you like to update?",
    -m => \@menu,
    -one_char
);

print "You have chosen to update $update_schema\n";
my $auth = prompt( "Is this correct? (y/n) \n\n", -onechar );
say '';

if ( $auth eq 'y' ) {

    my $db        = $config->{'db'}->{$update_schema};
    my $namespace = $db->{'namespace'};
    say "ok, updating $namespace\n";

    my $args = {
        constraint => $opt->constraint || qr{.*},
        debug => $opt->debug,
        dump_directory          => $base->path . '/lib',
        overwrite_modifications => $opt->overwrite_modifications || 0,
        naming                  => $opt->naming || 'v4',
        use_namespaces          => $opt->use_namespaces || 0,
        use_moose               => $opt->moose || 0,
    };

    $args->{components} = [ split /,/, $opt->components ] if $opt->components;

    say "args: " . dump( $args ) if $opt->debug;

    make_schema_at( $namespace, $args,
        [ $db->{'dsn'}, $db->{'user'}, $db->{'pass'} ],
    );

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
