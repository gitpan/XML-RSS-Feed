package XML::RSS::Feed::Factory;
use XML::RSS::Feed;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION     = 0.01;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(feed_factory);
@EXPORT_OK = qw(feed_factory);

sub feed_factory 
{
    my (@feeds) = @_;
    @feeds = @{$feeds[0]} if ref $feeds[0] eq "ARRAY";
    my @feed_objs = ();
    for my $hash (@feeds) {
	my $obj = $hash->{obj} || "XML::RSS::Feed";
	push @feed_objs, $obj->new(%$hash);
    }
    return @feed_objs;
}

1;
