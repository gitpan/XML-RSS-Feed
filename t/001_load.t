#!/usr/bin/perl

use Test::More tests => 4;

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

