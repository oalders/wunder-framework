#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Test::More;
use Try::Tiny;

use Wunder::Framework::CAP::FormMail;

my $fm = Wunder::Framework::CAP::FormMail->new;

ok( $fm, "created object" );

ok( $fm->setup, "setup ok" );

SKIP: {
    skip "no formmail config", 2 unless $fm->form_config;
    ok( $fm->form_config, "config ok" );
    diag p $fm->form_config;

    ok( $fm->send_mail, "send mail ok" );
}
done_testing();
