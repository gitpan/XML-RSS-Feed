#!/usr/bin/perl

use Test::More tests => 107;

BEGIN { 
    use_ok( 'XML::RSS::Feed', 'loaded XML::RSS::Feed' );
    use_ok( 'XML::RSS::Headline', 'loaded XML::RSS::Headline'  );
}

my $max_headlines = 5;
my $iterations = 100;
my $title    = "This is a test 1";
my $url      = "http://www.jbisbee.com/test/url/1";
cmp_ok($max_headlines, "<", $iterations, "Max headlines must be less than iterations");

my $feed = XML::RSS::Feed->new (
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
    max_headlines => $max_headlines,
);
isa_ok ($feed, 'XML::RSS::Feed');

my $headline = XML::RSS::Headline->new(
    url      => "http://www.jbisbee.com/testurl/1",
    headline => "Test Headline",
);
isa_ok ($headline, 'XML::RSS::Headline');

$feed->pre_process();

my @headlines = ();
for my $i (1 .. $iterations) {
    my %hash = (
	headline => ++$title,
	url      => ++$url,
    );
    push @headlines, $hash{headline};
    $feed->create_headline(%hash);
    cmp_ok($feed->num_headlines, '<=', $max_headlines, "Verify max_headlines $i");
}
$feed->post_process();
cmp_ok($feed->num_headlines, '==', $max_headlines, "Verify max_headlines");

@headlines = splice(@headlines,-$max_headlines,$max_headlines);

my @headlines2 = map { $_->headline } $feed->headlines;

ok(eq_array(\@headlines,\@headlines2),"Comparing before and after headlines");
