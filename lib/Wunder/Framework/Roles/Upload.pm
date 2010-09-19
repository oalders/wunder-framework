package Wunder::Framework::Roles::Upload;

use Moose::Role;

use Digest::MD5 qw/md5_hex/;
use File::Copy;
use File::MimeInfo::Magic;
use Params::Validate qw( SCALAR SCALARREF validate validate_pos );
use Path::Class;
use Perl6::Junction qw( any );

=head2 make_path( $params )

Create a filename and path for the image.  The image name and path is based on
the md5 hash of some artibrary data.  Most of this is lifted directly from
CGI::Uploader

=cut

sub make_path {

    my $self = shift;

    my %rules = (
        id        => { type => SCALAR, },
        base_path => { type => SCALAR, },
        extension => { type => SCALAR, },
    );

    my %args = validate( @_, \%rules );

    my $id        = $args{'id'};
    my $base_path = $args{'base_path'};
    my $extension = $args{'extension'};

    # if the user has given a full file name or even a mime type, that's ok.
    # we can extract the extension from that
    if ( $extension =~ m{(?:\.|/)([\w\d]*)\z} ) {
        $extension = $1;
    }

    if ( any( 'jpeg', 'pjpeg' ) eq $extension ) {
        $extension = 'jpg';
    }

    my $md5_path = md5_hex( $id );
    $md5_path =~ s|^(.)(.)(.).*|$1/$2/$3|;

    my $full_path = $base_path . '/' . $md5_path;
    unless ( -e $full_path ) {
        File::Path::make_path( $full_path );
    }

    return File::Spec->catdir( $md5_path, $id . '.' . $extension );

}

=head2 upload

Handle only the CGI upload of the image.  It's trivial, but the syntax is
never something I remember anyway.  Returns a reference to the image.

=cut

sub upload {

    my $self = shift;

    my %rules = (
        field => { type => SCALAR, },
        query => { isa  => 'CGI', optional => 1, default => CGI->new },
    );

    my %args = validate( @_, \%rules );

    my $field = $args{'field'};
    my $q     = $args{'query'};

    my $fh = $q->upload( $field );

    if ( !defined $fh ) {
        warn "no file uploaded for field $field" if !$fh;
        return;
    }

    my $image = '';
    while ( <$fh> ) {
        $image .= $_;
    }

    return \$image

}

=head2 store

Takes a SCALARREF to an image and stores it on disk as well as in a MySQL table.
Returns the DBIx::Class row in which the image has been stored.

You'll need a table which has the following columns:

CREATE TABLE `upload` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `file` mediumblob,
  `width` int(4) default NULL,
  `height` int(4) default NULL,
  `path` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
);

For example:

my $row = store(
    base_path   => $self->path,
    image       => \$image,
    rel_path    => 'usr/upload/img'
    resultset   => $self->schema->resultset('MyApp::Schema::Upload'),
);

=cut

sub store {

    my $self = shift;

    my %rules = (
        base_path => { type => SCALAR, },
        file      => { type => SCALAR, },
        rel_path  => { type => SCALAR, },
        resultset => { isa  => 'DBIx::Class', },
    );

    my %args = validate( @_, \%rules );

    my $base_path = $args{'base_path'};
    my $file      = $args{'file'};
    my $rel_path  = $args{'rel_path'};
    my $rs        = $args{'resultset'};

    # pass one undef value in order to get past the following bug:
    # INSERT INTO image DEFAULT VALUES
    my $row = $rs->new( { file => undef } )->insert;
    $base_path = $base_path . '/' . $rel_path;

    # all we really need is something with a correct extension. the mime type
    # can get us to the right place
    my $mime_type = File::MimeInfo::Magic::magic( $file );
    $mime_type =~ s{/}{.}gxms;

    my $location = $self->make_path(
        id        => $row->id,
        base_path => $base_path,
        extension => $mime_type,
    );

    my $full_path = "$base_path/$location";

    copy( $file, $full_path ) or die "Copy failed: $!";
    my $file_obj = Path::Class::File->new( $full_path );

    # TODO slurp file in for db insert
    $row->file( $file_obj->slurp );
    $row->path( "/$rel_path/$location" );

    $row->update;
    return $row;

}

1;
