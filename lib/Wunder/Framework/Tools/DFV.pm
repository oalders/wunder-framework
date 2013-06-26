package Wunder::Framework::Tools::DFV;

use strict;
use warnings;
use Modern::Perl;

use vars qw( @EXPORT_OK );

use Data::Validate::URI qw(is_web_uri);
use Exporter 'import';
use Net::Twitter;

@EXPORT_OK = qw(
    validate_email  validate_url validate_date validate_twitter_credentials
);

use Email::Valid;

=head1 SYNOPSIS

This module is intended as a collection of helpful little methods used in
validating data.  It is not restricted to use with Data::FormValidator, but
that is its primary use case.

Export the methods you'll be using:

use Wunder::Framework::Tools::DFV qw( validate_email validate_url );

Then make use of these methods when you set up your DFV profile:

    constraint_methods => {
        email   => sub { return validate_email( @_ ) },
        website => sub { return validate_url( @_ ) },
    },

=cut

##############################################################################
#
# Data::FormValidator methods
#
##############################################################################

=head2 validate_email

Generic email validation

=cut

sub validate_email {

    my $email = pop;
    my $result
        = Email::Valid->address( -address => $email, -mxcheck => 1 )
        ? 'yes'
        : 'no';
    if ( $result eq 'yes' ) {
        return $email;
    }

    return;

}

=head2 validate_url

Generic URL validation

=cut

sub validate_url {

    my ( $dfv, $url ) = @_;

    return is_web_uri( $url );

}

=head2 validate_date

Validate dates to YYYY-MM-DD

=cut

sub validate_date {

    my $date = pop;
    if ( $date =~ m{\A\d\d\d\d-\d\d-\d\d\z} ) {
        return $date;
    }
    return;

}

=head2 validate_twitter_credentials

Returns true if supplied username *and* password are correct.

=cut

sub validate_twitter_credentials {

    my ( $dfv, $val ) = @_;
    $dfv->name_this( 'twitter_credentials' );
    my $data = $dfv->get_input_data( as_hashref => 1 );

    my $nt = Net::Twitter->new(
        traits   => [qw/API::REST InflateObjects WrapError/],
        username => $data->{'twitter_u'},
        password => $data->{'twitter_p'},
    );

    return $val if ( $nt->verify_credentials );
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
