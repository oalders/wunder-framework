package Wunder::Framework::Tools::Build::CPAN;

use Moose;
use MooseX::Params::Validate;
use Modern::Perl;

use Data::Dump qw( dump );
use File::Find::Object::Rule;
use Find::Lib;
use List::Util qw( any );
use YAML::Syck;

=head1 SYNOPSIS

Try to find all of the dependencies for a code distribution.

=head2 find_deps(['/path/to/lib1', '/path/to/lib2' ])

Returns an ARRAY of package names

=head2 ignore

Supply an ARRAYREF of module names to ignore

=head2 ignore_rex

Supply an ARRAYREF of regexes to be used when ignoring modules

=cut


has 'ignore' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'ignore_regex' =>
    ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub find_deps {

    my $self = shift;
    my $dirs = shift || [ Find::Lib::base() . '/../lib' ];

    my $debug   = $ENV{'DEBUG'};
    my $include = '';

    foreach my $folder ( @{$dirs} ) {
        $include = '-I' . $folder . ' ';
    }

    my %mods = ();

    say "dirs: " . dump( $dirs ) if $debug;

    foreach my $folder ( @{$dirs} ) {

        say "searching $folder" if $debug;
        my @files = File::Find::Object::Rule->file()->name( '*pm', "*.pl" )
            ->in( $folder );

        say dump \@files if $debug;

        # this is a hack, since Devel::Modlist is meant to be used at the
        # command line

        foreach my $mod ( @files ) {

            my $command
                = "perl $include -MDevel::Modlist=yaml,nocore,stdout $mod";
            say $command if $debug;

            my $data = `$command`;
            my $yaml = Load( $data );

            foreach my $mod ( keys %{ $yaml->{'Requires'} } ) {
                $mods{$mod} = 1;
            }
        }

    }

    foreach my $key ( sort keys %mods ) {

        delete $mods{$key} if $key =~ m{\AWunder};
        delete $mods{$key} if any { $_ eq $key } @{ $self->ignore };

    REGEX:
        foreach my $regex ( @{ $self->ignore_regex } ) {
            if ( $key =~ $regex ) {
                delete $mods{$key};
                last REGEX;
            }
        }

    }

    return ( sort keys %mods );

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
