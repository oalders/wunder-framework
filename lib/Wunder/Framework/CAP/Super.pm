package Wunder::Framework::CAP::Super;

use Moose;
use Modern::Perl;
use MooseX::Params::Validate;

extends qw( CGI::Application::Plugin::HTDot CGI::Application );

with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::DBI';
with 'Wunder::Framework::Roles::DateTime';
with 'Wunder::Framework::Roles::Email';
with 'Wunder::Framework::Roles::Geo';
with 'Wunder::Framework::Roles::Log';

# "Use" libraries that we *always* need
use Carp qw( croak );
use CGI::Application::Plugin::AnyTemplate;
use CGI::Application::Plugin::FillInForm ( qw/fill_form/ );
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Stash;
use Data::Dump qw( dump );
use Params::Validate qw( validate validate_pos SCALAR );

use Wunder::Framework::Tools::FormBuilder;
use Wunder::Framework::Tools::Toolkit qw( commify converter get_dt round moneypad );

=head2 SYNOPSIS

The Wunder SuperClass.  Methods in here will generally be methods that will
override core methods in CGI::Application.

=head2 add_to_path( \@paths )

Add template directories to the tmpl_path param

=cut

=head2 cgiapp_init

Set up some basic config variables.

=head2 fb

Returns a FormBuilder object

=head2 load_tmpl

Turns on caching and turns off param checking in *every* case.  I never
want to die on bad params otherwise, so why start now?  Caching now off
bec. it seemed to cause conflicts across sites with similar template
names.

=head2 not_found

Generic routine to generate 404 pages

=head2 push_tmpl_path

Convenience method for add_to_path

=head2 stash_cols( $dbic )

When provided with a DBIC object, will stash each column as a param.  Good
for TT.

=head2 tt( $template )

Shortcut for rendering TT templates

=head2 tt_filters

Stub method for supplying filter methods to Template Toolkit

=head2 template_config

Override this method to set custom template configuration options

=head2 status codes

=head3 status_msg

Generic handling of Apache status codes.  Attach additional error msg for
clarification if present.

=head3 bad_request

Generic routine to generate 400 pages when url and params are
correct, but don't make any sense

=head3 unauthorized

Generic routine to generate 401 pages when proper user
credentials are missing

=head2 _error_handler

Try to do something useful with state of CGI if unexpected death occurs.
Enable this in your class by adding the following to setup()

$self->error_mode( '_error_handler' );

=cut

has 'fb' => (
    is         => 'ro',
    isa        => 'Wunder::Framework::Tools::FormBuilder',
    lazy_build => 1,
);

sub _build_fb {

    my $self = shift;
    my $fb = Wunder::Framework::Tools::FormBuilder->new;
    $fb->encode_this( 1 );
    return $fb;

}

sub cgiapp_init {

    my $self = shift;

    $self->param( server_name => $ENV{'SERVER_NAME'} );
    $self->error_mode( '_error_handler' );
    $self->header_add( -charset => 'utf-8' );

    # default error messages for FormValidator subs
    my $dfv_defaults = {
        missing_optional_valid => 1,
        filters                => 'trim',
        msgs                   => {
            any_errors => 'some_errors',
            prefix     => 'err_',
            missing    => 'required',
            invalid    => 'input not valid',
        },
    };

    $self->param( 'dfv_defaults' )
        || $self->param( 'dfv_defaults', $dfv_defaults );

    $self->template->config( %{ $self->template_config } );

    return $self->SUPER::cgiapp_init();

}


sub template_config {

    my $self = shift;

    return {
        default_type    => 'TemplateToolkit',
        TemplateToolkit => {
            POST_CHOMP         => 1,
            template_extension => '.html',
            RELATIVE           => 1,
            add_include_paths  => '.',
            FILTERS            => $self->tt_filters,
        },
    };


}

sub load_tmpl {

    my ( $self, $tmpl_file, @extra_params ) = @_;

    push @extra_params, "die_on_bad_params", "0";
    push @extra_params, "loop_context_vars", "1";

    return $self->SUPER::load_tmpl( $tmpl_file, @extra_params );
}

sub _error_handler {

    my $self = shift;

    # don't send messages from testbed
    if ( exists $ENV{'HARNESS_ACTIVE'} ) {
        return;
    }

    my $error_data = "http://$ENV{'SERVER_NAME'}$ENV{'REQUEST_URI'}\n\n";

    if ( exists $self->config->{'admin_key'} ) {
        my $key = $self->config->{'admin_key'};
        $error_data
            .= "http://$ENV{'SERVER_NAME'}$ENV{'REQUEST_URI'}&admin_key=$key\n\n";
    }

    #$error_data .= $self->dump();
    $error_data .= dump \%ENV;
    $error_data .= dump( { $self->query->Vars } );
    $error_data .= "\n@_\n";
    $error_data .= "tmpl_path: " . dump( $self->tmpl_path );
    #$error_data .= $@;
    #$error_data .= $!;

    $self->logger( $error_data );

    if ( $self->param( 'username' ) ) {
        $error_data .= "username: " . $self->param( 'username' );
    }

    my $server = $self->param( 'server_name' ) || $ENV{'SERVER_NAME'};

    my $msg = MIME::Lite->new(
        From    => 'olaf@wundersolutions.com',
        To      => $self->config->{'contact'}->{'notify'},
        Subject => $server . ' error',
        Data    => $error_data,
    );

    $self->send_msg( $msg );
    my $support = 'support@wundercounter.com';
    if ( $self->config ) {
        $support = $self->config->{'contact'}->{'support_email'};
    }

    $self->header_props( -status => 500 );

    # return the generic message can mess with XML for APIs etc
    return if $self->param( 'no_500_msg' );

    if ( $self->config && exists $self->config->{'error_msg'} ) {
        return
              '<html><body>'
            . $self->config->{'error_msg'}
            . '</body></html>';
    }

    return qq[
        <html><body>An error has occurred.  The site administrator has been
        informed. If this error is not fixed in a timely manner, please
        contact <a href="mailto:$support">$support</a></body></html>
    ];

}

sub add_to_path {

    my $self = shift;
    my $add  = shift;
    return $self->tmpl_path if !$add;

    my $path = $self->tmpl_path();
    my @path = ();

    if ( ref $path ne 'ARRAY' ) {
        push @path, $path if $path;
    }
    else {
        push @path, @{$path};
    }

    push @path, @{$add};

    $self->tmpl_path( \@path );

    return $self->tmpl_path();

}

sub push_tmpl_path {

    my $self = shift;
    return $self->add_to_path( @_ );

}

sub tt_filters {

    my $self = shift;

    return {
        commify         => sub { return commify( shift ) },
        date_from_epoch => sub {
            my $epoch = shift;
            return if !$epoch;
            return $self->dt( epoch => $epoch )->ymd;
        },
        datetime_from_epoch => sub {
            my $epoch = shift;
            return if !$epoch;
            my $dt = $self->dt( epoch => $epoch );
            return $dt->ymd . ' ' . $dt->hms;
        },
        time_from_epoch => sub {
            my $epoch = shift;
            return if !$epoch;
            my $dt = $self->dt( epoch => $epoch );
            return $dt->hms;
        },

        int   => sub { return int( shift ) },
        round => sub { return round( shift ) },
        moneypad => sub { return moneypad( shift ) },

        nbsp => sub {
            my $line = shift;
            $line =~ s{\s}{&nbsp;}gxms;
            return $line;
        },

    };

}

sub tt {

    my $self = shift;
    return $self->template->fill( shift() || $self->get_current_runmode,
        $self->stash );

}

sub not_found {

    my $self = shift;

    if ( exists $ENV{'MOD_PERL'} ) {
        $self->header_add( -status => 404 );
        return $self->redirect( '/' );
    }

    $self->header_props( -status => 404 );
    return $self->status_msg( "404: Not Found" );

}

sub unauthorized {

    my $self = shift;

    if ( exists $ENV{'MOD_PERL'} ) {
        $self->header_add( -status => 401 );
        return $self->redirect( '/' );
    }

    $self->header_props( -status => 401 );
    return $self->status_msg( "401: Unauthorized" );

}

sub bad_request {

    my $self = shift;

    if ( exists $ENV{'MOD_PERL'} ) {
        $self->header_add( -status => 400 );
        return $self->redirect( '/' );
    }

    $self->header_props( -status => 400 );
    return $self->status_msg( "400: Bad Request" );

}

sub status_msg {

    my $self = shift;
    my $msg  = shift;

    if ( exists $self->stash->{'status_error'} ) {
        $msg .= " (" . $self->stash->{'status_error'} . ")";
    }

    return $msg;

}

sub stash_cols {

    my $self = shift;
    my @args = validate_pos( @_, { isa => 'DBIx::Class' } );
    my $dbic = shift @args;
    my @cols = $dbic->columns;

    foreach my $col ( @cols ) {
        $self->stash( $col => $dbic->$col );
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
