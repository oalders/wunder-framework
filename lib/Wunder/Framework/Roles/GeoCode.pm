package Wunder::Framework::Roles::GeoCode;

use Moose::Role;

#requires 'config';

use Data::Dump qw( dump );
use Geo::Coder::GoogleMaps;
use Modern::Perl;
use Params::Validate qw( validate SCALAR );

=head1 SYNOPSIS

GeoCode and cache postal addresses.  Requires a GeoCode schema object,
which is a table which looks something like this:

CREATE TABLE `geo_code` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `address` varchar(100) default NULL,
  `city` varchar(100) default NULL,
  `region` varchar(30) default NULL,
  `country` char(2) NOT NULL default '',
  `latitude` double(13,9) default NULL,
  `longitude` double(13,9) default NULL,
  `lookup_source` enum('google','geo_coder_us') NOT NULL default 'google',
  `lookup_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM;

=head2 geo_code( country => 'CA', region => 'ON', city => 'Toronto', address => '1 Yonge St.' )

Returns a dbic row with the result of your lookup. The country field is required.  All
other params are optional. 

=cut

has 'api_key' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 0,
    lazy_build => 1,
);

has 'dbic' => (
    is => 'rw',

    #isa        => 'Geo::IP',
    required => 1,
);

sub _build_api_key {

    my $self = shift;
    return $self->config->{'google'}->{'maps'}->{'api_key'};

}

sub geo_code {

    my $self = shift;

    my %rules = (
        country => { type => SCALAR, optional => 0, },
        region  => { type => SCALAR, optional => 1, default => undef, },
        city    => { type => SCALAR, optional => 1, default => undef, },
        address => { type => SCALAR, optional => 1, default => undef, },
    );

    my %args = validate( @_, \%rules );

    my @cols = ( 'address', 'city', 'region', 'country', );

    # make sure we don't have blank cols -- only NULLs
    foreach my $col ( @cols ) {
        $args{$col} = undef if !$args{$col};
    }

    my $point = $self->dbic->find_or_create( \%args );

    if ( !$point->lookup_time ) {

        my $gmap = Geo::Coder::GoogleMaps->new(
            apikey => $self->api_key,
            output => 'xml',
        );

        my @address = ();
        foreach my $col ( @cols ) {
            push @address, $point->$col if $point->$col;
        }

        my $address = join ",", @address;

        my $location = $gmap->geocode( location => $address );

        if ( defined $location && $location->latitude ) {

            $point->longitude( $location->longitude );
            $point->latitude( $location->latitude );
            $point->lookup_source( 'google' );

            #say "original latitude: " . $location->latitude;
            #say "original longitude: " . $location->longitude;

        }

        $point->insert_or_update;

    }

    return $point;

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
