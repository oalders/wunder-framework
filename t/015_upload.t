#!/usr/bin/perl

use Modern::Perl;
use Test::More tests => 10;

require_ok('Wunder::Framework::Upload::Image');
my $image = Wunder::Framework::Upload::Image->new;

isa_ok( $image, 'Wunder::Framework::Upload::Image' );

my %extension = (
    'headshot.jpg'  => 'c/4/c/1.jpg',
    'image/jpeg'    => 'c/4/c/1.jpg',
    'image/pjpeg'   => 'c/4/c/1.jpg',
    'dude.gif'      => 'c/4/c/1.gif',
);

foreach my $extension ( keys %extension ) {
    
    my $loc = $image->make_path(
        id          => 1,
        base_path   => '/tmp',
        extension   => $extension,
    );
    
    ok( $loc, "got a file location" );
    
    cmp_ok(
        $loc, 'eq', $extension{ $extension },
        "got correct file name + path for $extension"
    );
    #diag( $loc );

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

