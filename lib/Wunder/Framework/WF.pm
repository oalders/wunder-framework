package Wunder::Framework::WF;

use Moose::Role;
use Wunder::Framework::Bundle;

=head2 SYNOPSIS

Mixes in a role (wf) which has access to all of the Wunder::Framework roles which are available.
Useful in Catalyst apps and other situations where you don't want to synthesize the roles into
$self.

=cut

has 'wf' => (
    is      => 'ro',
    isa     => 'Wunder::Framework::Bundle',
    lazy    => 1,
    default => sub { return Wunder::Framework::Bundle->new },
);

1;

