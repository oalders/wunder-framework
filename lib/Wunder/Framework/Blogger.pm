package Wunder::Framework::Blogger;

use Moose;

use Modern::Perl;
use Carp qw( croak );
use WWW::Mechanize;
use XML::Simple;

=head2 get_headlines( $feed_url )

Returns an ARRAYREF of latest article titles and links as provided by an RSS
feed.

=cut

sub get_headlines {
    
    my $self = shift;
    my $feed_url = shift || croak "feed url missing";
    
    my $mech = WWW::Mechanize->new;
    $mech->get( $feed_url );
        
    my $xs  = XML::Simple->new();
    my $ref = $xs->XMLin( $mech->content, ForceArray => 1 );
    
    my @posts = @{ $ref->{'entry'} };
    return if scalar @posts == 0;

    my @loop = ( );
    foreach my $post ( @posts ) {
        
        foreach my $link ( @{ $post->{'link'} } ) {
            if ( $link->{'rel'} eq 'alternate' ) {
                push @loop, $link;
                last;
            }
        }
    }
    
    return \@loop;
    
}

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
