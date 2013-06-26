package Wunder::Framework::Roles::Deployment;

use Moose::Role;
use Carp qw( croak );
use Config::General;
use Find::Lib;
use Hash::Merge qw( merge );
use Modern::Perl;

=head1 SYNOPSIS

The various roles required for deploying to an environment with
multiple staging streams.

=head2 stream

Return the name of this staging stream

=head2 path

Return the path to this installation

=head2 site

Return the site name in the path of this installation

=cut

has 'path' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has 'site' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has 'stream' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_stream {

    my $self = shift;

    foreach my $key ( 'WF_STREAM', 'CUSTOM_STREAM' ) {
        return $ENV{$key} if exists $ENV{$key};
    }

    if ( Find::Lib::base() =~ m{/home/co/(\w+)/}xsm ) {
        return $1;
    }

    croak "stream could not be discovered";

}

sub _build_path {

    my $self = shift;
    foreach my $key ( 'WF_PATH', 'CUSTOM_PATH' ) {
        return $ENV{$key} if exists $ENV{$key};
    }

    my @dirs = split "/", Find::Lib::base();

    croak "no path" if scalar @dirs < 5;

    # pattern is /home/co/stream/site
    return join "/", @dirs[ 0 .. 4 ];

}

sub _build_site {

    my $self = shift;
    my $path = $self->path;

    my @dirs = split "/", $path;

    # pattern is /home/co/stream/site
    return pop @dirs;

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
