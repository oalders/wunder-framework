#!/usr/bin/perl

use Data::Dump qw( dump );
use Find::Lib;
use Modern::Perl;
use Test::More qw( no_plan ); 

require_ok('Wunder::Framework::Image');

my $img = Wunder::Framework::Image->new(
    file => Find::Lib->base . '/resources/logo.png'
);

ok( $img, "got an image obj" );
ok ( $img->info, "got info" );

#diag( dump($img->info) );

$img->max_width(10);
$img->max_height(10);

ok( $img->process, "could process image" );

my $tmp = Find::Lib->base . '/resources/tmp_logo.png';

unlink( $tmp );

$img->magick->Write( $tmp );

ok ( -e $tmp, "image has been written" ); 

my $tmp_img = Wunder::Framework::Image->new(
    file => $tmp
);

ok( $tmp_img, "got obj for tmp image" );
my $info = $tmp_img->info;

ok($info->{ImageWidth}, "got width: " . $info->{ImageWidth} );
ok($info->{ImageHeight}, "got height: " . $info->{ImageHeight} );

cmp_ok( $info->{ImageWidth}, '<=', $img->max_width, "width is allowable" ); 
cmp_ok( $info->{ImageHeight}, '<=', $img->max_height, "height is allowable" ); 
