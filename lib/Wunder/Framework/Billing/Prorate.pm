package Wunder::Framework::Billing::Prorate;

use Moose;

has 'amount'       => ( isa => 'Num',      is => 'ro', required => 1 );
has 'months'       => ( isa => 'Num',      is => 'ro', required => 1 );
has 'monthly_rate' => ( isa => 'Num',      is => 'ro', required => 1 );
has 'next_payment' => ( isa => 'DateTime', is => 'ro', required => 1 );
has 'start_date'   => ( isa => 'DateTime', is => 'ro', required => 1 );

1;
