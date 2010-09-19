#!/usr/bin/perl

use Modern::Perl;

use Find::Lib '../../lib';

use Wunder::Framework::Tools::Deploy;
my $base = Wunder::Framework::Tools::Deploy->new;

chdir( $base->path ) || die "$!";

$base->mail_admin( 
    data    => join ("", `prove --lib -Icontrib -r t`), 
    subject => sprintf('%s test results (%s)', $base->config->{'top_url'}, $base->stream), 
);

