#!/usr/bin/perl

use Modern::Perl;

use Data::Dump qw( dump );
use Test::More tests => 2;

require_ok( 'Wunder::Framework::Test::Roles::Email' );

my $test = Wunder::Framework::Test::Roles::Email->new;

SKIP: {
    skip "config required for mail_admin", 1, if !$test->config->{'contact'};
    ok( $test->mail_admin(
            subject => 'framework test',
            data    => 'looks good'
        )
    );
}
