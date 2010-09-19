package Wunder::Framework::Tools::MySQL;

use Moose;
use MooseX::Params::Validate;

with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::MySQL';

=head1 SYNOPSIS

The make_grants script in the tools directory requires this package in order
to function.

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

1;
