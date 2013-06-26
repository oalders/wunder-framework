#!/usr/bin/perl

use Data::Dump qw( dump );
use Find::Lib '../lib';
use Modern::Perl;
use Perl6::Junction qw( none );
use Test::More skip_all => 'slowing down test suite';

require_ok( 'Wunder::Framework::Tools::Build::CPAN' );
my $find = Wunder::Framework::Tools::Build::CPAN->new;

my $base = Find::Lib::base();

ok( $find, "got an object" );

$find->ignore_regex( [qr/WWW/] );
my @with_regex = $find->find_deps;
ok( none( @with_regex ) eq 'WWW::Facebook::API::Users', "regex works" );

my $ignore = ['URI'];
ok( $find->ignore( $ignore ), "can set ignore" );
cmp_ok( $find->ignore, 'eq', $ignore, "ignore set correctly" );

my @with_ignore = $find->find_deps( ["$base/../lib"] );
ok( none( @with_ignore ) eq 'URI', "module ignored" );

my @mods = $find->find_deps();
ok( @mods, "got deps with no args" );

