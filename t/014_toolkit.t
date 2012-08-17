#!/usr/bin/env perl

use Modern::Perl;
use Test::More;

use Wunder::Framework::Tools::Toolkit qw( round );

require_ok('Wunder::Framework::Tools::Toolkit');

is ( round(0), 0, "rounds 0 correctly" );
is ( round(1), 1, "rounds 1 correctly" );
is ( round(1.4444), 1.44, "defaults to 2 places" );
is ( round(1.4444, 1), 1.4, "rounds to arbitrary decimal places" );

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
