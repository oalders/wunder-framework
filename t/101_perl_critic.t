#!/usr/bin/perl

use Modern::Perl;
use Test::Perl::Critic ( -severity => 5 );
use Find::Lib;

all_critic_ok( Find::Lib::base() . "/../lib" );    #Test all files in several $dirs


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
