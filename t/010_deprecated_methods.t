#!/usr/bin/perl

use Test::More tests => 5;

BEGIN { 
    use_ok( 'XML::RSS::Feed', 'loaded XML::RSS::Feed' );
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
cmp_ok($feed->failed_to_fetch, 'eq', "", "Verify that failed_to_fetch returns ''");
cmp_ok($feed->failed_to_parse, 'eq', "", "Verify that failed_to_parse returns ''");

