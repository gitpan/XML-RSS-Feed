#!/usr/bin/perl

use Test::More tests => 6;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new (
    url   => "http://www.jbisbee.com/rdf/",
    name  => 'jbisbee',
);
isa_ok ($feed, 'XML::RSS::Feed');

$SIG{__WARN__} = build_warn("deprecated");
cmp_ok($feed->failed_to_fetch, 'eq', "", "Verify that failed_to_fetch returns ''");
cmp_ok($feed->failed_to_parse, 'eq', "", "Verify that failed_to_parse returns ''");

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like($warn, qr/$_/i, $_) for @args };
}

