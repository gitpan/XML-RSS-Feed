package XML::RSS::Headline::PerlJobs;
use strict;
use warnings;
use base qw(XML::RSS::Headline);

our $VERSION = 2.1;

=head1 NAME

XML::RSS::Headline::PerlJobs - XML::RSS::Headline Example Subclass

=head1 SYNOPSIS

You can also subclass XML::RSS::Headline to provide a 'multiline' RSS headline
based on additional information inside the RSS Feed.  Here is an example for 
the Perl Jobs (jobs.perl.org) RSS feed by simply passing in the C<hlobj> class
name.

    use XML::RSS::Feed;
    use XML::RSS::Headline::PerlJobs;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "perljobs",
	url   => "http://jobs.perl.org/rss/standard.rss",
	hlobj => "XML::RSS::Headline::PerlJobs",
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

    <rssbot>  + Part Time Perl
    <rssbot>    Brian Koontz - United States, TX, Dallas
    <rssbot>    Part time, Independent contractor (project-based)
    <rssbot>    http://jobs.perl.org/job/950

=head1 MUTAITED METHOD

=over 4

=item B<< $headline->item( $item ) >>

Init the object for a parsed RSS item returned by L<XML::RSS>.

=back

=cut 

sub item {
    my ($self,$item) = @_;
    $self->SUPER::item($item); # set url and description

    my $key = 'http://jobs.perl.org/rss/';
    my $name     = $item->{$key}{company_name}     || "";
    my $location = $item->{$key}{location}         || "Unknown Location";
    my $hours    = $item->{$key}{hours}            || "Unknown Hours";
    my $terms    = $item->{$key}{employment_terms} || "Unknown Terms";

    my $name_location = $name ? $name . " - " . $location : $location;
    $self->headline("$item->{title}\n$name_location\n$hours, $terms");
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

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::Fark>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

=cut

1;
