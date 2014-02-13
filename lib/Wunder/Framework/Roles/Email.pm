package Wunder::Framework::Roles::Email;

use strict;
use warnings;

use DateTime::Format::Mail;
use Email::Sender::Simple qw(sendmail);
use MIME::Lite;
use Modern::Perl;
use Moose::Role;
use Params::Validate qw( validate SCALAR );

has 'smtp_conf' => ( is => 'rw', lazy_build => 1, );

sub _build_smtp_conf {
    my $self = shift;
    return $self->config->{email}->{smtp};
}

=head1 SYNOPSIS

The various roles required for sending email via generic methods

=head2 send_msg( $msg )

Requires a MIME::Lite object.

Try to offload emailing onto external machines. If the first attempt
fails, use sendmail, which will queue the message if it's unable to send from
here. A failed connection on the SMTP method will result in the message not
being delivered and we may never know about it.

To use SMTP, something like the following needs to be in the config file:

<email>
    <outgoing_headers>
        Sender          = mail@domain.com
        X-Envelope-From = mail@domain.com
    </outgoing_headers>
    <smtp>
        default = 1
        enabled = 1
        server = smtp.domain.com
        <args>
            Timeout  = 300
            #Port     = 26
            Debug    = 1
        </args>
    </smtp>
</email>

=cut

sub send_msg {

    my $self = shift;
    my $msg  = shift;

    $msg = $self->datestamp_msg( $msg );

    # these are for defaults. don't clobber existing headers
    if ( exists $self->config->{email}->{outgoing_headers} ) {
        my %headers = %{ $self->config->{email}->{outgoing_headers} };
        foreach my $header ( keys %headers ) {
            if ( !$msg->get( $header ) ) {
                $msg->add( $header => $headers{$header} );
            }
        }
    }

    my $conf = $self->smtp_conf;

    # is SMTP our first choice?
    if ( $conf && $conf->{'default'} ) {
        return 1 if $self->_send_by_smtp( $msg );
    }

    return 1 if sendmail( $msg->as_string );
    return $self->_send_by_smtp( $msg );

}

=head2 datestamp_msg( $msg )

Attach a date stamp to the msg

=cut

sub datestamp_msg {

    my $self = shift;
    my $msg  = shift;

    my $stamp = DateTime::Format::Mail->format_datetime( $self->dt );
    $msg->replace( Date => $stamp );

    return $msg;

}

=head2 mail_admin( subject => 'report', data => 'some data' )

Simple method to email reports etc to admin.  Required "contact"
section to be configured in config file.  If it's an urgent message, the pager
param should be set to 1.

=cut

sub mail_admin {

    my $self = shift;

    my %rules = (
        data      => { type => SCALAR, },
        data_type => { type => SCALAR, optional => 1, default => 'txt' },
        pager   => { type => SCALAR, optional => 1 },
        subject => {
            type     => SCALAR,
            optional => 1,
            default  => $ENV{'SERVER_NAME'},
        },
    );

    my %args = validate( @_, \%rules );
    my $contact = $self->config->{'contact'};

    my $msg = MIME::Lite->new(
        From    => $contact->{'from'},
        To      => $contact->{'notify'},
        Subject => $args{'subject'},
        Type    => 'multipart/mixed',
    );

    my %type = (
        txt  => 'TEXT',
        html => 'text/html',
    );

    my $part = MIME::Lite->new(
        Type => $type{ $args{'data_type'} },
        Data => $args{'data'},
    );

    $msg->attach( $part );

    if (   exists $args{'pager'}
        && $args{'pager'}
        && exists $contact->{'pager'} )
    {
        $msg->add( Cc => $contact->{'pager'} );
    }

    return $self->send_msg( $msg );
}

sub _send_by_smtp {

    my $self = shift;
    my $msg  = shift;
    my $conf = $self->smtp_conf;

    return 0 if !$conf || !$conf->{'enabled'};

    $msg->send_by_smtp( $conf->{'server'}, %{ $conf->{args} } );
    return $msg->last_send_successful;

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
