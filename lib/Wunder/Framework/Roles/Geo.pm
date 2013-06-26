package Wunder::Framework::Roles::Geo;

use Moose::Role;
use Carp qw( croak );
use Geo::IP;

=head1 SYNOPSIS

Returns the appropriate Geo::IP objects.  Saves you from having to remember
where the libraries are located.

=head2 geo

Returns a Geo::IP object.  Uses the paid City database.

=head2 geo_lite

Returns a Geo::IP object using the free database.

=head2 best_geo

Returns an object using the best available Geo::IP City library

=cut

has 'geo' => (
    is => 'ro',

    #isa        => 'Geo::IP',
    lazy_build => 1,
);

has 'geo_lite' => (
    is         => 'ro',
    isa        => 'Geo::IP',
    lazy_build => 1,
);

has 'geo_org' => (
    is => 'ro',

    #isa        => 'Geo::IP',
    lazy_build => 1,
);

has 'best_geo' => (
    is         => 'ro',
    isa        => 'Geo::IP',
    lazy_build => 1,
);

my $geo_folder = '/usr/share/GeoIP';

sub _build_geo {

    my $self = shift;
    my $geo  = undef;
    my $file = $geo_folder . '/GeoIPCity.dat';

    return if !-e $file;
    return Geo::IP->open( $file, GEOIP_STANDARD );

}

sub _build_geo_lite {

    my $self = shift;
    my $geo_lite
        = Geo::IP->open( $geo_folder . '/GeoLiteCity.dat', GEOIP_STANDARD )
        || croak $!;

    return $geo_lite;

}

sub _build_geo_org {

    my $self = shift;
    return Geo::IP->open( $geo_folder . '/GeoIPOrg.dat', GEOIP_STANDARD );

}

sub _build_best_geo {

    my $self = shift;
    return $self->geo || $self->geo_lite;

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
