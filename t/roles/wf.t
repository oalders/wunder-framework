#!/usr/bin/env perl

use Modern::Perl;

=head1 SYNOPSIS

Basically a load test

=cut

use Test::More;
use Wunder::Framework::Test::Roles::WF;

require_ok( 'Wunder::Framework::Test::Roles::WF' );
my $wf = Wunder::Framework::Test::Roles::WF->new;
ok( $wf, "got an object" );
isa_ok( $wf->wf,     'Wunder::Framework::Bundle' );
isa_ok( $wf->wf->dt, 'DateTime' );

done_testing();
