package Wunder::Framework::Roles::Log;

use Moose::Role;

#requires 'config';

use Modern::Perl;
use Log::Log4perl;

=head1 SYNOPSIS

The various roles required for logging when debugging

=head2 logger( $data )

Quick wrapper around logging functions to keep script from exiting if no
logger object exists.  Returns a lazy loading "singleton" object.

=cut

has 'logger_object' => (
    is         => 'ro',
    isa        => 'Log::Log4perl::Logger',
    lazy_build => 1,
);

sub logger {

    my $self = shift;
    $self->logger_object->info( @_ );
    return 1;

}

sub _build_logger_object {

    my $self = shift;

    if ( exists $self->config->{'log_file'} ) {

        Log::Log4perl->init( $self->config->{'log_file'} );
        return Log::Log4perl->get_logger( $self->config->{'log_level'}
                || 'INFO' );
    }

    my $path = $self->path;
    my $init = qq[
        log4perl.rootLogger=DEBUG, LOGFILE
        log4perl.category.Wunder.Base = DEBUG, LOGFILE

        log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
        log4perl.appender.LOGFILE.filename=$path/logs/perl.log
        log4perl.appender.LOGFILE.mode=append

        log4perl.appender.LOGFILE.layout=PatternLayout
        log4perl.appender.LOGFILE.layout.ConversionPattern=[%d] %F %L - %m%n
    ];

    Log::Log4perl->init( \$init );
    return Log::Log4perl->get_logger( 'INFO' );

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
