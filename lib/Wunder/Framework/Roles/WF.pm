package Wunder::Framework::Roles::WF;

use Moose::Role;
use Wunder::Framework::Bundle;

has 'wf' => (
    is      => 'ro',
    isa     => 'Wunder::Framework::Bundle',
    lazy    => 1,
    default => sub { return Wunder::Framework::Bundle->new },
);

1;

=pod

=head1 DESCRIPTION

Adds a wf role for access the Bundle roles. Helpful when using in tandem with
other frameworks and avoiding collisions with their method names.

=cut
