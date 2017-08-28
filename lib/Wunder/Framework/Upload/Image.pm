package Wunder::Framework::Upload::Image;

use Moose;

with 'Wunder::Framework::WF';
with 'Wunder::Framework::Roles::Upload';

use vars qw( @EXPORT_OK );

use CGI;
use Data::Dump qw( dump );
use Exporter 'import';
use File::Path;
use File::Spec;
use Graphics::Magick;
use Image::ExifTool qw(:Public);
use Image::Size;
use List::Util qw( any );
use Params::Validate qw( SCALAR SCALARREF validate validate_pos );
use Scalar::Util qw( openhandle );

@EXPORT_OK = qw(
    make_path        process_image   resize
    resize_ok           store           upload
    upload_and_resize   update_image
);

=head1 SYNOPSIS

Some generic image processing stuff.  Things that I always forget how to do,
because I do them so rarely.  The CPAN modules I've looked at for handling
them seem to be buggy, so in this case doing my own thing saves me some
tears.

Make sure your open form tag uses the following: enctype="multipart/form-data"

To use this module for image processing from some form other than a CGI, you
may do the following:

    use Wunder::Framework::Upload::Image qw( resize store );

    my $image_ref   = resize(
        file        => /path/to/image,
        image       => \$image_reference,
        max_height  => 600,
        max_width   => 800,
    );

    my $row = store(
        base_path   => $self->path,
        image       => $image_ref,
        rel_path    => $presets->{'rel_path'},
        schema      => $self->schema,
    );


=cut

=head2 upload_and_resize( %params )

Uses Image::Magick, which is more powerful than GD.  Uses Resize method, which
is like the Scale method, but it allows you to define filter and blur.

=cut

sub upload_and_resize {

    my $self  = shift;
    my %rules = (
        field      => { type => SCALAR, },
        max_width  => { type => SCALAR, },
        max_height => { type => SCALAR },
        query      => { isa  => 'CGI', optional => 1, default => CGI->new },
    );

    my %args = validate( @_, \%rules );

    my $field = $args{'field'};
    my $q     = $args{'query'};

    my $image_ref = $self->upload(
        field => $args{'field'},
        query => $q,
    );

    return $self->resize(
        file       => $q->tmpFileName( $q->param( $field ) ),
        image      => $image_ref,
        max_height => $args{'max_width'},
        max_width  => $args{'max_height'},
    );

}

=head2 resize_ok

Returns true if the supplied image exceeds the maximum height or width.

=cut

sub resize_ok {

    my $self = shift;

    my %rules = (
        image      => { type => SCALARREF },
        max_width  => { type => SCALAR, },
        max_height => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );

    my ( $x, $y ) = imgsize( $args{'image'} );

    return 0 if $x < $args{'max_width'} && $y < $args{'max_height'};
    return { x => $x, y => $y };

}

=head2 resize

Resize the image using Graphics::Magick.  Retains the original aspect ratio.
Requires a location of the file on disk.  Returns a reference to the actual
image.

=cut

sub resize {

    my $self = shift;

    my %rules = (
        file       => { type => SCALAR },
        image      => { type => SCALARREF },
        max_height => { type => SCALAR },
        max_width  => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );

    my $file      = $args{'file'};
    my $image_ref = $args{'image'};

    my $resize = $self->resize_ok(
        image      => $image_ref,
        max_width  => $args{'max_width'},
        max_height => $args{'max_height'},
    );

    # even if files don't need to be resized, correct colour profiles to RGB
    my $magick = $self->correct_colorspace( $file );

    if ( !$resize ) {
        my $blob = $magick->ImageToBlob();
        return \$blob;
    }

    my $x = $resize->{'x'};
    my $y = $resize->{'y'};

    # these calculations swiped from Image::Resize
    my $k_h    = $args{'max_height'} / $y;
    my $k_w    = $args{'max_width'} / $x;
    my $k      = ( $k_h < $k_w ? $k_h : $k_w );
    my $height = int( $y * $k );
    my $width  = int( $x * $k );

    $magick->Set( quality => 100 );
    my $status = $magick->Resize( width => $width, height => $height );
    warn $status if $status;

    my $blob = $magick->ImageToBlob();
    return \$blob;

}

=head2 update_image

Update image data without changing the file path

=cut

sub update_image {

    my $self = shift;

    my %rules = (
        base_path => { type => SCALAR },
        image     => { type => SCALARREF },
        row       => { isa  => 'DBIx::Class' },
    );

    my %args  = validate( @_, \%rules );
    my $image = $args{'image'};
    my $row   = $args{'row'};

    my ( $x, $y ) = imgsize( $args{'image'} );
    $row->width( $x );
    $row->height( $y );
    $row->file( $$image );
    $row->update;

    my $full_path = "$args{'base_path'}/web" . $row->path;
    my $fh        = IO::File->new( "> $full_path" );
    if ( defined $fh ) {
        print $fh $$image;
        $fh->close;
    }

    return $row;

}

=head2 correct_colorspace( $filename )

In the case of .png and .jpg convert CMYK profiles to RGB.  This gets around
a bug in Chrome and MSIE where jpegs with CMYK colour profiles are not
rendered by the browser.

$image->Quantize(colorspace=>'gray');

=cut

sub correct_colorspace {

    my $self = shift;

    my @args = validate_pos( @_, { type => SCALAR } );

    my $file = shift @args;
    my $tool = Image::ExifTool->new;
    my $info = $tool->ImageInfo( $file );

    my $magick = Graphics::Magick->new;
    my $status = $magick->Read( $file );
    warn "problem reading file: $status" if $status;

    my @correctable = qw( image/png image/jpg image/pjpeg image/jpeg );

    if ( any { $_ eq $info->{'MIMEType'} } @correctable ) {

        $magick->Set( colorspace => 'RGB' );

    }

    return $magick;

}

=head2 store_image

Add the necessary image meta-data

=cut

sub store_image {

    my $self = shift;
    my $row  = $self->store( @_ );
    my %args = @_;

    my $info = ImageInfo( $args{base_path} . $row->path );
    $row->width( $info->{'ImageWidth'} );
    $row->height( $info->{'ImageHeight'} );
    $row->update;

    return $row;

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
