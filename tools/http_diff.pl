#!/usr/bin/env perl

=head1 SYNOPSIS

Diffs in XHTML format

    perl wunder-tools/http_diff.pl http://domain.com/page1.html http://domain.com/page2.html > diff.html

=cut

use Modern::Perl;
use Data::Printer;
use Furl;
use Text::Diff;

my @URLs = @ARGV;

die 'usage: http_diff.pl $url $other_url' if scalar @URLs != 2;

my $furl = Furl->new;
my @html = ( );
foreach my $url ( @URLs ) {
    my $res = $furl->get( $url );
    push @html, \$res->content;
}

my $diff = diff @html, { STYLE => 'Text::Diff::HTML' };

say qq[
<style type="text/css">
.file span { display: block; }
.file .fileheader, .file .hunkheader {color: #888; }
.file .hunk .ctx { background: #eee;}
.file .hunk ins { background: #dfd; text-decoration: none; display: block; }
.file .hunk del { background: #fdd; text-decoration: none; display: block; }
</style>
$diff
];
