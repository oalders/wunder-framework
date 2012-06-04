#!/usr/bin/env perl

use Modern::Perl;
use Test::More;
use Wunder::Framework::Blogger;

my $blogger = Wunder::Framework::Blogger->new();
isa_ok( $blogger, 'Wunder::Framework::Blogger' );

my @headlines = $blogger->get_headlines(
    'http://blog.wundercounter.com/feeds/posts/default' );
ok( @headlines, "got headlines" );

done_testing();

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
