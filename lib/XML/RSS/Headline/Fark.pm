package XML::RSS::Headline::Fark;
use strict;
use warnings;
use base qw(XML::RSS::Headline);
use URI::Escape qw(uri_unescape);

our $VERSION = 2.04;

=head1 NAME

XML::RSS::Headline::Fark - XML::RSS::Headline Example Subclass

=head1 SYNOPSIS

Strip out the extra Fark redirect URL and strip out the various [blahblah]
blocks in the headline

    use XML::RSS::Feed;
    use XML::RSS::Headline::Fark;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "fark",
	url   => "http://www.pluck.com/rss/fark.rss",
	hlobj => "XML::RSS::Headline::Fark",
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the before output in #news on irc.perl.org

    <rssbot>  - [Sad] Elizabeth Edwards diagnosed with breast cancer
    <rssbot>    http://go.fark.com/cgi/fark/go.pl?IDLink=1200026&location=http://www.msnbc.msn.com/id/6408022

and here is the updated output   

    <rssbot>  - Elizabeth Edwards diagnosed with breast cancer
    <rssbot>    http://www.msnbc.msn.com/id/6408022

=head1 MUTAITED METHOD

=over 4

=item B<< $headline->item( $item ) >>

Init the object for a parsed RSS item returned by L<XML::RSS>.

=back

=cut 

sub item {
    my ($self,$item) = @_;
    $self->SUPER::item($item); # set url and description

    my $headline = $self->headline;
    $headline =~ s/\[.+?\]\s+//;
    $self->headline($headline);

    my $url = $self->url;
    my $stripit = qr/http\:\/\/go\.fark\.com\/cgi\/fark\/go\.pl\?IDLink\=\d+\&location\=/;
    $url =~ s/$stripit//;
    $self->url(uri_unescape($url));
}

=head1 AUTHOR

Copyright 2004 Jeff Bisbee <jbisbee@cpan.org>

http://search.cpan.org/~jbisbee/

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

=cut

1;
