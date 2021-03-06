package Wunder::Framework::CAP::FormMail;

use Moose;
use Modern::Perl;

extends 'Wunder::Framework::CAP::Super';

use Wunder::Framework::Tools::Toolkit qw( forcearray );

use Data::Dumper;
use List::Util qw( any );
use MIME::Lite ();

has 'email_from' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_email_from',
);

has 'form_config' => (
    is      => 'rw',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    builder => '_build_form_config',
);

=head2 setup

This should be a small module.  Few run modes.  It's the OO version of the
wunderInfo.cgi script.  It will start with stripped-down functionality, but
I'll add in the features as they are needed.

=cut

sub setup {

    my $self = shift;

    $self->start_mode( 'send_mail' );
    $self->run_modes( send_mail => 'send_mail', );

    $self->tmpl_path(
        [ forcearray( $self->config->{'form_mail'}->{'template_path'} ) ] );

    return $self->SUPER::setup;

}

=head2 send_mail

The guts of the module.  Send out the mail message.  :)

=cut

sub send_mail {

    my $self = shift;
    my $q    = $self->query;

    if ( !$self->required_ok ) {
        return $self->template->fill(
            $self->config->{'form_mail'}->{'error_template'},
            $self->stash );
    }

    my $config = $self->form_config;
    die "config missing" if !$config;

    ### Create a new multipart message:
    my $msg = MIME::Lite->new(
        From    => $self->email_from,
        To      => $config->{'To'},
        Subject => $config->{'Subject'},
        Type    => 'multipart/alternative'
    );

    foreach my $header ( 'Cc', 'Bcc' ) {
        if ( exists $config->{$header} && $config->{$header} ) {
            $msg->add( $header => $config->{$header} );
        }
    }

    ### Add parts (each "attach" has same arguments as "new"):
    my $text_part = MIME::Lite->new(
        Type => 'TEXT',
        Data => $self->text_message,
    );

    $msg->attach( $text_part );

    unless ( $config->{text_only} ) {

        my $html = $self->html_message;

        ### Create a standalone part:
        my $html_part = MIME::Lite->new(
            Type => 'text/html',
            Data => $$html,
        );

        $html_part->attr( 'content-type.charset' => 'UTF8' );
        $msg->attach( $html_part );

    }

    # Is there a file upload to be attached?
    my @uploads = forcearray( $config->{'uploads'} );

    foreach my $upload ( @uploads ) {

        if ( $q->param( $upload ) ) {

            my $filename    = $q->param( $upload );
            my $type        = $q->uploadInfo( $filename )->{'Content-Type'};
            my $tmpfilename = $q->tmpFileName( $filename );

            $msg->attach(
                Type        => $type,
                Path        => $tmpfilename,
                Filename    => $filename,
                Disposition => 'attachment'
            );
        }
    }

    $self->send_msg( $msg );
    $self->on_success();
    return $self->redirect( $config->{'redirect'} );

}

=head2 _build_form_config

Shortcut to config for this particular form

=cut

sub _build_form_config {

    my $self = shift;
    my $form_id = $self->query->param( 'form_id' ) || 'default';
    return if !exists $self->config->{'form_mail'}->{$form_id};
    return $self->config->{'form_mail'}->{$form_id};

}

sub _build_email_from {

    my $self   = shift;
    my $q      = $self->query;
    my $sender = $q->param( 'first_name' ) . ' ' . $q->param( 'last_name' );
    my $sender_email = $q->param( 'email' )
        || $self->form_config->{'recipient_email'};

    $sender = 'Web User' if $sender !~ m{\w}gxms;

    return "$sender <$sender_email>";

}

=head2 filter

Make sure that some nasty characters are stripped away.  This can be modified
later to do encoding etc instead of just stripping things away.

=cut

sub filter {

    my $self   = shift;
    my $data   = shift;
    my $filter = $self->config->{'form_mail'}->{'filter_regex'};
    $data =~ s{ $filter }{}gxms;

    return $data;

}

=head2 text_message

Send a text attachment which can be used if something goes wrong with the
HTML.  Could also be parsed out later by a script etc.

=cut

sub text_message {

    my $self         = shift;
    my $q            = $self->query;
    my $text_message = qq[Here are the contents of the form: \n\n];

    my @ignore = forcearray( $self->form_config->{'ignore'} );

    # Get all the values of the form and send them in the email
    foreach my $name ( $q->param ) {

        my $label = $self->filter( $name );

        # tampered values?
        next if $label ne $name;
        next if any { $_ eq $label } @ignore;

        my $value = $self->filter( $q->param( $label ) );

        $text_message .= qq [$label : $value\n];

    }

    return $text_message;
}

=head2 html_message

Constructs HTML message body

=cut

sub html_message {

    my $self = shift;
    return $self->fill_form(
        $self->template->fill( $self->form_config->{'template'} ) );

}

=head2 required_ok

Checks to see if required fields have been defined and exist

=cut

sub required_ok {

    my $self     = shift;
    my $q        = $self->query;
    my $required = $self->form_config->{'required'};
    return 1 if !$required || scalar keys %{$required} == 0;

    my @errors = ();

    foreach my $field ( keys %{$required} ) {

 #$self->logger( " $field : $required->{ $field } : " . $q->param( $field ) );
        if ( exists $required->{$field} && !$q->param( $field ) ) {
            push @errors,
                {
                field_name => $required->{$field},
                message    => "input required",
                };
        }
    }

    if ( @errors ) {
        $self->stash( errors => \@errors );
        return 0;
    }

    return 1;

}

=head2 on_success

Stub method which can be overridden by a subclass

=cut

sub on_success {
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
