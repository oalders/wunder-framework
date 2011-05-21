package Wunder::Framework::Tools::FormBuilder;

use Moose;

with 'Wunder::Framework::WF';

=head1 SYNOPSIS

Easy, simple, customizable form building.

=cut

use Wunder::Framework::Tools::Toolkit qw( converter dt_pad get_dt zeropad );

use Carp;
use CGI;
use Data::Dump qw( dump );
use Encode;
use Locale::SubCountry;
use Modern::Perl;
use Params::Validate qw( validate validate_pos SCALAR ARRAYREF HASHREF );
use Perl6::Junction qw( any );
use Scalar::Util qw( reftype );
use Text::Autoformat;

my %units_of = (
    datetime  => ['year', 'month', 'day', 'hour', 'minute', 'second'],
    date      => ['year', 'month', 'day'],
    time      => ['hour', 'minute', 'second'],
    timestamp => ['year', 'month', 'day', 'hour', 'minute', 'second'],
);

my %menu_rules = (
    name        => { type => SCALAR },
    readonly    => { type => SCALAR, optional => 1, default => undef },
);

=head2 verbose( 0|1 )

Enable verbose debugging output

=cut

has 'verbose' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

=head2 new()

Create the new object;

=cut

sub new {

    my $class = shift;
    my $self = {};
    bless($self,$class);

    return $self;

}

=head2 describe

Use MySQL to describe table features

=cut

sub describe {

    my $self = shift;

    my %rules = (
        dbh         => { isa => 'DBI::db' },
        return_as   => { type => SCALAR, optional => 1, default => 'ARRAYREF' },
        table       => { type => SCALAR },
    );

    my %return = ( );
    my %args = validate( @_, \%rules );
    my @table = ( );

    my $sth = $args{'dbh'}->prepare( " DESCRIBE `$args{'table'}` " );
    $sth->execute();

    while ( my $col = $sth->fetchrow_hashref ) {

        my %row = ();

        foreach my $key ( keys %{$col} ) {

            my $name = lc $key;
            $row{$name} = $col->{$key};

            if ( $row{'type'} && $row{'type'} =~ m{enum \( (.*?) \) }xms ) {

                my $enum = $1;
                $enum =~ s{'}{}gxms;
                my @enum = sort split ",", $enum;

                if ( exists $row{'null'} && $row{'null'} eq 'YES' ) {
                    unshift @enum, "";
                }

                $row{'enum'} = \@enum;
            }

        }

        if ( $args{'return_as'} eq 'HASHREF' ) {
            $return{$row{'field'}} = \%row;
        }

        push @table, \%row;
    }

    return \%return if $args{'return_as'} eq 'HASHREF';
    return \@table;

}

=head2 get_column_names

Returns an ARRAYREF of table column names, keeping the table order intact.

=cut

sub get_column_names {

    my $self = shift;

    my %rules = (
        dbh         => { isa => 'DBI::db' },
        table       => { type => SCALAR },
    );

    my %args    = validate( @_, \%rules );
    my $cols    = $self->describe( @_ );
    my @names   = ( );

    foreach my $col ( @{$cols} ) {
        push @names, $col->{'field'};
    }

    return \@names;

}


=head2 build_form( table => 'my_table', size => $integer )

Return an ARRAYREF that HTML::Template can turn into a form

=cut

sub build_form {

    my $self = shift;
    my $q = CGI->new();

    # don't want CGI params to override form defaults
    # we use FillInForm for that.  If we want CGI
    # defaults we can pass a CGI object to FillInForm
    $q->delete_all;

    my %rules = (
        dbh             => { isa => 'DBI::db' },
        dwiw            => { optional => 1, default => 0 },
        dfv_errs        => { optional => 1, type => HASHREF,  },
        hidden          => { optional => 1, type => ARRAYREF, },
        ignore          => { optional => 1, type => ARRAYREF, },
        names           => { optional => 1, type => HASHREF,  },
        override        => { optional => 1, type => HASHREF,  },
        password        => { optional => 1, type => ARRAYREF, default => [ ] },
        push_hidden     => { optional => 1, type => ARRAYREF, },
        preserve_case   => { optional => 1, default => 1 },
        readonly        => { optional => 1, type => ARRAYREF, },
        reftype         => { optional => 1, default => 'ARRAY', },
        showonly        => { optional => 1, type => ARRAYREF, },
        size            => { optional => 1, default => 30 },
        table           => { type => SCALAR, },
    );

    my %args = validate( @_, \%rules );
    my $table = $self->describe( dbh => $args{'dbh'}, table => $args{'table'} );

    my @elements    = ( );
    my %elements    = ( );

    my $hidden      = $self->array_to_hash( $args{'hidden'} );
    my $ignore      = $self->array_to_hash( $args{'ignore'} );
    my $names       = $args{'names'};
    my $override    = $args{'override'};
    my @password    = @{ $args{'password'} };
    my $readonly    = $self->array_to_hash( $args{'readonly'} );
    my $showonly    = $self->array_to_hash( $args{'showonly'} );

    foreach my $field_name ( @{$args{'push_hidden'} } ) {
        unshift @{$table}, { field => $field_name };
        $hidden->{$field_name} = 1;
    }

    foreach my $col ( @{$table} ) {

        my $element = undef;
        my $name = $col->{'field'};
        $name =~ tr/[A-Z]/[a-z]/ if !$args{'preserve_case'};

        next if exists $ignore->{$name};

        # hidden fields will always be allowed, even if visible fields are restricted
        next if ( $args{'showonly'} && !exists $showonly->{$name} && !exists $hidden->{$name} );

        my $disable = 0;
        $disable    = 1 if (exists $readonly->{$name} );

        if ( exists $override->{$name} ) {
            $element = $override->{$name};
        }

        elsif ( $col->{'key'} eq 'PRI' || exists $hidden->{$name} ) {

            $element = $q->hidden(
                -name => $name,
            );

            # needs to be set if it's a PRIMARY KEY
            $hidden->{$name} = 1;
        }

        elsif ( $col->{'type'} =~ m{(?: \A int|char|varchar ) \( (\d+) \) }xms ) {

            if ( $disable ) {

                $element = $q->textfield(
                    -name => $name,
                    -size => $args{'size'},
                    -maxlength => $1,
                    -disabled => 1,
                );
            }

            elsif ( any ( @password ) eq $name ) {

                $element = $q->password_field(
                    -name => $name,
                    -size => $args{'size'},
                    -maxlength => $1,
                );

            }

            else {

                if ( $args{'dwiw'} && $name eq 'country' ) {
                    $element = $self->country_menu({
                        name        => $name,
                        id          => $name,
                        onchange    => 'update_region()',
                        default     => $self->get_user_country,
                    });
                }
                elsif ( $args{'dwiw'} && $name eq 'region' ) {
                    $element =  $self->region_menu( $self->get_user_country, {
                        name    => $name,
                        id      => $name,
                    });
                }
                elsif ( $args{'dwiw'} && any ('expiration_month', 'expiration_year') eq $name ) {
                    $element =  $self->$name;
                }                
                else {
                    $element = $q->textfield(
                        -name => $name,
                        -size => $args{'size'},
                        -maxlength => $1,
                    );
                }
            }
        }

        # this is a boolean field
        elsif ( $col->{'type'} eq 'tinyint(1)' || $col->{'type'} eq 'binary(1)' ) {

            my @values = ( 0, 1 );
            my %labels = ( 0 => 'No', 1 => 'Yes' );

            if ( exists $col->{'null'} && $col->{'null'} eq 'YES' ) {
                unshift @values, '';
            }

            $element = $q->popup_menu(
                -name => $name,
                -values => \@values,
                -labels => \%labels,
            );
        }

        elsif ( $col->{'type'} =~ m{enum \( (.*?) \) }xms ) {
            my $enum = $1;
            $enum =~ s{'}{}gxms;
            my @enum = split ",", $enum;

            if ( $col->{'null'} eq 'YES' ) {
                unshift @enum, "";
            }

            $element = $q->popup_menu(
                -name => $name,
                -values => \@enum,
            );

        }

        elsif ( $col->{'type'} =~ m{float \( (\d+),(\d+) ? \) }xms ) {

            # leave room for the decimal point
            my $size = $1 + 1;

            if ( $disable ) {

                $element = $q->textfield(
                    -name => $name,
                    -size => $size,
                    -maxlength => $size,
                    -disabled => 1,
                    -id       => $name,
                );
            }

            else {

                $element = $q->textfield(
                    -name => $name,
                    -size => $size,
                    -maxlength => $size,
                    -id       => $name,
                );

            }
        }

        elsif ( $col->{'type'} eq 'mediumtext' || $col->{'type'} eq 'text') {

            $element = $q->textarea(
                -name       => $name,
                -rows       => 10,
                -columns    => $args{'size'},
                -id         => $name,
            );

        }

        elsif ( $col->{'type'} =~ m{\A(blob|tinyblob|mediumblob|longblob)\z}) {

            $element = $q->filefield(
                -name       => $name,
                -id         => $name,
            );

        }

        elsif ( $col->{'type'} eq 'date' ) {

            $element = $self->get_date_menu( name => $name, readonly => $disable  );

        }

        elsif ( any ('datetime', 'timestamp') eq $col->{'type'} ) {

            $element  = $self->get_date_menu( name => $name, readonly => $disable );
            $element .= ' ' . $self->get_timestamp_menu( name => $name, readonly => $disable );

        }

        elsif ( $col->{'type'} eq 'time' ) {

            $element = $self->get_timestamp_menu( name => $name, readonly => $disable );

        }

        my $is_hidden = 0;
        $is_hidden = 1 if exists $hidden->{$name};
        my $col_name = $name;

        if ( exists $names->{$name} ) {
            $name = $names->{$name};
        }
        else {
            $name = $col->{'field'};
            $name =~ s{_}{ }gxms;
            $name =~ s{([a-z])([A-Z])}{$1 $2}gxms; # CamelCase -> Camel Case
            $name = autoformat $name, { case => 'title' };
            $name =~ s{\n}{}gxms;
        }

        my $dfv_error = undef;
        my $dfv_col = 'err_' . $col_name;
        if ( $args{'dfv_errs'} && exists $args{'dfv_errs'}->{ $dfv_col } ) {
            $dfv_error = $args{'dfv_errs'}->{ $dfv_col };
        }

        push @elements, {
            column_name => $col_name,
            dfv_error   => $dfv_error,
            element     => $element,
            name        => $name,
            hidden      => $is_hidden,
        };

        $elements{$col->{'field'}} = $element if $element;

    }

    if ( $args{'reftype'} eq 'ARRAY' ) {
        return \@elements;
    }
    else {
        return \%elements;
    }

}

=head2 array_to_hash( \@array )

Convert an ARRAYREF to a HASHREF

=cut

sub array_to_hash {

    my $self = shift;
    my $array = shift;

    my $hashref = { };

    # it's ok to create an empty HASHREF
    return $hashref unless $array;

    foreach my $element ( @{$array} ) {
        $hashref->{$element} = 1;
    }

    return $hashref;

}

=head2 country_codes

Returns a list of country codes sorted alphabetically by country *name*

=cut

sub country_codes {

    my $self = shift;
    my $world = Locale::SubCountry::World->new();
    my %all_country_keyed_by_code = $world->code_full_name_hash;

    my @codes = sort { $all_country_keyed_by_code{$a} cmp $all_country_keyed_by_code{$b} } keys %all_country_keyed_by_code;

    return \@codes;

}

=head2 country_menu( $params )

Returns a list of country codes.  $args is a HASHREF of valid arguments which
can be passed directly to the CGI object.

The exception is the "nullable" param, which should be passed when you don't
want the menu to default to any specific country.

=cut

sub country_menu {

    my $self    = shift;

    my %args    = ( );
    my %rules   = (
        id     => { type => SCALAR, optional => 1, default => 'country_code' },
        name   => { type => SCALAR, optional => 1, default => 'country_code' },
        onchange    => { type => SCALAR, optional => 1 },
        default     => { type => SCALAR, optional => 1 },
        labels      => { type => SCALAR, optional => 1 },
        nullable    => { type => SCALAR, optional => 1 },
        values      => { type => SCALAR, optional => 1 },
        disabled    => { type => SCALAR, optional => 1 },
    );

    # do this to keep from breaking API
    my $country = shift;

    # all args are optional, so we can handle them this way
    # if we don't we get the following error:
    # Can't use an undefined value as a HASH reference

    my $arg_ref = shift;
    if ( !$arg_ref && reftype( $country ) eq 'HASH' ) {
        $arg_ref = $country;
    }
    if ( $arg_ref ) {
        my @args = %{ $arg_ref };
        %args    = validate( @args, \%rules );
    }

    my $world       = Locale::SubCountry::World->new();
    my %all_country_keyed_by_code = $world->code_full_name_hash;

    my @codes = @{ $self->country_codes() };

    if ( exists $args{'nullable'} ) {
        if ( $args{'nullable'} ) {
            unshift @codes, "";
        }
        delete $args{'nullable'};
    }

    my $q = CGI->new;

    return encode("utf8", $q->popup_menu(
        -values => \@codes,
        -labels => \%all_country_keyed_by_code,
        %args,
    ) );

}

=head2 get_user_country

Used when setting the default country for a dropdown (like in a signup form).
If the form has already been submitted, we'll go with the user's submitted
country.  If not, we'll look up the IP number and see if we get something
useful.  When in doubt, default to the US

=cut

sub get_user_country {

    my $self    = shift;
    my $q       = CGI->new;
    my $country = $q->param('country');

    return $country if $country;
    
    my $record = $self->wf->best_geo->record_by_addr( $ENV{'REMOTE_ADDR'} );
    return $record->country_code if $record;
    
    if ( $self->verbose ) {
        warn "no country param provided / ip $ENV{'REMOTE_ADDR'} not located";        
    }

    return;

}

=head2 region_menu( $country_code )

Returns a SELECT list of region codes (states/provinces) based
on a supplied country code.

=cut

sub region_menu {

    my $self    = shift;
    my $q       = CGI->new;

    my @args = validate_pos(
        @_,
        { type => SCALAR,  optional => 1, default => $q->param('country') || undef },
        { type => HASHREF, optional => 1, default => {} }
    );

    my $country_code    = shift @args;
    my $args            = shift @args;

    if ( !$country_code ) {
        warn "no country code supplied to region menu";
        return;
    }


    my $entity  = Locale::SubCountry->new( $country_code );
    my %codes   = $entity->code_full_name_hash;

    # the empty list is kind of funky, so allow for that for "FK" and
    # other countries where we don't have a region list
    if ( scalar keys %codes == 1 && exists $codes{''} ) {

        return $q->textfield(
            -name       => 'region_code',
            -size       => 20,
            -maxlength  => 30,
            -id         =>  'region_code',
            %{$args},
        );

    }

    # some region names have info in brackets -- strip that out
    foreach my $code ( keys %codes ) {
        $codes{$code} =~ s{\(.*\)\Z}{};
    }

    my @codes = sort { $codes{$a} cmp $codes{$b} } keys %codes;
    $codes{''} = 'Select a State/Region';
    unshift @codes, '';

    return encode("utf8", $q->popup_menu(
            -name   =>  'region_code',
            -values =>  \@codes,
            -labels =>  \%codes,
            -id     =>  'region_code',
            %{$args},
        )
    );

}

=head2 ajax_region_menu

Use this in the context of an AJAX call.  Overrides some of the region_menu
defaults.

=cut

sub ajax_region_menu {

    my $self     = shift;
    my $q        = CGI->new;
    my $country  = $q->param('country');

    if ( !$country || length( $country ) != 2 ) {
        return "...";
    }

    my $name = $q->param('name') || 'region';
    $name =~ s{[^a-z_]}{}gxsm;

    my $menu = $self->region_menu( $q->param('country'),
        {
            id      => $name,
            name    => $name,
            default => $q->param( $name ),
        }
    );

    return $menu;

}

=head2 ajax_country_menu

Use this in the context of an AJAX call.  Overrides some of the country_menu
defaults.

=cut

sub ajax_country_menu {

    my $self = shift;
    my $q    = CGI->new;
    my $country = $self->get_user_country() || 'US';

    my $name = $q->param('name') || 'country';
    $name =~ s{[^a-z_]}{}gxsm;
    
    my $attr = {
        id          => $name,
        name        => $name,
        onchange    => 'update_region();',
        default     => $q->param( $name ) || $country,
    };

    my $menu = $self->country_menu( $country, $attr );
    
    #$self->wf->logger( "country: " . dump $attr );

    return $menu;

}


=head2 dt_attrs( dt => $dt, name => 'field_name|column_name' )

Returns a HASHREF of DateTime attributes that can be passed to FillInForm
to initialize a FormBuilder form.

=cut

sub dt_attrs {

    my $self = shift;
    my %rules = (
        dt => { isa => 'DateTime', optional => 1, default => get_dt() },
        name => { type => SCALAR, }
    );

    my %args = validate( @_, \%rules );
    my $dt  = $args{'dt'};
    my $name = $args{'name'};
    my $dt_attrs = { };

    my @methods = qw( year month day hour minute second );

    foreach my $method ( @methods ) {
        $dt_attrs->{ $name . '_' . $method } = dt_pad( $dt->$method );
    }

    return $dt_attrs;

}

=head2 row_from_cgi

Returns a HASHREF of CGI params that have been matched against
the column names of a table.

=cut

sub row_from_cgi {

    my $self = shift;
    my %rules = (
        cgi     => { isa => 'CGI', optional => 1, default => CGI->new },
        dbh     => { isa => 'DBI::db' },
        preserve_case => { optional => 1, default => 1 },
        table   => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );
    my $query = $args{'cgi'};

    my $describe = $self->describe( dbh => $args{'dbh'}, table => $args{'table'} );

    my %attrs = ( );

    foreach my $col_ref ( @{$describe} ) {
        my $name = $col_ref->{'field'};
        my $type = $col_ref->{'type'};

        $name =~ tr/[A-Z]/[a-z]/ if !$args{'preserve_case'};

        # if we check for definedness *first*, 0 values get missed and they're
        # important when updating tables
        no warnings; ## no critic
        if ( $query->param( $name ) =~ /[a-zA-Z0-9]/ ) {
        use warnings;
            $attrs{$name} = $query->param($name);
        }
        elsif ( $type eq 'datetime' ||
                $type eq 'date'     ||
                $type eq 'time' ) {

            my $update = 1;
            my %time = ( );

            my @units = @{ $units_of{$type} };

            foreach my $unit ( @units ) {
                # eg due_year
                my $param = $name . '_' . $unit;

                # if even one param is missing the query will
                # fail, so we'll ignore it
                if ( !$query->param( $param ) ) {
                    $update = 0;
                    last;
                }
                else {
                    $time{$unit} = $query->param( $param );
                }
            }
            if ( $update ) {
                my $date = join "-", $time{'year'}, $time{'month'}, $time{'day'};
                my $time = join ":", $time{'hour'}, $time{'minute'}, $time{'second'};

                if ( $type eq 'datetime' ) {
                    $attrs{$name} = $date . ' ' . $time;
                }
                elsif ( $type eq 'time' ) {
                    $attrs{$name} = $time;
                }
                elsif ( $type eq 'date' ) {
                    $attrs{$name} = $date;
                }
            }

        }
    }

    return \%attrs;
}

=head2 row_from_dbic

Returns a HASHREF of CGI params that have been matched against
the column names of a table and the values from a DBIC object.

=cut

sub row_from_dbic {

    my $self = shift;
    my %rules = (
        dbic    => { isa => 'DBIx::Class' },
        dbh     => { isa => 'DBI::db', optional => 1 }, # deprecated
        table   => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );
    my $dbic = $args{'dbic'};

    my $describe = $self->describe(
        dbh     => $dbic->storage->dbh,
        table   => $args{'table'}
    );

    my %attrs = $dbic->get_columns;

    foreach my $col_ref ( @{$describe} ) {

        my $name = $col_ref->{'field'};
        my $type = $col_ref->{'type'};

        if ( $type eq 'datetime'  ||
             $type eq 'timestamp' ||
             $type eq 'date'      ||
             $type eq 'time' ) {

            # if it's a NULL value, we don't worry about it
            next if !$dbic->$name;
            my @units = @{ $units_of{$type} };

            foreach my $unit ( @units ) {
                # eg due_year
                my $param = $name . '_' . $unit;
                $attrs{ $param } = dt_pad( $dbic->$name->$unit );

            }

        }
    }

    return \%attrs;
}

=head2 get_date_menu( name => $name, readonly => [0|1] )

Return a date menu that can be used for "date" cols.
This will also be used when generating

=cut

sub get_date_menu {

    my $self = shift;

    my %args = validate( @_, \%menu_rules );

    my $name = $args{'name'};

    my $q = CGI->new;

    my $months = {
        '01' => 'Jan',
        '02' => 'Feb',
        '03' => 'Mar',
        '04' => 'Apr',
        '05' => 'May',
        '06' => 'Jun',
        '07' => 'Jul',
        '08' => 'Aug',
        '09' => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec',

    };

    my @elements = ( );
    my $readonly = undef;
    $readonly = "disabled => 1" if $args{'readonly'};

    my @months = dt_pad(1..12);
    push @elements, $q->popup_menu(
        -name => $name . '_month',
        -values => \@months,
        -labels => $months,
        $readonly
    );

    my @days = dt_pad(1..31);
    push @elements, $q->popup_menu(
        -name => $name . '_day',
        -values => \@days,
        $readonly
    );

    push @elements, $q->popup_menu(
        -name => $name . '_year',
        -values => [2006..($self->wf->dt->year + 5)],
        $readonly
    );

    return join " ", @elements;

}

=head2 get_timestamp_menu( $name )

Returns a time menu useful for timestamp cols
or for creating datetime cols

=cut

sub get_timestamp_menu {

    my $self = shift;
    my %args = validate( @_, \%menu_rules );

    my $name        = $args{'name'};
    my $readonly    = undef;
    $readonly       = "disabled => 1" if $args{'readonly'};

    my $q = CGI->new;

    my @elements = ( );

    my @hours = dt_pad(0..23);
    push @elements, $q->popup_menu(
        -name => $name . '_hour',
        -values => \@hours,
        $readonly
    );

    my @minutes = dt_pad(0..59);
    push @elements, $q->popup_menu(
        -name => $name . '_minute',
        -values => \@minutes,
        $readonly
    );

    my @seconds = dt_pad(0..59);
    push @elements, $q->popup_menu(
        -name => $name . '_second',
        -values => \@seconds,
        $readonly
    );

    return join " ", @elements;

}

=head2 expiration_month

Return a generic menu which can be used for credit card expiration dates

=cut

sub expiration_month {

    my $self = shift;
    my %args = @_;

    my @months = ( );
    foreach my $month ( 1..12 ) {
        push @months, zeropad( number => $month );
    }

    my $q = CGI->new;
    return $q->popup_menu(
        -name => 'expiration_month',
        -values => \@months,
        %args,
    );

}

=head2 expiration_year( years => $years )

Return a generic menu which can be used for credit card expiration year.  The
sole argument is the number of years you would like on the menu.  Will begin
with the current year.  Defaults to 10

=cut

sub expiration_year {

    my $self    = shift;
    my %args    = validate(
        @_, { years => { type => SCALAR, optional => 1, default => 10 } }
    );

    my $years = delete $args{'years'};

    # we aren't using a time zone, so we'll subtract a day in order to make
    # sure we don't run into any issues on Dec 31st of any given year
    my $dt = DateTime->now->add( days => -1 );

    my $q = CGI->new;
    return $q->popup_menu(
        -name => 'expiration_year',
        -values => [ $dt->year .. $dt->year + $years ],
        %args,
    );

}

=head2 ip2country( $ip )

Returns appropriate country_code for an IP.  Defaults to REMOTE_ADDR, but you
can override this by passing an IP address.

=cut

sub ip2country {

    my $self = shift;
    my $ip = shift || $ENV{'REMOTE_ADDR'};
    my $record = $self->wf->best_geo->record_by_addr( $ip );
    return $record ? $record->country_code : undef; 

}

=head2 ip2region( $ip )

Returns appropriate region_code for an IP.  Defaults to REMOTE_ADDR, but you
can override this by passing an IP address.

=cut

sub ip2region {

    my $self = shift;
    my $ip = shift || $ENV{'REMOTE_ADDR'};
    my $record = $self->wf->best_geo->record_by_addr( $ip );
    return $record ? $record->region : undef; 

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
