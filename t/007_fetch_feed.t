#!/usr/bin/perl

use Test::More tests => 9;

BEGIN { 
    use_ok( 'XML::RSS::Feed', 'loaded XML::RSS::Feed' );
    use_ok( 'XML::RSS::Headline', 'loaded XML::RSS::Headline'  );
}

SKIP: {
	eval { require LWP::Simple };

    skip "LWP::Simple not installed", 7 if $@;

	my $feed = XML::RSS::Feed->new (
	    name => 'jbisbee_test',
	    url  => "http://www.jbisbee.com/rsstest",
	);
    isa_ok ($feed, 'XML::RSS::Feed');

	my $rss_xml = LWP::Simple::get($feed->url) || undef;

    skip "Could not fetch " . $feed->url . " ... timed out", 6 unless $rss_xml;

    ok($feed->parse($rss_xml), "Failed to parse XML from " . $feed->url );

    cmp_ok($feed->num_headlines, '==', 10, "Verify correct number of headlines");
    cmp_ok($feed->late_breaking_news, '==', 0, "Verify mark_all_headlines_read");

	sleep 30;

	my $rss_xml2 = LWP::Simple::get($feed->url) || undef;

    skip "Could not fetch " . $feed->url . " ... timed out", 3 unless $rss_xml2;

    ok($feed->parse($rss_xml2), "Failed to parse XML from " . $feed->url );

    cmp_ok($feed->num_headlines, '>=', 11, "Verify correct number of headlines");
    cmp_ok($feed->late_breaking_news, '>=', 1, "Verify 1 new story");
}
    
    

