package XML::RSS::Feed;
use strict;
use XML::RSS;
use XML::RSS::Headline;
use Carp qw(confess);
use Time::HiRes;
use Storable qw(store retrieve);
use vars qw($VERSION);
$VERSION = 1.02;

=head1 NAME

XML::RSS::Feed - Encapsulate RSS XML New Items Watching

=head1 SYNOPSIS

A quick and dirty non-POE example that uses a blocking B<sleep>.  The
magic is in the B<late_breaking_news> method that returns only 
headlines it hasn't seen.

    use XML::RSS::Feed;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	url    => "http://www.jbisbee.com/rdf/",
	name   => "jbisbee",
	delay  => 10,
	debug  => 1,
	tmpdir => "/tmp", # optional caching
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

ATTENTION! - If you want a non-blocking way to watch multiple RSS sources 
with one process use POE::Component::RSSAggregator.

=head1 CONSTRUCTOR

=over 4

=item B<XML::RSS::Feed-E<gt>new( url =E<gt> $url, name =E<gt> $name )>

=over 4

=item B<Required Params>

=over 4

=item B<name>

Identifier for the RSS feed.

=item B<url>

The URL to the RSS feed

=back

=item B<Optional Params>

=over 4

=item B<delay>

Number of seconds between updates (defaults to 600)

=item B<tmpdir>

Optional directory to cache a feed L<Storable> file to keep persistance between instances.

=item B<debug>

Boolean value to turn debuging on.

=item B<headline_as_id>

Boolean value to use the headline as the id when URL isn't unique within a feed.

=item B<hlobj>

A class name sublcassed from L<XML::RSS::Headline>

=back

=back

=back

=cut 

sub new
{
    my $class = shift;

    my $self = bless { 
	rss_headlines    => [],
	rss_headline_ids => {},
	max_headlines    => 0,
    }, $class;

    my %args = @_;
    foreach my $method (keys %args) {
	if ($self->can($method)) {
	    $self->$method($args{$method})
	}
	else {
	    confess "Invalid argument '$method'";
	}
    }
    $self->_load_cached_headlines if $self->{tmpdir};
    $self->{delay} = 3600 unless $self->{delay};
    return $self;
}

sub _load_cached_headlines
{
    my ($self) = @_;
    if ($self->{tmpdir}) {
	my $filename_sto = $self->{tmpdir} . '/' . $self->name . '.sto';
	my $filename_xml = $self->{tmpdir} . '/' . $self->name;
	if (-s $filename_sto) {
	    my $cached  = retrieve($filename_sto);
	    $self->set_last_updated($cached->{last_updated});
	    $self->process($cached->{items},$cached->{title},$cached->{link});
	    warn "[$self->{name}] Loaded Cached RSS Storable\n" if $self->{debug};
	}
	elsif (-T $filename_xml) { # legacy XML caching
	    open(my $fh, $filename_xml);
	    my $xml = do { local $/, <$fh> };
	    close $fh;
	    warn "[$self->{name}] Loaded Cached RSS XML\n" if $self->{debug};
	    $self->parse($xml);
	}
	else {
	    warn "[$self->{name}] No Cache File Found\n" if $self->{debug};
	}
    }
}

sub _strip_whitespace
{
    my ($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _mark_all_headlines_seen
{
    my ($self) = @_;
    $self->{rss_headline_ids}{$_->id} = 1 for $self->late_breaking_news;
}

=head1 METHODS

=over 4

=item B<$feed-E<gt>parse( $xml_string )>

pass in a xml string to parse with XML::RSS and then call 
$feed->process() to process the results.

=back

=cut

sub parse
{
    my ($self,$xml) = @_;
    my $rss = XML::RSS->new();
    eval {
	$rss->parse($xml);
    };
    if ($@) {
	warn "[$self->{name}] !! Failed to parse RSS XML -> $@\n" if $self->debug;
	return 0;
    }
    else {
	warn "[$self->{name}] Parsed RSS XML\n" if $self->debug;
	my $items = [ map { { item => $_ } } @{$rss->{items}} ];
	$self->process($items,$rss->{channel}{title},$rss->{channel}{link});
	return 1;
    }
}

=over 4

=item B<$feed-E<gt>process( $items, $title, $link )>

=item B<$feed-E<gt>process( $items, $title )>

=item B<$feed-E<gt>process( $items )>

Calls B<pre_process>, B<process_items>, B<post_process>, B<title>, and B<link>
methods to process the parsed results of an RSS XML feed.

=over 4

=item $items

An array of hash refs which will eventually become XML::RSS::Headline objects.  Look
at XML::RSS::Headline->new() for acceptable arguments.

=item $title

The title of the RSS feed.

=item $link

The RSS channel link (normally a URL back to the homepage) of the RSS feed.

=back

=back

=cut

sub process
{
    my ($self,$items,$title,$link) = @_;
    if ($items) {
	$self->pre_process;
	$self->process_items($items);
	$self->title($title) if $title;;
	$self->link($link) if $link;
	$self->post_process;
    }
}

=over 4

=item B<$feed-E<gt>pre_process>

Mark all headlines from previous run as seen.

=back

=cut

sub pre_process
{
    my ($self) = @_;
    $self->_mark_all_headlines_seen;
}

=over 4

=item B<$feed-E<gt>process_items( $items )>

Turn an array refs of hash refs into L<XML::RSS::Headline> objects and added to the
internal list of headlines.

=back

=cut

sub process_items
{
    my ($self,$items) = @_;
    if ($items) {
	# used 'reverse' so order seen is preserved
	for my $item (reverse @$items) { 
	    $self->create_headline(%$item);
	}
    }
}

=over 4

=item B<$feed-E<gt>post_process>

Post process cleanup and debug messages.

=back

=cut

sub post_process
{
    my ($self) = @_;
    if ($self->init) {
	warn "[$self->{name}] " . $self->late_breaking_news . " New Headlines Found\n" 
	    if $self->debug;
    }
    else {
	$self->_mark_all_headlines_seen;
	$self->init(1);
	warn "[$self->{name}] " . $self->num_headlines . " Headlines Initialized\n" if $self->debug;
    }
    $self->set_last_updated;
}

=over 4

=item B<$feed-E<gt>create_headline( %args)>

Create a new XML::RSS::Headline object and add it to the interal list.  Check
XML::RSS::Headline->new() for acceptable values for B<%args>.

=back

=cut

sub create_headline
{
    my ($self, %args ) = @_;
    my $hlobj = $self->{hlobj} || "XML::RSS::Headline";
    $args{headline_as_id} = $self->{headline_as_id};
    my $headline = $hlobj->new(%args);
    push (@{$self->{rss_headlines}}, $headline) unless $self->seen_headline($headline->id);

    # lets remove the oldest if the new headline put us over the max_headlines limit
    if ($self->max_headlines) {
	while ($self->num_headlines > $self->max_headlines) {
	    my $garbage = shift @{$self->{rss_headlines}};
	    # just in case max_headlines < number of headlines in the feed
	    $self->{rss_headline_ids}{$garbage->id} = 1;
	    warn "[$self->{name}] Exceeded maximum headlines, removing oldest headline\n" 
		if $self->debug;
	}
    }
}

=over 4

=item B<$feed-E<gt>num_headlines>

Returns the number of headlines for the feed.

=back

=cut

sub num_headlines
{
    my ($self) = @_;
    return scalar @{$self->{rss_headlines}};
}

=over 4

=item B<$feed-E<gt>seen_headline( $id )>

Just a boolean test to see if we've seen a headline or not.

=back

=cut

sub seen_headline
{
    my ($self,$id) = @_;
    return 1 if exists $self->{rss_headline_ids}{$id};
    return 0;
}

=over 4

=item B<$feed-E<gt>headlines>

Returns an array or array reference (based on context) of XML::RSS::Headline objects

=back

=cut

sub headlines
{
    my ($self) = @_;
    return wantarray ? @{$self->{rss_headlines}} : $self->{rss_headlines};
}

=over 4

=item B<$feed-E<gt>late_breaking_news>

Returns an array or the number of elements (based on context) of the 
B<latest> XML::RSS::Headline objects.

=back

=cut

sub late_breaking_news
{
    my ($self) = @_;
    my @list = grep { !$self->seen_headline($_->id); } @{$self->{rss_headlines}};
    return wantarray ? @list : scalar @list;
}


=over 4

=item B<$feed-E<gt>DESTROY>

If tmpdir is defined the rss XML is cached when the object is destoryed.

=back

=cut

sub DESTROY
{
    my ($self) = @_;
    return unless $self->tmpdir;
    if (-d $self->tmpdir && $self->num_headlines) {
	my $tmp_filename = $self->tmpdir . '/' . $self->{name} . ".sto";
	if (store($self->_build_dump_structure, $tmp_filename)) {
	    warn "[$self->{name}] Cached RSS Storable to $tmp_filename\n" if $self->debug;
	}
	else {
	    warn "[$self->{name}] Could not cache RSS XML to $tmp_filename\n" if $self->debug;
	}
    }
}

sub _build_dump_structure
{
    my ($self) = @_;
    my $cached = {};
    $cached->{title} = $self->title;
    $cached->{link} = $self->link;
    $cached->{last_updated} = $self->{timestamp_hires};
    $cached->{items} = [];
    for my $headline (reverse $self->headlines) {
	push @{$cached->{items}}, {
	    headline     => $headline->headline,
	    url          => $headline->url,
	    description  => $headline->description,
	    first_seen   => $headline->first_seen_hires,
	};
    }
    return $cached;
}

=over 4

=item B<$feed-E<gt>set_last_updated>

=item B<$feed-E<gt>set_last_updated( Time::HiRes::time )>

Set the time of when the feed was last processed.  If you pass in a value
it will be used otherwise calls Time::HiRes::time.

=back

=cut

sub set_last_updated
{
    my ($self,$hires_time) = @_;
    $self->{hires_timestamp} = $hires_time || Time::HiRes::time();
}

=over 4

=item B<$feed-E<gt>last_updated>

The time (in epoch seconds) of when the feed was last processed.

=back

=cut

sub last_updated
{
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

=over 4

=item B<$feed-E<gt>last_updated_hires>

The time (in epoch seconds and milliseconds) of when the feed was last processed.

=back

=cut

sub last_updated_hires
{
    my ($self) = @_;
    return $self->{hires_timestamp};
}

=head1 SET/GET ACCESSOR METHODS

=over 4

=item B<$feed-E<gt>title>

=item B<$feed-E<gt>title( $title )>

The title of the RSS feed.

=back

=cut

sub title
{
    my ($self,$title) = @_;
    if ($title) {
	$title = _strip_whitespace($title);
	$self->{title} = $title if $title;
    }
    $self->{title};
}

=over 4

=item B<$feed-E<gt>debug>

=item B<$feed-E<gt>debug( $bool )>

Turn on debugging messages

=back

=cut

sub debug
{
    my $self = shift @_;
    $self->{debug} = shift if @_;
    $self->{debug};
}

=over 4

=item B<$feed-E<gt>init>

=item B<$feed-E<gt>init( $bool )>

init is used so that we just load the current headlines and don't return all 
headlines.  in other words we initialize them.  Takes a boolean argument.

=back

=cut

sub init
{
    my $self = shift @_;
    $self->{init} = shift if @_;
    $self->{init};
}

=over 4

=item B<$feed-E<gt>name>

=item B<$feed-E<gt>name( $name )>

The identifier of an RSS feed.

=back

=cut

sub name
{
    my $self = shift;
    $self->{name} = shift if @_;
    $self->{name};
}

=over 4

=item B<$feed-E<gt>delay>

=item B<$feed-E<gt>delay( $seconds )>

Number of seconds between updates.

=back

=cut

sub delay
{
    my $self = shift @_;
    $self->{delay} = shift if @_;
    $self->{delay};
}

=over 4

=item B<$feed-E<gt>link>

=item B<$feed-E<gt>link( $rss_channel_url )>

The url in the RSS feed with a link back to the site where the RSS feed came from.

=back

=cut

sub link
{
    my $self = shift @_;
    $self->{link} = shift if @_;
    $self->{link};
}

=over 4

=item B<$feed-E<gt>url>

=item B<$feed-E<gt>url( $url )>

The url in the RSS feed with a link back to the site where the RSS feed came from.

=back

=cut

sub url
{
    my $self = shift @_;
    $self->{url} = shift if @_;
    $self->{url};
}

=over 4

=item B<$feed-E<gt>headline_as_id>

=item B<$feed-E<gt>headline_as_id( $bool )>

Within some RSS feeds the URL may not always be unique, in these cases
you can use the headline as the unique id.  The id is used to check whether
or not a feed is new or has already been seen.

=back

=cut

sub headline_as_id
{
    my $self = shift @_;
    # FIXME this should loop through an existing headlines and set their 
    #       headline_as_id value as well
    $self->{headline_as_id} = shift if @_;
    $self->{headline_as_id};
}

=over 4

=item B<$feed-E<gt>hlobj>

=item B<$feed-E<gt>hlobj( $class )>

Ablity to change use a subclass XML::RSS::Headline package to encapsulate
the RSS headlines.  (See Perl Jobs example in L<XML::RSS::Headline>).  This
should just be the package name

=back

=cut

sub hlobj
{
    my $self = shift @_;
    $self->{hlobj} = shift if @_;
    $self->{hlobj};
}

=over 4

=item B<$feed-E<gt>tmpdir>

=item B<$feed-E<gt>tmpdir( $tmpdir )>

Temporay directory to store cached RSS XML between instances for persistance.

=back

=cut

sub tmpdir
{
    my $self = shift @_;
    $self->{tmpdir} = shift if @_;
    $self->{tmpdir};
}

=over 4

=item B<$feed-E<gt>max_headlines>

=item B<$feed-E<gt>max_headlines( $integer )>

The maximum number of headlines you'd like to keep track of.  (0 means infinate)

=back

=cut

sub max_headlines
{
    my $self = shift @_;
    $self->{max_headlines} = shift if @_;
    $self->{max_headlines};
}


=head1 AUTHOR

=over 4

=item Jeff Bisbee

=item CPAN ID: JBISBEE

=item cpan@jbisbee.com

=item http://search.cpan.org/author/JBISBEE/

=back

=head1 COPYRIGHT

=over 4

=item This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=item The full text of the license can be found in the LICENSE file included with this module.

=back

=head1 SEE ALSO

=over 4

=item L<XML::RSS::Headline>, L<POE::Component::RSSAggregator>

=back

=cut

1;
