#!/usr/bin/perl

use Modern::Perl;

=head1 SYNOPSIS

We can't expect the paid library to be installed on every machine, so the
->geo method shouldn't fail on undef

=cut

use Data::Dump qw( dump );
use Test::More tests => 5;
use Wunder::Framework::Bundle;
use Wunder::Framework::Test::Roles::GeoCode;

my $wf = Wunder::Framework::Bundle->new;

SKIP: {

    my $conf = $wf->config->{google}->{maps};

    skip "Prereqs missing", 5 
        unless ( exists $conf->{table} && $conf->{api_key} );
        
        require_ok( $wf->config->{db}->{ $conf->{schema} }->{'namespace'} );
    my $coder = Wunder::Framework::Test::Roles::GeoCode->new(
        dbic => $wf->schema->resultset( 'GeoCode' ) );

    ok( $coder->api_key, "got an api key: " . $coder->api_key );
    
    my $point = $coder->geo_code( country => 'CA' );
    ok( $point, "got a point back for CA" );
    cmp_ok( $point->latitude, '==', 36.778261, "correct latitude" );
    cmp_ok( $point->longitude, '==', -119.4179324, "correct longitude" );
    
    my %cols = $point->get_columns;
    #diag( dump \%cols );

}
