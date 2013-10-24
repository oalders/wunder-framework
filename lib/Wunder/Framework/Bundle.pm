package Wunder::Framework::Bundle;

use Moose;
with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::DateTime';
with 'Wunder::Framework::Roles::DBI';
with 'Wunder::Framework::Roles::Email';
with 'Wunder::Framework::Roles::Geo';
with 'Wunder::Framework::Roles::Log';
with 'Wunder::Framework::Roles::MySQL';

=head2 SYNOPIS

Object which mixes in all available Framework roles

=cut

__PACKAGE__->meta->make_immutable();
1;
