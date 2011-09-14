package Wunder::Framework::Roles::Config;

use Moose::Role;
use Carp qw( croak );
use Config::General;
use Cwd;
use Find::Lib;
use Hash::Merge qw( merge );
use Modern::Perl;

=head1 SYNOPSIS

The various roles required for deploying with config files.

=head2 config

Return config file object for this staging stream (db info).  The file
should be found here:

/home/co/$stream/$site/conf/$stream/base.cfg

A global config file may be placed at:

/home/co/$stream/$site/conf/global.cfg

This file should contain any elements which are common to all config files or
any elements which should serve as defaults.  These settings can be
overridden in any of the base.cfg files

Local config files may be placed at:

/home/co/$stream/$site/conf/$stream/local.cfg

These would generally be files which should not be under version control
as they would be used to differentiate configs between load balanced
machines.

This method will return an empty HASHREF if no config files are found.  It
will not die (or even warn) as there may be perfectly valid reasons for
using the framework without initialized config files.

=cut

has 'config' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has 'config_base' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_config {

    my $self = shift;

    my $base   = $self->config_base . $self->stream . "/base.cfg";
    my $config = {};

    if ( -e $base ) {
        $config = { Config::General->new( $base )->getall };
    }

    foreach my $type ( 'global', $self->stream . '/local' ) {

        my $file = $self->config_base . $type . '.cfg';

        if ( -e $file ) {
            my $add_config = { Config::General->new( $file )->getall };

            if ( $type =~ m{local} ) {
                $config = merge( $add_config, $config );
            }
            else {
                $config = merge( $config, $add_config );
            }
        }

    }

    return $config;

}

sub _build_config_base {

    my $self = shift;
    return $self->path . '/conf/';

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
