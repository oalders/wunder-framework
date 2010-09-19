package Wunder::Framework::CAP::Routes;

use Moose;
use Modern::Perl;
use Data::Dump qw( dump );

=head1 SYNOPSIS

This module is based loosely on CGI::Application::Plugin::Routes.  I couldn't
get it to work and I'd like to add my own validation, 404 redirects etc, so I
spent an hour or so to do the same thing with a custom method.  The added
benefit is that this stuff is actually readable...

You would use it in a multiple inheritance situation:

use base ( 'Wunder::Framework::CAP::Super', 'Wunder::Framework::CAP::Routes');

There will be many applications which don't use this and I may, at some point,
want to switch over to the Routes plugin if/when it's improved, so this seems
like the cleanest way to tackle this

=head2 register_routes

Enable all run modes listed in the routing table and assign them to a method
of the same name

=cut

sub register_routes {

    my $self    = shift;
    my %args    = @_;
    $self->param( strict_routes => 1 ) if $args{'strict'};
    $self->param( debug => 1 ) if $args{'debug'};

    my @routes  = ( );

    if ( $self->param('routes') ) {
        @routes = @{ $self->param('routes') };
    }
    if ( $args{'urls'} ) {
        if ( exists $args{'stackable'} && $args{'stackable'} ) {
            $self->logger("is stackable") if $self->debug_routes;
            push @routes, @{ $args{'urls'} };
        }
        else {
            @routes = @{ $args{'urls'} };
        }
    }

    my %routes  = @routes;

    foreach my $rm ( values %routes ) {
        $self->run_modes( $rm => $rm );
    }

    $self->param( routes => \@routes );
    $self->param( routes_prerun => $self->process_routes );

    return;

}

=head2 routes

Simple accessor.  Returns the name of the prerun_mode, if it could be found.

=cut

sub routes {

    my $self = shift;
    return $self->param( 'routes_prerun' );

}

=head2 process_routes

The routing table is an ARRAYREF and it is traversed in order from top to
bottom until every regex has been attempted.  So, paths should be listed in
order of shortest to longest.  The last successful match will be the match
that is processed.  I could have done this in reverse order, I suppose, but
that wouldn't make much sense to look at and I don't think we're going to lose
many CPU cycles to regexes on URLs.

=cut

sub process_routes {

    my $self    = shift;

    my @args    = ( );
    my $error   = undef;
    my $routes  = $self->param('routes') || [ ];

    my @table   = @{ $routes };
    my $path    = $self->query->path_info || $ENV{'SCRIPT_NAME'};
    my $new_rm  = undef;
    my $parts   = undef;
    my @names   = ( );

    return if !$path; # this is problem being run from the command line

    RULE:
    foreach ( 1 .. (scalar @table)/2 ) {

        my $rule    = shift @table;
        my $rm      = shift @table;

        $self->logger( "rule: $rule | rm: $rm ") if $self->debug_routes;

        if ( $rule =~ m{\A([a-zA-Z0-9/_\-]*)(.*)}gxms ) {

            my $regex   = $1;
            my $names   = $2;

            if ( $path =~ m{\A$regex(.*)} ) {
                $new_rm = $rm;
                $parts  = $1;
                @names  = ( );
            }
            else {
                # no point in continuing
                next RULE;
            }

            if ( $names ) {
                $names =~ s{\A:}{}gxms;
                @names = split "/:", $names;
            }

        }

    }


    if ( $new_rm ) {

        @args = split "/", $parts;

        # param validation should be enforced in run modes (not here)
        # strip away .html and .htm extensions as they are useless in this
        # context

        # however, if there are more params than are allowed for, this should
        # return a 404 (or whatever the default runmode is)

        if ( $self->param( 'strict_routes')
          && scalar ( @args ) > scalar ( @names ) ) {
            if ( $self->debug_routes ) {
                $self->logger( "strict routes enabled.  names exceed declared args.");
                $self->logger( "args: " . dump \@args );
                $self->logger( "names: " . dump \@names );
            }
            return;
        }

        foreach my $i ( 0 .. scalar @args - 1) {

            my $value = $args[$i];
            $value =~ s{\.html?\z}{}xms;

            $self->query->param(
                -name   => $names[$i],
                -value  => $value,
            );

            if ( $self->debug_routes ) {
                $self->logger( "routes: $names[$i] : $value" );
                $self->logger( "routes: " . dump \@args );
                $self->logger( dump $self->query );
            }
        }
    }

    my $debug = {
        args    => \@args,
        error   => $error,
        names   => \@names,
        parts   => $parts,
        path    => $path,
        path_info => $self->query->path_info,
        rm      => $new_rm,
        strict  => $self->param( 'strict_routes' ),
    };

    $self->param( debug_routes => $debug );
    if ( $self->debug_routes ) {
        $self->logger( "Routes debugging is enabled" );
        $self->logger( dump $debug );
    }

    $new_rm = $self->get_current_runmode if !$new_rm;

    return $new_rm;
}

=head2 dump_routes

Debugging tool -- dumps routing info

=cut

sub dump_routes {

    my $self = shift;
    return dump $self->param( 'debug_routes' );

}

=head2 routes_path

Return the URL path which Routes used to work its magic

=cut

sub routes_path {

    my $self = shift;

    if ( $self->param('debug_routes') ) {
        return $self->param('debug_routes')->{'path'} ;
    }

    return;
}

=head2 debug_routes

Returns true if debugging mode is enabled

=cut

sub debug_routes {

    my $self = shift;
    return $self->param('debug');

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
