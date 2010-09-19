package Wunder::Framework::Roles::Everything;

use Moose::Role;

with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::DateTime';
with 'Wunder::Framework::Roles::DBI';
with 'Wunder::Framework::Roles::Email';
with 'Wunder::Framework::Roles::Geo';
with 'Wunder::Framework::Roles::Log';
with 'Wunder::Framework::Roles::MySQL';
with 'Wunder::Framework::Roles::Upload';
with 'Wunder::Framework::Roles::Config';

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
