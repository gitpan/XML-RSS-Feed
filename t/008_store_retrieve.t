#!/usr/bin/perl

use Test::More tests => 19;

BEGIN { 
    use_ok( 'XML::RSS::Feed', 'loaded XML::RSS::Feed' );
    use_ok( 'XML::RSS::Headline', 'loaded XML::RSS::Headline'  );
}


SKIP: {
    skip "/tmp directory doesn't exist", 17 unless -d "/tmp";

    eval { require LWP::Simple };

    skip "LWP::Simple not installed", 17 if $@;

    unlink "/tmp/test_008.sto";
    my $feed = XML::RSS::Feed->new (
	name   => 'test_008',
	url    => "http://www.jbisbee.com/rsstest",
	tmpdir => "/tmp",
    );

    isa_ok ($feed, 'XML::RSS::Feed');

    my $rss_xml = LWP::Simple::get($feed->url) || undef;

    skip "Could not fetch " . $feed->url . " ... timed out", 16 unless $rss_xml;
    ok($feed->parse($rss_xml), "Failed to parse XML from " . $feed->url );
    cmp_ok($feed->num_headlines, '==', 10, "Verify correct number of headlines");
    cmp_ok($feed->late_breaking_news, '==', 0, "Verify mark_all_headlines_read");

    my @headlines_old = map { $_->headline } $feed->headlines;
    my $num_headlines = $feed->num_headlines;
    my @seen_old = map { $_->first_seen_hires } $feed->headlines;
    undef $feed;
    $feed2 = XML::RSS::Feed->new (
	name   => 'test_008',
	url    => "http://www.jbisbee.com/rsstest",
	tmpdir => "/tmp",
    );
    isa_ok ($feed2, 'XML::RSS::Feed');
    cmp_ok($num_headlines, '==', $feed2->num_headlines, "Compare after restoring cache");

    unlink "/tmp/test_008.sto";
    my @headlines_new = map { $_->headline } $feed2->headlines;
    my @seen_new = map { $_->first_seen_hires } $feed2->headlines;

    ok(eq_array(\@headlines_old,\@headlines_new), "Comparing headlines before and after");

    for my $i (0..$#seen_old) {
	my $num = $i + 1;
	cmp_ok($seen_old[$i], '==', $seen_new[$i], "Compare headline $num timestamp_hires");
    }
    undef $feed2
}
