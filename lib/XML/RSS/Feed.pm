package XML::RSS::Feed;
use strict;
use XML::RSS;
use vars qw($VERSION);
$VERSION = 0.25;

=head1 NAME

XML::RSS::Feed - Encapsulate RSS XML New Items Watching

=head1 SYNOPSIS

ATTENTION! - If you want a non-blocking way to watch multiple RSS sources 
with one process.  Use POE::Component::RSSAggregator

A quick non-POE example:

  #!/usr/bin/perl -w
  use strict;
  use XML::RSS::Feed;
  use LWP::Simple;

  my %source = (
      url    => "http://www.jbisbee.com/rdf/",
      name   => "jbisbee",
      delay  => 10,
      tmpdir => "/tmp", # optional caching
  );
  my $feed = XML::RSS::Feed->new(%source);

  while (1) {
      print "Fetching " . $feed->url . "\n";
      my $rssxml = get($feed->url);
      if (my @late_breaking_news = $feed->parse($rssxml)) {
          for my $headline (@late_breaking_news) {
              print $headline->headline . "\n";
          }
      }
      # this sucks (and blocks) 
      # use the POE::Component::RSSAggregator module instead!
      sleep($feed->delay); 
  }

An example of subclassing XML::RSS::Headline

  #!/usr/bin/perl -w
  use strict;
  use XML::RSS::Feed;
  use LWP::Simple;
  use PerlJobs;

  my %source = (
      url   => http://jobs.perl.org/rss/standard.rss
      hlobj => PerlJobs
      title => jobs.perl.org
      name  => perljobs
      delay => 1800
  );
  my $feed = XML::RSS::Feed->new(%source);

  while (1) {
      print "Fetching " . $feed->url . "\n";
      my $rssxml = get($feed->url);
      if (my @late_breaking_news = $feed->parse($rssxml)) {
          for my $headline (@late_breaking_news) {
              print $headline->headline . "\n";
          }
      }
      sleep($feed->delay);
  }

and here is PerlJobs.pm which is subclassed from XML::RSS::Headline in
this example.

  package PerlJobs;
  use strict;
  use XML::RSS::Feed;
  use base qw(XML::RSS::Headline);

  sub headline
  {
      my ($self) = @_;
      my $sub_hash = $self->{item}{'http://jobs.perl.org/rss/'};
      return $self->{item}{title} . "\n" . $sub_hash->{company_name} . 
	  " - " . $sub_hash->{location} . "\n" .  $sub_hash->{hours} . 
	  ", " . $sub_hash->{employment_terms};
  }

  1;

This can pull other info from the item block into your headline.  Here
is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

  <rssbot> -- jobs.perl.org (http://jobs.perl.org/)
  <rssbot>  + Part Time Perl
  <rssbot>    Brian Koontz - United States, TX, Dallas
  <rssbot>    Part time, Independent contractor (project-based)
  <rssbot>    http://jobs.perl.org/job/950

=head1 AUTHOR

Jeff Bisbee
CPAN ID: JBISBEE
cpan@jbisbee.com
http://search.cpan.org/author/JBISBEE/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<POE::Component::RSSAggregator>

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
    $self->_load_cached_headlines if $self->{tmpdir};
    $self->{delay} = 600 unless $self->{delay};
    return $self;
}

sub _load_cached_headlines
{
    my ($self) = @_;
    if ($self->{tmpdir}) {
	my $filename = $self->{tmpdir} . '/' . $self->name;
	if (-T $filename) {
	    open(my $fh, $filename);
	    my $xml = do { local $/, <$fh> };
	    close $fh;
	    warn "[$self->{name}] Loaded Cached RSS XML\n" if $self->{debug};
	    $self->parse($xml);
	}
	else {
	    warn "[$self->{name}] !! Failed to Load Cached RSS XML\n" if $self->{debug};
	}
    }
}

sub parse
{
    my ($self,$xml) = @_;
    $self->{xml} = $xml;
    my $rss_parser = XML::RSS->new();
    eval {
	$rss_parser->parse($xml);
    };
    if ($@) {
	warn "[$self->{name}] !! Failed to parse RSS XML -> $@\n" if $self->debug;
	$self->failed_to_parse(1);
	return 0;
    }
    else {
	warn "[$self->{name}] Parsed RSS XML\n" if $self->debug;
	$self->title($rss_parser->{channel}->{title});
	$self->link($rss_parser->{channel}->{link});
	$self->_process_items($rss_parser->{items});
	return 1;
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
    my $hlobj = $self->{hlobj} || "XML::RSS::Headline";
    if ($items) {
	my @late_breaking_news = ();
	# the $seen variable fixes and issue where a headline is 
	# added and removed and the very last headline appears as 
	# new.  $seen sets a flag that once old headlines are found
	# in the items array, there cant be any new ones.
	my $seen = 0;
	my @headlines = map { 
	    my $headline = $hlobj->new(
		#feed           => $self, # why oh why did I do this?!?
		item           => $_,
		headline_as_id => $self->headline_as_id,
	    );
	    # init is used so that we just load the current headlines
	    # and don't return all headlines.  in other words
	    # we initialize them
	    unless ($self->seen_headline($headline->id) || 
		    $seen || !$self->init) {
		push @late_breaking_news, $headline 
	    }
	    $seen = 1 if $self->seen_headline($headline->id); 
	    $headline;
	} @$items;

	$self->init(1);
	$self->late_breaking_news(\@late_breaking_news);
	$self->headlines(\@headlines);

	# turn on 'debug' to figure things out
	warn "[$self->{name}] " . @headlines . " Headlines Found\n" if $self->debug;
	warn "[$self->{name}] " . @late_breaking_news . " New Headlines Found\n" if $self->debug;
    }
    else {
	warn "[$self->{name}] !! No Headlines Found\n" if $self->debug;
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
	'300'  => '5 minutes',
	'600'  => '10 minutes',
	'900'  => '15 minutes',
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

sub late_breaking_news
{
    my $self = shift;
    $self->{late_breaking_news} = shift if @_;
    $self->{late_breaking_news} = [] unless $self->{late_breaking_news};
    return wantarray ? @{$self->{late_breaking_news}} : 
	scalar @{$self->{late_breaking_news}};
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

sub hlobj
{
    my $self = shift @_;
    $self->{hlobj} = shift if @_;
    $self->{hlobj};
}

sub tmpdir
{
    my $self = shift @_;
    $self->{tmpdir} = shift if @_;
    $self->{tmpdir};
}

sub DESTROY
{
    my $self = shift;
    return unless $self->tmpdir;
    if (-d $self->tmpdir && $self->{xml}) {
	my $tmp_filename = $self->tmpdir . '/' . $self->{name};
	if (open(my $fh, ">$tmp_filename")) {
	    print $fh $self->{xml};
	    close $fh;
	    warn "[$self->{name}] Cached RSS XML to $tmp_filename\n" if $self->debug;
	}
	else {
	    warn "[$self->{name}] Could not cache RSS XML to $tmp_filename\n" if $self->debug;
	}
    }
}


package XML::RSS::Headline;
use strict;
use Digest::MD5 qw(md5_base64);
use URI;
use Clone qw(clone);
use vars qw($VERSION);
$VERSION = 0.10;

sub new
{
    my $class = shift @_;
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
    return $self;
}

sub _generate_id
{
    my ($self) = @_;
    # to many problems with urls not staying the same within a source
    # www.debianplanet.org || debianplanet.org
    # search.cpan.org || search.cpan.org:80
    #$self->{id} = md5_base64($self->url . $self->headline);

    # just using headline
    if ($self->headline_as_id) {
	$self->{id} = md5_base64($self->{item}->headline);
    }
    else {
	$self->{id} = $self->{item}->{link};
    }
}

sub id
{
    my ($self) = shift @_;
    return $self->{id};
}

sub headline
{
    my ($self) = @_;
    return $self->{item}->{title};
}

sub multiline_headline
{
    my ($self) = @_;
    my @multiline_headlines = split /\n/, $self->headline;
    return \@multiline_headlines;
}

sub url
{
    my ($self) = @_;
    return $self->{item}->{link};
}

sub headline_as_id
{
    my $self = shift @_;
    $self->{headline_as_id} = shift if @_;
    $self->{headline_as_id};
}

sub item
{
    my ($self,$item) = @_;
    if ($item) {
	$self->{item} = clone $item;
	$self->{item}->{link} = URI->new($self->{item}->{link})->canonical;
	$self->_generate_id;
    }
    $self->{item};
}

# No idea why this is here
#sub feed
#{
#    my $self = shift @_;
#    $self->{feed} = shift if @_;
#    $self->{feed};
#}

1;
