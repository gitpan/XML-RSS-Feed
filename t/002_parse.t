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

my $slashdot_rss1 = qq|<?xml version="1.0" encoding="ISO-8859-1"?>

<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>Slashdot</title>
<link>http://slashdot.org/</link>
<description>News for nerds, stuff that matters</description>
</channel>

<image>
<title>Slashdot</title>
<url>http://images.slashdot.org/topics/topicslashdot.gif</url>
<link>http://slashdot.org/</link>
</image>

<item>
<title>XPde 0.5 - A Linux Desktop for Windows Users</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2322233</link>
</item>

<item>
<title>Canadian Minister Promises to Fix Copyright Law</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2317226</link>
</item>

<item>
<title>Grand Challenge Videos Posted</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2115226</link>
</item>

<item>
<title>Make Your Own TRON Costume</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/1722215</link>
</item>

<item>
<title>Gates on Winsecurity</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2112235</link>
</item>

<item>
<title>Automobiles Evolve to Live Up to Their Name</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2056208</link>
</item>

<item>
<title>Red Hat Recap</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/2047250</link>
</item>

<item>
<title>ICANN Cracks Down on Invalid WHOIS Data</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/1726226</link>
</item>

<item>
<title>Little Robots Play Soccer</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/1724217</link>
</item>

<item>
<title>NASA Gravity Probe Set for Launch</title>
<link>http://slashdot.org/article.pl?sid=04/04/03/1716234</link>
</item>

<textinput>
<title>Search Slashdot</title>
<description>Search Slashdot stories</description>
<name>query</name>
<link>http://slashdot.org/search.pl</link>
</textinput>

</rdf:RDF>|;

my $slashdot_rss2 = qq|<?xml version="1.0" encoding="ISO-8859-1"?>

<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>Slashdot</title>
<link>http://slashdot.org/</link>
<description>News for nerds, stuff that matters</description>
</channel>

<image>
<title>Slashdot</title>
<url>http://images.slashdot.org/topics/topicslashdot.gif</url>
<link>http://slashdot.org/</link>
</image>

<item>
<title>States Link Databases to Find Tax Cheats</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/2021256</link>
</item>

<item>
<title>Invulnerable, Waterproof PDA</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1814258</link>
</item>

<item>
<title>Still More on Open Source Usability</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1811226</link>
</item>

<item>
<title>Moore's Law Limits Pushed Back Again</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/182224</link>
</item>

<item>
<title>Advanced Mobile Phone Tech in Japan</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1754231</link>
</item>

<item>
<title>Computerized Time Clocks Susceptible to 'Manager Attack'</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1655231</link>
</item>

<item>
<title>A Completely Separate Ecosystem on Earth</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1653233</link>
</item>

<item>
<title>3D, FPS File Manager</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1621251</link>
</item>

<item>
<title>Searching by Shape...</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1423210</link>
</item>

<item>
<title>New Wave of Web Ads?</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1410251</link>
</item>

<textinput>
<title>Search Slashdot</title>
<description>Search Slashdot stories</description>
<name>query</name>
<link>http://slashdot.org/search.pl</link>
</textinput>

</rdf:RDF>|;

$feed->parse($slashdot_rss1);
cmp_ok($feed->num_headlines, '==', 10, "Verify 10 Slashdot headlines");
cmp_ok($feed->late_breaking_news, '==', 0, "Verify 0 new headlines");
$feed->parse($slashdot_rss2);
cmp_ok($feed->num_headlines, '==', 20, "Verify 20 Slashdot headlines");
cmp_ok($feed->late_breaking_news, '==', 10, "Verify 10 new headlines");

