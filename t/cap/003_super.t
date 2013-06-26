#!/usr/bin/perl

use Modern::Perl;
use Test::More qw( no_plan );

require_ok( 'Wunder::Framework::CAP::Super' );
my $super = Wunder::Framework::CAP::Super->new;

isa_ok( $super, "Wunder::Framework::CAP::Super" );

my $logger = $super->logger_object;
isa_ok( $logger, 'Log::Log4perl::Logger' );

isa_ok( $super->dt, 'DateTime' );
ok( $super->path,       "got path: " . $super->path );
ok( $super->stream,     "got stream: " . $super->stream );
ok( $super->site,       "got site name: " . $super->site );
ok( $super->tt_filters, "got some filters" );

my $dt = $super->dt( epoch => 1 );
isa_ok( $dt, 'DateTime' );

$dt->add( months => 1 );
cmp_ok( $dt->year, '==', 1970, "creates DateTime from epoch" );

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
