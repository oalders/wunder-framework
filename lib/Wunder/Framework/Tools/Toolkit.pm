package Wunder::Framework::Tools::Toolkit;

use strict;
use warnings;
use Modern::Perl;

use vars qw( @EXPORT_OK );

use Exporter 'import';
use Scalar::Util qw( reftype );

@EXPORT_OK = qw(
    comma_split     commify             converter
    capitalize      dt_pad              forcearray
    get_dt          moneypad            percent
    random_token    round               suggest_password
    suggest_passwd  zeropad             commapad
);

=head1 SYNOPSIS

All of those handy tools that I use all the time.  No need to
make an OO module for this stuff.

=cut

use DateTime;
use Params::Validate qw( validate SCALAR );
use String::Random;

=head2 dt_pad( @list )

Pads digits less than zero so that they are valid in MySQL datetime
fields etc

=cut

sub dt_pad {

    my @digits = @_;
    foreach ( @digits ) {
        if ( $_ < 10 && length($_) == 1 ) {
            $_ = '0' . $_;
        }
    }

    if ( scalar @digits == 1 ) {
        return shift @digits;
    }

    return @digits;

}

=head2 zeropad( number => $number, limit => $upper_limit )

Returns a nicely zeropadded number for creating invoice numbers etc.

=cut

sub zeropad {

    my %rules = (
        number  => { type => SCALAR, },
        limit   => { optional => 1, default => 2, type => SCALAR, }
    );

    my %args = validate( @_, \%rules );
    my $number = $args{'number'};

    my $padding = $args{'limit'} - length( $number );
    if ( $padding > 0 ) {
        $number = "0"x$padding . $number;
    }

    return $number;

}

=head2 get_dt

Return an initialized DateTime object, set to the present time.

=cut

sub get_dt {

    my %rules = (
        epoch => { optional => 1, type => SCALAR, },
    );

    my %args = validate( @_, \%rules );

    my $dt = undef;

    if ( $args{'epoch'} ) {
        $dt = DateTime->from_epoch( epoch => $args{'epoch'} );
    }
    else {
        $dt = DateTime->now;
    }

    $dt->set_time_zone('America/Chicago');
    return $dt;

}

=head2 moneypad( $number, $currency )

Pads out floats and integers to two decimal places, if necessary.
Usually meant for getting prices to look pretty.  Will round the
number first if it goes beyond 2 decimal places.

Accepts an optional second argument (currency)

=cut

sub moneypad {

    my $number      = shift;
    my $currency    = shift;

    if ( $currency && $currency eq 'JPY' ) {
        return round( $number, 0 );
    }

    return sprintf( "%.2f", round( $number ) );

}

=head2 commapad

Calls moneypad and then commifies the return value.  You may not
always want commas in moneypad numbers -- especially if you still
need to perform calculations with those numbers.  The sums returned
by this function are purely for display purposes

=cut

sub commapad {

    return commify( moneypad( @_ ) );

}


=head2 round( $number, $decimal_places )

Round numbers to 2 decimal places unless otherwise specified

=cut

sub round {

    my ($n, $p) = @_;
    no warnings; ## no critic
    unless ( $p =~ /[0-9]/) { $p = 2 }
    use warnings;
    $n = 1 if !$n;
    my $add = $n < 0 ? -.5 : .5;
    return int($n * 10**$p + $add) / 10**$p;

}

=head2 capitalize

Capitalize the first letter of each word (and lowercase
all the rest).

=cut

sub capitalize {

    # capitalizes individual words
    my @data = @_;

    foreach ( @data ) {
        $_ =~ s/--/ /g;
        $_ =~ tr/[A-Z]/[a-z]/;
        $_ =~ s/\b(\w)/\u\L$1/g;
    }

    if ( scalar @data == 1 ) {
        return shift @data;
    }

    return @data;
}

=head2 commify

Add commas in just the right places.

=cut

sub commify {

    local $_ = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $_;

}

=head2 suggest_password

Returns a randomish password that can be assigned to a user.

=cut

sub suggest_password {

    my $foo = String::Random->new();
    my $password = $foo->randregex('\w\w\d\d\w\w\w\d\w\w\d'); # Prints 3 random digits
    $password =~ s/[^0-9a-zA-Z]//g;

    return $password;

}

=head2 suggest_passwd

Convenience method for suggest_password

=cut

sub suggest_passwd {

    return suggest_password( @_ );

}

=head2 converter

Provides an object to convert to UTF-8

=cut

sub converter {
    require Text::Iconv;

    my $converter   = Text::Iconv->new( "ISO8859-1", "utf-8" );
    return $converter;
}

=head2 forcearray

For use with config files.  One item lists are usually convereted to scalars
rather than arrays.  This helps when you're expecting a one-item list rather
than a scalar

=cut

sub forcearray {

    my $ref = shift;

    if ( ! reftype $ref ) {
        return $ref;
    }
    elsif ( reftype $ref eq 'SCALAR' ) {
        return ${ $ref };
    }
    elsif ( reftype $ref eq 'ARRAY' ) {
        return @{ $ref };
    }


    return;

}

=head2 comma_split( $data )

Extract custom key/value pairs from POSTed data

=cut

sub comma_split {

    # the only way to get key/value pairs via PayPal IPN is to stuff them
    # into one param

    my %custom  = ( );
    my @pairs   = split /,/, shift;
    foreach my $pair ( @pairs ) {
        my ( $name, $value ) = split /=/, $pair;
        $custom{ $name } = $value;
    }

    return \%custom;

}

=head2 percent( $dividend, $divisor )

Returns % formatted number.

=cut

sub percent {

    my $dividend = shift || 0;
    my $divisor  = shift || 0;

    # avoid division by zero errors
    return 0 unless $divisor > 0;

    $dividend = ( $dividend / $divisor ) * 10000;
    $dividend = int( $dividend );
    $dividend = $dividend / 100;

    return $dividend;

}


=head2 random_token( $length )

Return a string of length $length made of of random characters.  Useful for
obscuring URLs, creating tokens etc

=cut

sub random_token {

    my $length  = shift || 6;

    my @avail   = ( 'A' .. 'Z', 'a' ..  'z', 0 .. 9 );
    my $hash    = undef;

    foreach ( 1 .. $length ) {
       my $rand = int(rand(61));
       $hash .= $avail[ $rand ];
    }

    return $hash;

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
