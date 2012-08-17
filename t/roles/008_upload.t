#!/usr/bin/perl

use Modern::Perl;

=head1 SYNOPSIS

We can't expect the paid library to be installed on every machine, so the
->geo method shouldn't fail on undef

=cut

use Data::Dump qw( dump );
use Test::More tests => 1;
use Wunder::Framework::Bundle;
use Wunder::Framework::Test::Roles::Upload;

require_ok('Wunder::Framework::Test::Roles::Upload');
#my $upload = Wunder::Framework::Test::Roles::Upload->new;

