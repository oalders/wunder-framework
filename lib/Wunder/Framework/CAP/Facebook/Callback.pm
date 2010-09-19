package Wunder::Framework::CAP::Facebook::Callback;

use Moose;
use Modern::Perl;

use CGI;
use CGI::Application::Plugin::FillInForm (qw/fill_form/);
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;
use HTML::Entities;

extends 'Wunder::Framework::CAP::Facebook';

use Wunder::Framework::Tools::Toolkit qw( get_dt );


=head2 cgiapp_prerun

Set run mode here based on some criteria, like whether we are being called in
canvas mode.

add_required should not be run in every case.  This needs to be fixed.

=cut

sub cgiapp_prerun {

     my $self   = shift;
     my $fbc    = $self->fbc;

     if ( $fbc->canvas->in_fb_canvas( $self->query ) ) {
          my $fb_params = $fbc->canvas->get_fb_params( $self->query );
          if ( $fb_params->{'added'} == 0 ) {
               $self->prerun_mode('add_required');
          }
          else {
               $self->refresh_friends;
          }
     }

     # login_required was initially here, but that message was also coming up
     # for users who had not yet added the app...
     if ( !$fbc->session_key ) {
          $self->prerun_mode( 'add_required' );
     }

    $self->logger( Dumper $self);
    $self->logger( Dumper \%ENV);
    $self->logger( Dumper $self->query );

    return $self->SUPER::cgiapp_prerun;

}

=head2 setup

Run mode setup.

=cut

sub setup {

    my $self = shift;

    $self->start_mode('canvas') if $self->start_mode eq 'start';

    $self->run_modes(
        add_required     => 'add_required',
        callback         => 'callback',
        canvas           => 'canvas',
        invite           => 'invite',
        login_required   => 'login_required',
        post_invite      => 'post_invite',
    );

    my @path = qw(
        $self->path . "/templates/callback"
        $self->path . "/templates/common"
    );

    $self->tmpl_path( \@path );

    # facebook turns links into POST, so GET params can be lost...
    my $query = $self->query;
    if ( !$query->param('rm') && $query->url_param('rm') ) {
        $query->param( rm => $query->url_param('rm') );
    }

    return $self->SUPER::setup;

}

=head2 load_tmpl

Set a few custom params.

=cut

sub load_tmpl {

     my $self       = shift;
     my $template   = $self->SUPER::load_tmpl( @_ );

     $template->param(
          app_url => $self->config->{'facebook'}->{'app_url'},
          app_name => $self->config->{'facebook'}->{'app_name'},
     );

     return $template;
}

=head2 callback

This is the page Facebook forwards the user to.  A token is passed as a query
param.

=cut

sub callback {

    my $self = shift;
    my $fbc = $self->do_token;

    return $self->redirect("/callback.cgi?rm=location");

}

=head2 add_required

Force user to sign up before accessing site

=cut

sub add_required {

    my $self = shift;
    my $template = $self->load_tmpl;

    $template->param( add_url => $self->fbc->get_add_url );
    return $template->output;

}

=head2 canvas

Create the canvas page

=cut

sub canvas {

     my $self       = shift;
     my $client     = $self->client;
     my $config     = $self->config;
     my $fbc        = $self->fbc;
     my $friends    = $self->get_friends;
     my $query      = $self->query;
     my $t          = $self->load_tmpl();

    return $t->output;

}

=head2 invite

Create the invitation page

=cut

sub invite {

     my $self       = shift;
     my @exclude    = ( );
     my $fbc        = $self->fbc;
     my $t          = $self->load_tmpl();

     # don't invite folks who already have the app
     if ( $self->config->{'facebook'}->{'invite'}->{'exclude_friends'} ) {
          @exclude = @{ $fbc->friends->get_app_users };
     }

     # don't invite folks whom you have already invited
     if ( $self->config->{'facebook'}->{'invite'}->{'exclude_previous'} ) {

          my $rs = $self->client->search_related(
               'invitation',
          );

          while ( my $invite = $rs->next ) {
               push @exclude, $invite->user;
          }

     }

     $t->param( exclude_ids => join ",", @exclude );

     # create and decode message body
     my $body = $self->load_tmpl('includes/invite_msg.html');
     $t->param( invite_msg => encode_entities( $body->output ) );

     return $t->output;

}

=head2 post_invite

Log users to whom invitations have been sent so we exclude them next time

=cut

sub post_invite {

     my $self  = shift;
     my $client = $self->client;
     my $dt    = get_dt();
     my @ids   = $self->query->url_param('ids[]');

     foreach my $id ( @ids ) {

          my $invite = $client->find_or_create_related(
               'invitation',
               { user => $id }
          );

          $invite->date( $dt->ymd );
          $invite->update;
     }

     return $self->forward('invite');

}


=head2 login_required

Page is being hit without session info and outside of the canvas

=cut

sub login_required {

     my $self = shift;
     my $fbc = $self->fbc;

     return "login required " . $fbc->session_key;
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
