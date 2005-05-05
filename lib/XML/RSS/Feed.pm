package XML::RSS::Feed;
use strict;
use warnings;
use XML::RSS;
use XML::RSS::Headline;
use Time::HiRes;
use Storable qw(store retrieve);

our $VERSION = 2.1;

=head1 NAME

XML::RSS::Feed - Persistant XML RSS Encapsulation

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
with one process use L<POE::Component::RSSAggregator>.

=head1 CONSTRUCTOR

=over 4

=item B<< XML::RSS::Feed->new( url => $url, name => $name ) >>

=item B<Required Params>

=over 4

=item * B<name> 

Identifier and hash lookup key for the RSS feed. 

=item * B<url> 

The URL of the RSS feed

=back

=item B<Optional Params>

=over 4

=item * B<delay> 

Number of seconds between updates (defaults to 600)

=item * B<tmpdir> 

Directory to keep a cached feed (using Storable) to keep persistance between instances.

=item * B<debug>

Turn debuging on.

=item * B<headline_as_id>

Boolean value to use the headline as the id when URL isn't unique within a feed.

=item * B<hlobj>

A class name sublcassed from L<XML::RSS::Headline>

=item * B<max_headlines>

The max number of headlines to keep.  (default is unlimited)

=back

=back

=cut 

sub new {
    my $class = shift;

    my $self = bless {
	process_count    => 0,
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
	    warn "Invalid argument '$method'";
	}
    }
    $self->_load_cached_headlines if $self->{tmpdir};
    $self->delay(3600) unless $self->delay;
    return $self;
}

sub _load_cached_headlines {
    my ($self) = @_;
    my $filename_sto = $self->{tmpdir} . '/' . $self->name . '.sto';
    my $filename_xml = $self->{tmpdir} . '/' . $self->name;
    if (-s $filename_sto) {
	my $cached  = retrieve($filename_sto);
	my $title = $self->title || $cached->{title} || "";
	$self->set_last_updated($cached->{last_updated});
	$self->{process_count}++;
	$self->process($cached->{items},$title,$cached->{link});
	warn "[$self->{name}] Loaded Cached RSS Storable\n" if $self->{debug};
    }
    elsif (-T $filename_xml) { # legacy XML caching
	open(my $fh, $filename_xml);
	my $xml = do { local $/, <$fh> };
	close $fh;
	warn "[$self->{name}] Loaded Cached RSS XML\n" if $self->{debug};
	$self->{process_count}++;
	$self->parse($xml);
    }
    else {
	warn "[$self->{name}] No Cache File Found\n" if $self->{debug};
    }
}

sub _strip_whitespace {
    my ($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _mark_all_headlines_seen {
    my ($self) = @_;
    return unless $self->{process_count};
    $self->{rss_headline_ids}{$_->id} = 1 for $self->late_breaking_news;
}

=head1 METHODS

=over 4

=item B<< $feed->parse( $xml_string ) >>

Pass in a xml string to parse with XML::RSS and then call 
B<< $feed->process() >> to process the results.

=cut

sub parse {
    my ($self,$xml) = @_;
    my $rss = XML::RSS->new();
    eval { $rss->parse($xml) };
    if ($@) {
	warn "[$self->{name}] [!!] Failed to parse RSS XML: $@\n";
	return 0;
    }
    else {
	warn "[$self->{name}] Parsed RSS XML\n" if $self->{debug};
	my $items = [ map { { item => $_ } } @{$rss->{items}} ];

	$self->process($items,($self->title || $rss->{channel}{title}),$rss->{channel}{link});
	return 1;
    }
}

=item B<< $feed->process( $items, $title, $link ) >>

=item B<< $feed->process( $items, $title ) >>

=item B<< $feed->process( $items ) >>

Calls B<pre_process>, B<process_items>, B<post_process>, B<title>, and B<link>
methods to process the parsed results of an RSS XML feed.

=over 4

=item * B<$items>

An array of hash refs which will eventually become L<XML::RSS::Headline> objects.  Look
at XML::RSS::Headline->new() for acceptable arguments.

=item * B<$title>

The title of the RSS feed.

=item * B<$link>

The RSS channel link (normally a URL back to the homepage) of the RSS feed.

=back

=cut

sub process {
    my ($self,$items,$title,$link) = @_;
    if ($items) {
	$self->pre_process;
	$self->process_items($items);
	$self->title($title) if $title;;
	$self->link($link) if $link;
	$self->post_process;
	return 1;
    }
    return 0;
}

=item B<< $feed->pre_process >>

Mark all headlines from previous run as seen.

=cut

sub pre_process {
    my ($self) = @_;
    $self->_mark_all_headlines_seen;
}

=item B<< $feed->process_items( $items ) >>

Turn an array refs of hash refs into L<XML::RSS::Headline> objects and added to the
internal list of headlines.

=cut

sub process_items {
    my ($self,$items) = @_;
    if ($items) {
	# used 'reverse' so order seen is preserved
	for my $item (reverse @$items) { 
	    $self->create_headline(%$item);
	}
	return 1;
    }
    return 0;
}

=item B<< $feed->post_process >>

Post process cleanup, cache headlines (if tmpdir), and debug messages.

=cut

sub post_process {
    my ($self) = @_;
    if ($self->init) {
	warn "[$self->{name}] " . $self->late_breaking_news . " New Headlines Found\n" 
	    if $self->{debug};
    }
    else {
	$self->_mark_all_headlines_seen;
	$self->init(1);
	warn "[$self->{name}] " . $self->num_headlines . " Headlines Initialized\n" 
	    if $self->{debug};
    }
    $self->{process_count}++;
    $self->cache;
    $self->set_last_updated;
}

=item B<< $feed->create_headline( %args) >>

Create a new L<XML::RSS::Headline> object and add it to the interal list.  Check
B<< XML::RSS::Headline->new() >> for acceptable values for B<< %args >>.

=cut

sub create_headline {
    my ($self, %args ) = @_;
    my $hlobj = $self->{hlobj} || "XML::RSS::Headline";
    $args{headline_as_id} = $self->{headline_as_id};
    my $headline = $hlobj->new(%args);
    return unless $headline;

    unshift (@{$self->{rss_headlines}}, $headline) unless $self->seen_headline($headline->id);

    # lets remove the oldest if the new headline put us over the max_headlines limit
    if ($self->max_headlines) {
	while ($self->num_headlines > $self->max_headlines) {
	    my $garbage = pop @{$self->{rss_headlines}};
	    # just in case max_headlines < number of headlines in the feed
	    $self->{rss_headline_ids}{$garbage->id} = 1;
	    warn "[$self->{name}] Exceeded maximum headlines, removing oldest headline\n" 
		if $self->{debug};
	}
    }
}

=item B<< $feed->num_headlines >>

Returns the number of headlines for the feed.

=cut

sub num_headlines {
    my ($self) = @_;
    return scalar @{$self->{rss_headlines}};
}

=item B<< $feed->seen_headline( $id ) >>

Just a boolean test to see if we've seen a headline or not.

=cut

sub seen_headline {
    my ($self,$id) = @_;
    return 1 if exists $self->{rss_headline_ids}{$id};
    return 0;
}

=item B<< $feed->headlines >>

Returns an array or array reference (based on context) of L<XML::RSS::Headline> objects

=cut

sub headlines {
    my ($self) = @_;
    return wantarray ? @{$self->{rss_headlines}} : $self->{rss_headlines};
}

=item B<< $feed->late_breaking_news >>

Returns an array or the number of elements (based on context) of the 
B<latest> L<XML::RSS::Headline> objects.

=cut

sub late_breaking_news {
    my ($self) = @_;
    my @list = grep { !$self->seen_headline($_->id); } @{$self->{rss_headlines}};
    return wantarray ? @list : scalar @list;
}


=item B<< $feed->cache >>

If tmpdir is defined the rss info is cached.

=cut

sub cache {
    my ($self) = @_;
    return unless $self->tmpdir;
    if (-d $self->tmpdir && $self->num_headlines) {
	my $tmp_filename = $self->tmpdir . '/' . $self->{name} . ".sto";
	eval { store($self->_build_dump_structure, $tmp_filename) };
	if ($@) {
	    warn "[$self->{name}] Could not cache RSS XML to $tmp_filename\n";
	    return;
	}
	else {
	    warn "[$self->{name}] Cached RSS Storable to $tmp_filename\n" if $self->{debug};
	    return 1;
	}
    }
    return;
}

sub _build_dump_structure {
    my ($self) = @_;
    my $cached = {};
    $cached->{title} = $self->title;
    $cached->{link} = $self->link;
    $cached->{last_updated} = $self->{timestamp_hires};
    $cached->{items} = [];
    for my $headline ($self->headlines) {
	push @{$cached->{items}}, {
	    headline     => $headline->headline,
	    url          => $headline->url,
	    description  => $headline->description,
	    first_seen   => $headline->first_seen_hires,
	};
    }
    return $cached;
}

=item B<< $feed->set_last_updated >>

=item B<< $feed->set_last_updated( Time::HiRes::time ) >>

Set the time of when the feed was last processed.  If you pass in a value
it will be used otherwise calls Time::HiRes::time.

=cut

sub set_last_updated {
    my ($self,$hires_time) = @_;
    $self->{hires_timestamp} = $hires_time if $hires_time;
    $self->{hires_timestamp} = Time::HiRes::time() unless $self->{hires_timestamp}
}

=item B<< $feed->last_updated >>

The time (in epoch seconds) of when the feed was last processed.

=cut

sub last_updated {
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

=item B<< $feed->last_updated_hires >>

The time (in epoch seconds and milliseconds) of when the feed was last processed.

=cut

sub last_updated_hires {
    my ($self) = @_;
    return $self->{hires_timestamp};
}

=back

=head1 SET/GET ACCESSOR METHODS

=over 4

=item B<< $feed->title >>

=item B<< $feed->title( $title ) >>

The title of the RSS feed.

=cut

sub title {
    my ($self,$title) = @_;
    if ($title) {
	$title = _strip_whitespace($title);
	$self->{title} = $title if $title;
    }
    $self->{title};
}

=item B<< $feed->debug >>

=item B<< $feed->debug( $bool ) >>

Turn on debugging messages

=cut

sub debug {
    my $self = shift @_;
    $self->{debug} = shift if @_;
    $self->{debug};
}

=item B<< $feed->init >>

=item B<< $feed->init( $bool ) >>

init is used so that we just load the current headlines and don't return all 
headlines.  in other words we initialize them.  Takes a boolean argument.

=cut

sub init {
    my $self = shift @_;
    $self->{init} = shift if @_;
    $self->{init};
}

=item B<< $feed->name >>

=item B<< $feed->name( $name ) >>

The identifier of an RSS feed.

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    $self->{name};
}

=item B<< $feed->delay >>

=item B<< $feed->delay( $seconds ) >>

Number of seconds between updates.

=cut

sub delay {
    my $self = shift @_;
    $self->{delay} = shift if @_;
    $self->{delay};
}

=item B<< $feed->link >>

=item B<< $feed->link( $rss_channel_url ) >>

The url in the RSS feed with a link back to the site where the RSS feed came from.

=cut

sub link {
    my $self = shift @_;
    $self->{link} = shift if @_;
    $self->{link};
}

=item B<< $feed->url >>

=item B<< $feed->url( $url ) >>

The url in the RSS feed with a link back to the site where the RSS feed came from.

=cut

sub url {
    my $self = shift @_;
    $self->{url} = shift if @_;
    $self->{url};
}

=item B<< $feed->headline_as_id >>

=item B<< $feed->headline_as_id( $bool ) >>

Within some RSS feeds the URL may not always be unique, in these cases
you can use the headline as the unique id.  The id is used to check whether
or not a feed is new or has already been seen.

=cut

sub headline_as_id {
    my ($self,$bool) = @_;
    if (defined $bool) {
	$self->{headline_as_id} = $bool;
	$_->headline_as_id($bool) for $self->headlines;
    }
    $self->{headline_as_id};
}

=item B<< $feed->hlobj >>

=item B<< $feed->hlobj( $class ) >>

Ablity to use a subclass of L<XML::RSS::Headline>.  (See Perl Jobs example in 
L<XML::RSS::Headline::PerlJobs>).  This should just be the name of the subclass.

=cut

sub hlobj {
    my ($self,$hlobj) = @_;
    $self->{hlobj} = $hlobj if defined $hlobj;
    $self->{hlobj};
}

=item B<< $feed->tmpdir >>

=item B<< $feed->tmpdir( $tmpdir ) >>

Temporay directory to store cached RSS XML between instances for persistance.

=cut

sub tmpdir {
    my $self = shift @_;
    $self->{tmpdir} = shift if @_;
    $self->{tmpdir};
}

=item B<< $feed->max_headlines >>

=item B<< $feed->max_headlines( $integer ) >>

The maximum number of headlines you'd like to keep track of.  (0 means infinate)

=cut

sub max_headlines {
    my $self = shift @_;
    $self->{max_headlines} = shift if @_;
    $self->{max_headlines};
}

=back

=head1 DEPRECATED METHODS

=over 4

=item B<< $feed->failed_to_fetch >>

This should was deprecated because, the object shouldn't really know
anything about fetching, it just processes the results.  This method 
currently will always return false

=cut

sub failed_to_fetch {
    warn __PACKAGE__ . "::failed_to_fetch has been deprecated";
    return;
}

=item B<< $feed->failed_to_parse >>

This method was deprecated because, $feed->parse now returns a bool value.
This method will always return false

=cut

sub failed_to_parse {
    warn __PACKAGE__ . "::failed_to_parse has been deprecated";
    return;
}

=back

=head1 AUTHOR

Copyright 2004 Jeff Bisbee <jbisbee@cpan.org>

http://search.cpan.org/~jbisbee/

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=head1 SEE ALSO

L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::Fark>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

=cut

1;
