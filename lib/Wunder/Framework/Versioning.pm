package Wunder::Framework::Versioning;

use Moose;
use Modern::Perl;

with 'MooseX::Getopt';

with 'Wunder::Framework::Roles::Config';
with 'Wunder::Framework::Roles::Deployment';
with 'Wunder::Framework::Roles::DBI';
with 'Wunder::Framework::Roles::DateTime';

=head1 SYNOPSIS

A (hopefully) flexible db versioning system, based on the DBIx::Class
module of similar name.

=cut

use Carp qw( croak );
use Data::Dump qw( dump );
use File::Tools qw( mkpath );
use IO::File;
use Params::Validate qw( validate_pos HASHREF SCALAR );
