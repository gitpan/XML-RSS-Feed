package XML::RSS::Feed;
use strict;
use XML::RSS;
use XML::RSS::Feed::Factory;
use XML::RSS::Feed::Headline;
use vars qw($VERSION);
$VERSION = 0.02;

=head1 NAME

XML::RSS::Feed - Encapsulate RSS XML New Items Watching

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use XML::RSS::Feed;
  use LWP::Simple;

  my %source = (
      url   => "http://www.jbisbee.com/rdf/",
      name  => "jbisbee",
      delay => 10,
  );
  my $feed = XML::RSS::Feed->new(%source);

  while (1) {
      print "Fetching " . $feed->url . "\n";
      my $rssxml = get($feed->url);
      if (my @late_breaking_news = $feed->parse($rssxml)) {;
        for my $headline (@late_breaking_news) {
          print $headline->headline . "\n";
        }
      }
      sleep($feed->delay);
  }

=head1 DESCRIPTION

ATTENTION! - If you want a non-blocking way to watch multiple RSS sources
with one process.  Use POE::Component::RSSAggregator

=head1 AUTHOR

	Jeff Bisbee
	CPAN ID: JBISBEE
	cpan@jbisbee.com
	http://www.jbisbee.com/perl/modules/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<POE::Component::RSSAggregator>, L<XML::RSS::Feed::Factory>, L<XML::RSS::Feed::Headline>

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    foreach my $method (keys %args) {
	if ($self->can($method)) {
	    $self->$method($args{$method})
	}
	else {
	    die "Invalid argument '$method'";
	}
    }
    $self->{delay} = 600 unless $self->{delay};
    return $self;
}

sub parse
{
    my ($self,$xml) = @_;
    my $rss_parser = XML::RSS->new();
    eval {
	$rss_parser->parse($xml);
    };
    if ($@) {
	warn "[!!] Failed to parse " . $self->url . "\n" if $self->debug;
	$self->failed_to_parse(1);
	return 0;
    }
    else {
	warn "[--] Parsed " . $self->url . "\n" if $self->debug;
	$self->title($rss_parser->{channel}->{title});
	$self->link($rss_parser->{channel}->{link});
	$self->_process_items($rss_parser->{items});
	return 0;
    }
}

sub title
{
    my ($self,$title) = @_;
    if ($title) {
	$title = _strip_whitespace($title);
	$self->{title} = $title if $title;
    }
    $self->{title};
}

sub num_headlines
{
    my ($self) = @_;
    my $num_headlines = 0;
    $num_headlines = @{$self->{rss_headlines}} if $self->{rss_headlines};
    return $num_headlines;
}

sub _process_items
{
    my ($self,$items) = @_;
    if ($items) {
	my @late_breaking_news = ();
	# the $seen variable fixes and issue where a headline is 
	# added and removed and the very last headline appears as 
	# new.  $seen sets a flag that once old headlines are found
	# in the items array, there cant be any new ones.
	my $seen = 0;
	my @headlines = map { 
	    my $headline = XML::RSS::Feed::Headline->new(
		headline       => $self->_build_headline($_),
		url            => $_->{'link'},
		feed           => $self,
		item           => $_,
		headline_as_id => $self->headline_as_id,
	    );
	    # init is used so that we just load the current headlines
	    # and don't return all headlines.  in other words
	    # we initialize them
	    unless ($self->seen_headline($headline->id) || 
		    $seen || 
		    !$self->init) {
		push @late_breaking_news, $headline 
	    }
	    $seen = 1 if $self->seen_headline($headline->id); 
	    $headline;
	} @$items;
	$self->init(1);
	$self->late_breaking_news(\@late_breaking_news);
	$self->headlines(\@headlines);

	# turn on 'debug' to figure things out
	warn "[--] " . @headlines . " Headlines Found for " . 
	    $self->url . "\n" if $self->debug;
	warn "[--] " . @late_breaking_news . " New Headlines Found for " . 
	    $self->url . "\n" if $self->debug;
    }
    else {
	warn "[!!] No Headlines Found for " . $self->url . "\n" if $self->debug;
    }
}

sub headlines
{
    my ($self,$headlines) = @_;
    if ($headlines) {
	$self->{rss_headline_ids} = {map { $_->id, $_ } @$headlines};
	$self->{rss_headlines} = $headlines;
    }
    return $self->{rss_headlines};
}

sub seen_headline
{
    my ($self,$id) = @_;
    return 1 if exists $self->{rss_headline_ids}{$id};
    return 0;
}

sub human_readable_delay
{
    my ($self) = @_;
    my %lookup = (
	'300'  => '5 mintues',
	'600'  => '10 mintues',
	'900'  => '15 mintues',
	'1800' => 'half an hour',
	'3600' => 'hour',
    );
    return $lookup{$self->delay} || $self->delay . " seconds";
}

sub _strip_whitespace
{
    my ($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# just override this method to get more info for the XML::RSS 'item'
sub _build_headline
{
    my ($self,$item) = @_;
    return $item->{title}
}

sub late_breaking_news
{
    my $self = shift;
    $self->{late_breaking_news} = shift if @_;
    $self->{late_breaking_news} = [] unless $self->{late_breaking_news};
    return wantarray ? @{$self->{late_breaking_news}} : 
	"@{$self->{late_breaking_news}}";
}


## GENERIC SET/GET METHODS

sub debug
{
    my $self = shift @_;
    $self->{debug} = shift if @_;
    $self->{debug};
}

sub init
{
    my $self = shift @_;
    $self->{init} = shift if @_;
    $self->{init};
}

sub link
{
    my $self = shift @_;
    $self->{link} = shift if @_;
    $self->{link};
}

sub name
{
    my $self = shift;
    $self->{name} = shift if @_;
    $self->{name};
}

sub parsed_xml
{
    my $self = shift;
    $self->{xml} = shift if @_;
    $self->{xml};
}

sub failed_to_fetch
{
    my $self = shift @_;
    $self->{failedfetch} = shift if @_;
    $self->{failedfetch};
}

sub failed_to_parse
{
    my $self = shift @_;
    $self->{failedparse} = shift if @_;
    $self->{failedparse};
}

sub delay
{
    my $self = shift @_;
    $self->{delay} = shift if @_;
    $self->{delay};
}

sub url
{
    my $self = shift @_;
    $self->{url} = shift if @_;
    $self->{url};
}

sub headline_as_id
{
    my $self = shift @_;
    $self->{headline_as_id} = shift if @_;
    $self->{headline_as_id};
}

1;
