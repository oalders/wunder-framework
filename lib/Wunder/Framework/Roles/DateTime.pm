package Wunder::Framework::Roles::DateTime;

use Moose::Role;

#requires 'config';

use Data::Dump qw( dump );
use DateTime;
use DateTime::Format::MySQL;
use Devel::SimpleTrace;
use Modern::Perl;
use MooseX::Params::Validate;

=head1 SYNOPSIS

Contains a role which instantiates a DateTime object to the correct time zone.

=head2 dt( epoch => $epoch )

Returns a DateTime object, initialized to the correct time zone.

=head2 mysql_datetime( $dt )

Returns a MySQL formatted datetime string. If no $dt is provided, the
current time is returned.

=cut

has 'time_zone' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub dt {

    my $self = shift;

    my $epoch
        = validated_list( \@_, epoch => { optional => 1, type => 'Int' }, );
    my $dt = undef;

    if ( $epoch ) {
        $dt = DateTime->from_epoch( epoch => $epoch );
    }
    else {
        $dt = DateTime->now;
    }

    $dt->set_time_zone( $self->time_zone );

    return $dt;

}

sub mysql_datetime {
    my $self = shift;
    return DateTime::Format::MySQL->format_datetime( shift || $self->dt );
}

sub _build_time_zone {

    my $self = shift;
    return $self->config->{'time_zone'} || 'America/Chicago';

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
