#!/usr/bin/perl

use Test::More tests => 8;

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
my $des      = "Description number 1";


my $rss = {
    channel => {
	title => "Channel Title",
	link  => "http://www.google.com/",
    },
    items => [],
};

for my $i (1 .. $iterations) {
    push @{$rss->{items}}, {
	headline    => ++$title,
	url         => ++$url,
	description => ++$des,
    };
}

$feed->pre_process;
$feed->title($rss->{channel}{title});
$feed->link($rss->{channel}{link});
$feed->process_items($rss->{items},$rss->{channel}{title},$rss->{channel}{link});
$feed->post_process;

cmp_ok($feed->num_headlines, '==', $iterations, "Verify num_headlines $iterations");
cmp_ok($feed->late_breaking_news, '==', 0, "Verify mark_all_headlines_read");

cmp_ok($feed->title, 'eq', $rss->{channel}{title}, "Verify feed title");
cmp_ok($feed->link, 'eq', $rss->{channel}{link}, "Verify feed link");
