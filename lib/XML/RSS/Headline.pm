package XML::RSS::Headline;
use strict;
use Digest::MD5 qw(md5_base64);
use URI;
use Carp qw(cluck confess);
use Time::HiRes;
use vars qw($VERSION);
$VERSION = 1.01;

=head1 NAME

XML::RSS::Headline - Wrapper for RSS Feed Headline Items

=head1 SYNOPSIS

Headline object to encapsulate the headline/URL combination of a RSS feed.  It
provides a unique id either by way of the URL or by doing an MD5 checksum on the 
headline (when URL uniqueness fails).

=head1 CONSTRUCTOR

=over 4

=item B<XML::RSS::Headline-E<gt>new( headline =E<gt> $headline, url =E<gt> $url )>

=item B<XML::RSS::Headline-E<gt>new( item =E<gt> $item )>

A XML::RSS::Headline object can be initialized either with headline/url or 
with a parse XML::RSS item structure.  The argument 'headline_as_id' is 
optional and takes a boolean as its value.

=back

=cut 

sub new
{
    my $class = shift @_;
    my $self = bless {}, $class;
    my %args = @_;
    my $first_seen = $args{first_seen} || Time::HiRes::time();
    delete $args{first_seen} if exists $args{first_seen};

    if ($args{item}) {
	confess 'missing title or link within item' unless 
	    $args{item}->{link} && $args{item}->{title};
    }
    else {
	confess 'url/headline or item required' unless $args{url} && $args{headline};
    }
    foreach my $method (keys %args) {
	if ($self->can($method)) {
	    $self->$method($args{$method})
	}
	else {
	    confess "Invalid argument '$method'";
	}
    }
    $self->set_first_seen($first_seen);
    return $self;
}

=head1 METHODS

=over 4

=item B<$headline-E<gt>id>

The id is our unique identifier for a headline/url combination.  Its how we 
can keep track of which headlines we have seen before and which ones are new.
The id is either the URL or a MD5 checksum generated from the headline text 
(if B<$headline-E<gt>headline_as_id> is true);

=back

=cut 

sub id
{
    my ($self) = shift @_;
    return $self->{_rss_headline_id} if $self->headline_as_id;
    return $self->url;
}

sub _cache_id
{
    my ($self) = @_;
    $self->{_rss_headline_id} = md5_base64($self->headline)
}

=over 4

=item B<$headline-E<gt>multiline_headline>

This method returns the headline as either an array or array 
reference based on context.  It splits headline on newline characters 
into the array.

=back

=cut 

sub multiline_headline
{
    my ($self) = @_;
    my @multiline_headline = split /\n/, $self->headline;
    return wantarray ? @multiline_headline : \@multiline_headline;
}

=over 4

=item B<$headline-E<gt>item( $item )>

Init the object for a parsed RSS item returned by L<XML::RSS>.

=back

=cut 

sub item
{
    my ($self,$item) = @_;
    if ($item) {
	$self->url($item->{link});
	$self->headline($item->{title});
	$self->description($item->{description});
    }
}

=over 4

=item B<$headline-E<gt>set_first_seen>

=item B<$headline-E<gt>set_first_seen( Time::HiRes::time )>

Set the time of when the headline was first seen.  If you pass in a value
it will be used otherwise calls Time::HiRes::time.

=back

=cut

sub set_first_seen
{
    my ($self,$hires_time) = @_;
    $self->{hires_timestamp} = $hires_time || Time::HiRes::time();
}

=over 4

=item B<$headline-E<gt>first_seen>

The time (in epoch seconds) of when the headline was first seen.

=back

=cut

sub first_seen
{
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

=over 4

=item B<$headline-E<gt>first_seen_hires>

The time (in epoch seconds and milliseconds) of when the headline was first seen.

=back

=cut

sub first_seen_hires
{
    my ($self) = @_;
    return $self->{hires_timestamp};
}

=head1 GET/SET ACCESSOR METHODS

=over 4

=item B<$headline-E<gt>headline>

=item B<$headline-E<gt>headline( $headline )>

The rss headline/title

=cut 

sub headline
{
    my ($self,$headline) = @_;
    if ($headline) {
	$self->{headline} = $headline;
	$self->_cache_id if $self->headline_as_id;
    }
    return $self->{headline};
}

=item B<$headline-E<gt>url>

=item B<$headline-E<gt>url( $url )>

The rss link/url.  URI->canonical is called to attempt to normalize the URL

=cut 

sub url
{
    my ($self,$url) = @_;
    # clean the URL up a bit
    $self->{url} = URI->new($url)->canonical if $url;
    return $self->{url};
}

=item B<$headline-E<gt>description>

=item B<$headline-E<gt>description( $description )>

The description of the RSS headline.

=cut 

sub description
{
    my ($self,$description) = @_;
    $self->{description} = $description if $description;
    return $self->{description};
}


=item B<$headline-E<gt>headline_as_id>

=item B<$headline-E<gt>headline_as_id( $bool )>

A bool value that determines whether the URL will be the unique identifier or 
the if an MD5 checksum of the RSS title will be used instead.  (when the URL
doesn't provide absolute uniqueness or changes within the RSS feed) 

This is used in extreme cases when URLs aren't always unique to new healines
(Use Perl Journals) and when URLs change within a RSS feed (www.debianplanet.org / 
debianplanet.org / search.cpan.org,search.cpan.org:80)

=cut 

sub headline_as_id
{
    my ($self,$bool) =  @_;
    if (defined $bool) {
	$self->{headline_as_id} = $bool;
	$self->_cache_id;
    }
    $self->{headline_as_id};
}

=item B<$headline-E<gt>timestamp>

=item B<$headline-E<gt>timestamp( Time::HiRes::time() )>

A high resolution timestamp that is set using Time::HiRes::time when the 
object is created.

=back

=cut 

sub timestamp
{
    my ($self,$timestamp) = @_;
    $self->{timestamp} = $timestamp if $timestamp;
    return $self->{timestamp};
}

=head1 SUBCLASS EXAMPLE

You can also subclass XML::RSS::Headline to provide a 'multiline' RSS headline
based on additional information inside the RSS Feed.  Here is an example for 
the Perl Jobs (jobs.perl.org) RSS feed.

    use XML::RSS::Feed;
    use LWP::Simple qw(get);
    use PerlJobs;

    my $feed = XML::RSS::Feed->new(
	url   => "http://jobs.perl.org/rss/standard.rss",
	hlobj => "PerlJobs",
	name  => "perljobs",
	delay => 60,
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is PerlJobs.pm which is subclassed from XML::RSS::Headline in
this example and B<$headline-E<gt>item> is redefined to init 
B<$self-E<gt>headline> with more nested info located with in the 
parsed RSS item structure.  (Notice that we're just concatinating 
bits of info with newlines to seperate the lines.

    package XML::RSS::Headline::PerlJobs;
    use strict;
    use base qw(XML::RSS::Headline);

    sub item
    {
	my ($self,$item) = @_;
	$self->SUPER::item($item); # set url and description
	$self->headline( 
	    $item->{title} . "\n" . 
	    $item->{'http://jobs.perl.org/rss/'}{company_name} || "Unknown Company" . " - " .
	    $item->{'http://jobs.perl.org/rss/'}{location} || "Unknown Location" . "\n" .  
	    $item->{'http://jobs.perl.org/rss/'}{hours} || "Unknown Hours" . ", " . 
	    $item->{'http://jobs.perl.org/rss/'}{employment_terms} || "Unknown Terms"
	);
    }

    1;

Here is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

    <rssbot>  + Part Time Perl
    <rssbot>    Brian Koontz - United States, TX, Dallas
    <rssbot>    Part time, Independent contractor (project-based)
    <rssbot>    http://jobs.perl.org/job/950

=head1 AUTHOR

=over 1

=item Jeff Bisbee

=item CPAN ID: JBISBEE

=item cpan@jbisbee.com

=item http://search.cpan.org/author/JBISBEE/

=back

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<POE::Component::RSSAggregator>

=cut

1;
