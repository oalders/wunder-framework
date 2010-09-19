package Wunder::Framework::CAP::Facebook;

use Moose;
use Modern::Perl;

extends 'Wunder::Framework::CAP::Super';

use Carp qw( croak );
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;
use Lingua::EN::Inflect qw ( PL );
use List::Compare;
use Locale::SubCountry;
use Params::Validate qw ( validate SCALAR );
use WWW::Facebook::API;

use Wunder::Framework::Tools::Toolkit qw( get_dt );

my $DEBUG = 1;
$DEBUG = 0 if !exists $ENV{'SHELL'};

=head2 cgiapp_init

Set session + cookie options, if needed

=cut

sub cgiapp_init {

    my $self = shift;

    return $self->SUPER::cgiapp_init;

}

=head2 setup

CGI::App basic setup.

=cut

sub setup {

    my $self = shift;

    $self->run_modes(
        dumper      => 'dumper',
        help        => 'help',
        location    => 'location',
        post_add    => 'post_add',
        post_remove => 'post_remove',
        profile     => 'profile',
        tos         => 'tos',
    );

    my $path = $self->tmpl_path();
    my @add_path = (
        $self->path . "/templates/base",
        $self->path . "/templates/common",
    );

    if ( $path ) {
        push @{$path}, @add_path
    }
    else {
        $path = \@add_path;
    }
    $self->tmpl_path( $path );

    return $self->SUPER::setup;

}

=head2 load_tmpl

search_path_on_include is not enabled in Wunder::Framework::CAP::Super

=cut

sub load_tmpl {

    my ($self, $tmpl_file, @extra_params) = @_;

    push @extra_params, "search_path_on_include", "1";
    push @extra_params, "loop_context_vars", "1";

    my $template = $self->SUPER::load_tmpl($tmpl_file, @extra_params);
    $template->param( self => $self );
    return $template;

}


=head2 do_token

Call this function whenever Facebook passes us an auth_token

=cut

sub do_token {

    my $self    = shift;
    my $fbc     = $self->fbc;
    my $token   = $self->query->param('auth_token');

    if ( $token ) {

        $fbc->auth->get_session( $token );

        foreach my $param ( 'session_key', 'session_uid', 'session_expires' ) {
            $self->session->param( $param => $fbc->$param );
        }

        my $client = $self->schema->resultset('Client')->find_or_create(
            { user => $fbc->session_uid }
        );

        $client->session_key( $fbc->session_key );
        $client->session_expires( $fbc->session_expires );
        $client->insert_or_update;

    }

    return $fbc;

}

###################################################################
# Begin Run Modes
###################################################################

=head2 post_add

Facebook posts to this page after a user installs the application.
We'll need to initialize the user in the database here.

=cut

sub post_add {

    my $self    = shift;
    my $fbc     = $self->do_token;
    $self->refresh_friends;

    $self->mail_admin(
        subject => $self->config->{'facebook'}->{'app_url'} . " Added",
        data    => $self->client->user,
    );

    return $self->redirect( $self->config->{'facebook'}->{'app_url'} );

}

=head2 post_remove

Facebook posts to this page after a user removes the application.
We'll need to disble the user in the database here.

=cut

sub post_remove {

    my $self = shift;
#    $self->_error_handler;

#    my $client = $self->client;
#    $client->active( 0 );
#    $client->update;

    $self->mail_admin(
        subject => $self->config->{'facebook'}->{'app_url'} . " removed",
        data    => Dumper $self,
    );

    return $self->redirect( $self->config->{'facebook'}->{'app_url'} );

}

=head2 help

Support page.  This is part of the app config on the Facebook end.

=cut

sub help {

    my $self = shift;

    my $path = $self->tmpl_path;
    my $template = $self->load_tmpl;

    return $template->output;

}

=head2 tos

Post the Terms of Service

=cut

sub tos {

    my $self = shift;
    return $self->load_tmpl->output;

}

###################################################################
# Begin Utility Methods
###################################################################

=head2 fbc

Return an instantiated WWW::Facebook::API fbc (FaceBook Client) object

=cut

sub fbc {

    my $self = shift;
    return $self->param('fbc') if $self->param('fbc');

    my $fbc = WWW::Facebook::API->new(
        %{ $self->config->{'facebook'}->{'api'} }
    );

    # is this a call from Facebook?
    if ( $fbc->canvas->in_fb_canvas( $self->query ) ) {

        # should institute some logging here...
        my $valid = $fbc->canvas->validate_sig( $self->query );
        if ( !$valid && $self->get_current_runmode ne 'post_add') {
            #$self->_error_handler;
            #croak "invalid";
        }

        my $attr = $fbc->canvas->get_fb_params( $self->query );
        my $client = $self->schema->resultset('Client')->find(
            { user => $attr->{'user'} }
        );

        $fbc->session_uid( $attr->{'user'} );
        $fbc->session_key( $attr->{'session_key'} );
        $fbc->session_expires( $attr->{'session_expires'} );
    }

    # is it being run from cron?  (no session in that case )
    # in general, I should be able to use my own id to make calls
    elsif ( $ENV{'SHELL'} ) {

        my $client = $self->schema->resultset('Client')->find({ clientid => 1 });

        $fbc->session_uid( $client->user );
        $fbc->session_key( $client->session_key );
        $fbc->session_expires( $client->session_expires );

    }

    # it looks like it's being called directly at the site.  any applicable
    # data should already be in the session
    else {

        foreach my $param ( 'session_key', 'session_uid', 'session_expires' ) {
            if ( $self->session->param( $param ) ) {
                $fbc->$param( $self->session->param( $param ) );
            }
        }
    }

    $self->param( fbc => $fbc );

    return $fbc;
}

=head2 set_fbc( $client )

Mutator -- creates new fbc based on $client object -- for command line use.

=cut

sub set_fbc {

    my $self    = shift;
    my $client  = shift;
    my $fbc     = $self->fbc;

    die "need client" unless $client;

    $fbc->session_uid( $client->user );
    $fbc->session_key( $client->session_key );
    $fbc->session_expires( $client->session_expires );

    return $fbc;

}

=head2 client

Shortcut to return DBIC client obj.

=cut

sub client {

    my $self = shift;

    return $self->param('client') if $self->param('client');
    die "no session" if !$self->fbc->session_uid;

    my $client = $self->schema->resultset('Client')->find_or_create(
        { user => $self->fbc->session_uid }
    );

    # update client if we don't have name etc
    $self->param( client => $client );

    return $client;
}

=head2 set_client( uid )

Client mutator for use at the command line

=cut

sub set_client {

    my $self = shift;
     my $client = $self->schema->resultset('Client')->find(
        { user => shift }
    );

    $self->param( client => $client );

    return $client;

}

=head2 get_friends

Only post a request for friends if they are not already in the params
POSTed to us by Facebook.

=cut

sub get_friends {

    my $self    = shift;
    my $fbc     = $self->fbc;

    if ( $self->fbc->canvas->in_fb_canvas( $self->query ) ) {
        my $response = $fbc->canvas->get_fb_params( $self->query );
        my $friends  = $response->{'friends'};
        my @friends = split ",", $friends;
        return \@friends;
    }

    # returns an ARRAYREF
    else {
        return $fbc->friends->get;
    }

}

=head2 refresh_friends

Refresh list of friends in our database.

1) If client.last_updated is greater than 24h, refresh friend info for *all*
friends

2) If there are uncached friends, refresh info for only these friends

=cut

sub refresh_friends {

    my $self    = shift;
    my $client  = $self->client;
    my $friends = $self->get_friends;
    return unless $friends;

    my $cache_expiry = get_dt();
    $cache_expiry->subtract( days => 1 );

    if ( !$client->last_update || $client->last_update->epoch < $cache_expiry->epoch ) {
        my $updated = $self->cache_user_details( $friends );
        $client->last_update( get_dt );
        $client->update;
        return $updated;
    }

    my @friends = $self->schema->resultset('Friend')->search(
        { user => { -in => $friends } }
    );

    my @cached = ( );
    foreach my $friend ( @friends ) {
        push @cached, $friend->user;
    }

    # get an unsorted list "-u"
    my $lc = List::Compare->new('-u', $friends, \@cached);
    my @uncached = $lc->get_unique;

    return if scalar @uncached == 0;

    return $self->cache_user_details( \@uncached );

}

=head2 cache_user_details

Cache info on friends that is only storable for 24h

=cut

sub cache_user_details {

    my $self        = shift;
    my $friends     = shift;
    my $mode        = shift || 'friend';
    my $friend_list = join ",", @{$friends};
    my $client      = $self->client;
    my $fbc         = $self->fbc;

    my $query = qq[
        SELECT
        uid,
        first_name,
        last_name,
        current_location
        FROM
        user
        WHERE
        uid IN ($friend_list)
    ];

    my $info = $fbc->fql->query( query => $query );

    foreach my $user ( @{$info} ) {

        my $user_row = undef;

        if ( $mode ne 'user' ) {

            my $friend = $client->find_or_create_related(
                'friend', { user => $user->{'uid'} }
            );

            $user_row = $friend->find_or_create_related( 'user', {} );
            $friend->insert_or_update;
        }

        else {
            $user_row = $self->schema->resultset('User')->find_or_create(
                { userid => $user->{'uid'} }
            );
        }

        # first and last name will never be null
        $user_row->first_name( $user->{'first_name'} );
        $user_row->last_name( $user->{'last_name'} );

        $self->geo_update( $user, $user_row );

        $user_row->insert_or_update;
    }

    return $friend_list;

}

=head2 profile

Renders the profile page box.

=cut

sub profile {

    my $self    = shift;
    my $t       = $self->load_tmpl('profile.html');

    $t->param(
        add_url         => $self->fbc->get_add_url,
        app_url         => 'http://apps.facebook.com/' . $self->config->{'facebook'}->{'app_url'},
        dt              => get_dt(),
        uid             => $self->fbc->session_uid,
    );

    return $t->output;
}

=head2 geo_update( $user, $row )

Update geo info for users.  Can be complicated since we don't like
the FB format for Geo info...

=cut

sub geo_update {

    my $self = shift;
    my ( $user, $user_row ) = @_;

    # city and zip need no normalization
    my $loc = $user->{'current_location'};
    foreach my $col ( 'city', 'zip' ) {
        if ( exists $loc->{$col} && $loc->{$col} =~ m{[\w\d]} ) {
            $user_row->$col( $loc->{$col} );
        }
        else {
            $user_row->$col( undef );
        }
    }

    my $geo_update = 0;
    if ( exists $loc->{'country'} && $loc->{'country'} =~ m{\w} ) {
        my $country = Locale::SubCountry->new( $loc->{'country'} );
        if ( $country ) {
            $user_row->country( $country->country_code );
            my $state = $loc->{'state'};

            # US states are already ISO compliant
            if ( $country->country_code ne 'US' ) {
                $state = $country->code( $loc->{'state'} );
                if ( $state eq 'unknown' ) {
                    $state = undef;
                }
            }
            #print join "\t", $friend->user->userid, $country->country_code, $loc->{'state'}, $state, "\n" if $DEBUG;
            $user_row->state( $state );
            $geo_update = 1;
        }
    }

    if ( !$geo_update ) {
        $user_row->country( undef );
        $user_row->state( undef );
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
