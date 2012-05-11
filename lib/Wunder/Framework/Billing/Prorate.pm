package Wunder::Framework::Billing::Prorate;

use Moose;

=head2 DESCRIPTION

This object doesn't do anything other than hold some values and enforce some
type constraints.

=cut

has 'amount'       => ( isa => 'Num',      is => 'ro', required => 1 );
has 'months'       => ( isa => 'Num',      is => 'ro', required => 1 );
has 'monthly_rate' => ( isa => 'Num',      is => 'ro', required => 1 );
has 'next_payment' => ( isa => 'DateTime', is => 'ro', required => 1 );
has 'start_date'   => ( isa => 'DateTime', is => 'ro', required => 1 );

1;
