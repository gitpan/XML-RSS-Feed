package XML::RSS::Feed::Factory;
use XML::RSS::Feed;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = 0.03;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(feed_factory);
@EXPORT_OK = qw(feed_factory);

=head1 NAME

XML::RSS::Feed::Factory - Automate XML::RSS::Feed generation

=head1 SYNOPSIS

  use XML::RSS::Feed::Factory;
  my @feeds = (
      {
          url   => "http://www.jbisbee.com/rdf/",
          name  => "jbisbee",
          delay => 10,
          debug => 1,
      },
      {
          url   => "http://lwn.net/headlines/rss",
          name  => "lwn",
          delay => 300,
          debug => 1,
      },
  );
  my @feed_objs = feed_factory(@feeds);

=head1 DESCRIPTION

Object factory to create XML::RSS::Feed factory.

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

L<POE::Component::RSSAggregator>, L<XML::RSS::Feed> 

=cut

sub feed_factory 
{
    my (@feeds) = @_;
    @feeds = @{$feeds[0]} if ref $feeds[0] eq "ARRAY";
    my @feed_objs = ();
    for my $hash (@feeds) {
	die "expecting hash ref" unless ref $hash eq "HASH";
	my $obj = $hash->{obj} || "XML::RSS::Feed";
	push @feed_objs, $obj->new(%$hash);
    }
    return @feed_objs;
}

1;
