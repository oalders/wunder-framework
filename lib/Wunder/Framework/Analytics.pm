package Wunder::Framework::Analytics;

use Modern::Perl;
use Socket qw( AF_INET inet_pton );
use Sub::Exporter -setup => { exports => [ qw(ip2host) ] };

sub ip2host {
    my $ip = shift;
    my $iaddr = inet_pton( AF_INET, $ip );
    return gethostbyaddr( $iaddr, AF_INET );
}

1;

=head2 ip2host ( $ip )

IP to hostname conversion

=cut
