#!/usr/bin/perl

use Test::More tests => 5;

BEGIN { 
    use_ok( 'XML::RSS::Feed', 'loaded XML::RSS::Feed' );
    use_ok( 'XML::RSS::Headline', 'loaded XML::RSS::Headline'  );
}

my $feed = XML::RSS::Feed->new (
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
);
isa_ok ($feed, 'XML::RSS::Feed');

my $headline = XML::RSS::Headline->new(
    url      => "http://www.jbisbee.com/testurl/1",
    headline => "Test Headline",
);
isa_ok ($headline, 'XML::RSS::Headline');

my $iterations = 100;
my $title    = "This is a test 1";
my $url      = "http://www.jbisbee.com/test/url/1";

$feed->pre_process();
for my $i (1 .. $iterations) {
    $feed->create_headline(
	headline => ++$title,
	url      => ++$url,
    );
}
$feed->post_process();

my @headlines = $feed->headlines;
my @sorted_headlines = sort { $a->first_seen_hires <=> $b->first_seen_hires } $feed->headlines;

ok(eq_array(\@headlines,\@sorted_headlines),"Validate first_seen_hires");
