package Wunder::Framework::Image;

use Moose;

use Modern::Perl;
use Params::Validate qw( SCALAR SCALARREF validate validate_pos );
use Perl6::Junction qw( any );
use Image::ExifTool;

with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::Log';

=head1 SYNOPSIS

This module is meant for handling images which will be viewed by browsers and
email clients.  An image file path is required to get things started.  The
info() method returns information about the *original* file.  Once the image
has been altered you will either need to inspect it yourself, or write it to
disk and create a new Wunder::Framework::Image object to get the relevant
information.

Once processing is complete, $img->magick returns a Graphics::Magick object to
you, which you may use to write files etc.

$img->magick->Write("filename.png")

=head2 file

Full path to the image file

=head2 info

Returns results of Image::ExifTool->ImageInfo, which is a HASHREF

=head2 magick

Returns a Graphics::Magick object.

=cut

has 'file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'info' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has 'magick' => (
    is         => 'rw',
    isa        => 'Graphics::Magick',
    lazy_build => 1,
);

has 'max_width' => ( is => 'rw', isa => 'Int', );

has 'max_height' => ( is => 'rw', isa => 'Int', );

sub _build_info {
    my $self = shift;
    my $tool = Image::ExifTool->new;
    return $tool->ImageInfo( $self->file );
}

sub _build_magick {
    my $self   = shift;
    require Graphics::Magick;
    my $magick = Graphics::Magick->new;
    my $status = $magick->Read( $self->file );
    die "problem reading file: $status" if $status;
    return $magick;
}

=head2 correct_colorspace( $filename )

In the case of .png and .jpg convert CMYK profiles to RGB.  This gets around
a bug in Chrome and MSIE where jpegs with CMYK colour profiles are not
rendered by the browser.

$image->Quantize(colorspace=>'gray');

=cut

sub correct_colorspace {

    my $self   = shift;
    my $magick = $self->magick;

    my @correctable = qw( image/png image/jpg image/pjpeg image/jpeg );

    if ( any( @correctable ) eq $self->info->{'MIMEType'} ) {

        $magick->Set( colorspace => 'RGB' );

    }

    return;

}

=head2 resize_ok

Returns true if the supplied image exceeds the maximum height or width.

=cut

sub resize_ok {

    my $self = shift;
    my $info = $self->info;

    if ( $self->max_width && $info->{ImageWidth} > $self->max_width ) {
        return 1;
    }

    if ( $self->max_height && $info->{ImageHeight} > $self->max_width ) {
        return 1;
    }

    return 0;

}

=head2 resize

Resize the image using Graphics::Magick.  Retains the original aspect ratio.
Requires a location of the file on disk.  Returns a reference to the actual
image.

=cut

sub resize {

    my $self   = shift;
    my $resize = $self->resize_ok;

    return 0 if ( !$resize );

    my $x = $self->info->{ImageWidth};
    my $y = $self->info->{ImageHeight};

    # these calculations swiped from Image::Resize
    my $k_h    = ( $self->max_height / $y ) || 1;
    my $k_w    = ( $self->max_width / $x ) || 1;
    my $k      = ( $k_h < $k_w ? $k_h : $k_w );
    my $height = int( $y * $k );
    my $width  = int( $x * $k );

    $self->magick->Set( quality => 100 );

    $self->logger("width => $width, height => $height");
    my $status = $self->magick->Resize( width => $width, height => $height );
    die $status if $status;

    return 1;

}

=head2 process

Apply all of the processing routines to on image

=cut

sub process {

    my $self = shift;
    $self->correct_colorspace;
    $self->resize;

    return 1;
}

1;
