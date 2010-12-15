#!/usr/bin/perl

=head2 SYNOPSIS

Use this script to add update DBIC schema table definitions.  Generally there will be 
a module in lib/dev/YourModule/Schema.pm which gives you some choices for running
this script.

=cut

use DBIx::Class::Schema::Loader;
use Find::Lib '../lib/dev', '../lib';
use IO::Prompt;
use Modern::Perl;

use Wunder::Framework::Bundle;

my $base    = Wunder::Framework::Bundle->new();
my $config  = $base->config;
my @schemas = keys %{ $config->{'db'} };

my @menu = ();
foreach my $name ( @schemas ) {
    push @menu, $name if $name =~ /write\z/;
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

if ( $auth eq 'y' ) {

    my $db        = $config->{'db'}->{$update_schema};
    my $namespace = $db->{'namespace'};
    print "ok, updating $namespace\n";
    eval "require $namespace";

    DBIx::Class::Schema::Loader->dump_to_dir( $base->path . '/lib' );

    #$namespace->dump_to_dir( $base->path .'/lib');
    $namespace->connection( $db->{'dsn'}, $db->{'user'}, $db->{'pass'} );

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
