package XML::RSS::Headline::UsePerlJournals;
use strict;
use warnings;
use base qw(XML::RSS::Headline);

our $VERSION = 2.04;

=head1 NAME

XML::RSS::Headline::UsePerlJournals - XML::RSS::Headline Example Subclass

=head1 SYNOPSIS

You can also subclass XML::RSS::Headline to tweak the rss content to your liking.
In this example. I change the headline to remove the date/time and add the 
Use Perl Journal author's ID.  Also in this use Perl; rss feed you get the actual link 
to the journal entry, rather than the link just to the user's journal.  (meaning that
the journal URLs contain the entry's ID)

    use XML::RSS::Feed;
    use XML::RSS::Headline::UsePerlJournals;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "useperljournals",
	url   => "http://use.perl.org/search.pl?tid=&query=&author=&op=journals&content_type=rss",
	hlobj => "XML::RSS::Headline::UsePerlJournals",
	delay => 60,
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

    <rssbot>  + [pudge] New Cool Journal RSS Feeds at use Perl;
    <rssbot>    http://use.perl.org/~pudge/journal/21884

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
    my $url = $self->url;
    my ($id) = $url =~ /\/\~(.+?)\//;
    $headline =~ s/\s+\(.+\)\s*$//;

    $self->headline("[$id] $headline");
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

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::Fark>, L<POE::Component::RSSAggregator>

=cut

1;
