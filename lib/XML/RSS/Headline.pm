package XML::RSS::Headline;
use strict;
use Digest::MD5 qw(md5_base64);
use Encode qw(encode_utf8);
use URI;
use Time::HiRes;
use HTML::Entities;
use constant DESCRIPTION_HEADLINE => 45; # length of headline when from description

our $VERSION = 2.00;

=head1 NAME

XML::RSS::Headline - Persistant XML RSS Encapsulation

=head1 SYNOPSIS

Headline object to encapsulate the headline/URL combination of a RSS feed.  It
provides a unique id either by way of the URL or by doing an MD5 checksum on the 
headline (when URL uniqueness fails).

=head1 CONSTRUCTOR

=over 4

=item B<C<< XML::RSS::Headline->new( headline =E<gt> $headline, url =E<gt> $url ) >>>

=item B<C<< XML::RSS::Headline->new( item =E<gt> $item ) >>>

A XML::RSS::Headline object can be initialized either with headline/url or 
with a parse XML::RSS item structure.  The argument 'headline_as_id' is 
optional and takes a boolean as its value.

=back

=cut 

sub new {
    my $class = shift @_;
    my $self = bless {}, $class;
    my %args = @_;
    my $first_seen = $args{first_seen};
    my $headline_as_id = $args{headline_as_id} || 0;
    delete $args{first_seen} if exists $args{first_seen};
    delete $args{headline_as_id} if exists $args{headline_as_id};

    if ($args{item}) {
	unless (($args{item}->{title} || $args{item}->{description}) && $args{item}->{link}) {
	    warn "item must contain either title/link or description/link";
	    return;
	}
    }
    else {
	unless ($args{url} && ($args{headline} || $args{description})) {
	    warn 'Either item, url/headline. or url/description are required';
	    return;
	}
    }

    $self->headline_as_id($headline_as_id);

    for my $method (keys %args) {
	if ($self->can($method)) {
	    $self->$method($args{$method})
	}
	else {
	    warn "Invalid argument: '$method'";
	}
    }

    unless ($self->headline) {
	warn "Failed to set headline";
	return;
    }

    $self->set_first_seen($first_seen);
    return $self;
}


=head1 METHODS

=over 4

=item B<C<< $headline->id >>>

The id is our unique identifier for a headline/url combination.  Its how we 
can keep track of which headlines we have seen before and which ones are new.
The id is either the URL or a MD5 checksum generated from the headline text 
(if B<$headline-E<gt>headline_as_id> is true);

=cut 

sub id {
    my ($self) = shift @_;
    return $self->{_rss_headline_id} if $self->headline_as_id;
    return $self->url;
}

sub _cache_id {
    my ($self) = @_;
    $self->{_rss_headline_id} = md5_base64(encode_utf8($self->{safe_headline}))
	if $self->{safe_headline}; 
}

=item B<C<< $headline->multiline_headline >>>

This method returns the headline as either an array or array 
reference based on context.  It splits headline on newline characters 
into the array.

=cut 

sub multiline_headline {
    my ($self) = @_;
    my @multiline_headline = split /\n/, $self->headline;
    return wantarray ? @multiline_headline : \@multiline_headline;
}

=item B<C<< $headline->item( $item ) >>>

Init the object for a parsed RSS item returned by L<XML::RSS>.

=cut 

sub item {
    my ($self,$item) = @_;
    return unless $item;
    $self->url($item->{link});
    $self->headline($item->{title});
    $self->description($item->{description});
}

=item B<C<< $headline->set_first_seen >>>

=item B<C<< $headline->set_first_seen( Time::HiRes::time() ) >>>

Set the time of when the headline was first seen.  If you pass in a value
it will be used otherwise calls Time::HiRes::time().

=cut

sub set_first_seen {
    my ($self,$hires_time) = @_;
    $self->{hires_timestamp} = $hires_time;
    $self->{hires_timestamp} = Time::HiRes::time() unless $hires_time;
    return 1;
}

=item B<C<< $headline->first_seen >>>

The time (in epoch seconds) of when the headline was first seen.

=cut

sub first_seen {
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

=item B<C<< $headline->first_seen_hires >>>

The time (in epoch seconds and milliseconds) of when the headline was first seen.

=back

=cut

sub first_seen_hires {
    my ($self) = @_;
    return $self->{hires_timestamp};
}

=head1 GET/SET ACCESSOR METHODS

=over 4

=item B<C<< $headline->headline >>>

=item B<C<< $headline->headline( $headline ) >>>

The rss headline/title.  HTML::Entities::decode_entities is used when the
headline is set.  (not sure why XML::RSS doesn't do this)

=cut 

sub headline {
    my ($self,$headline) = @_;
    if ($headline) {
	$self->{headline} = decode_entities $headline;
	$self->{headline} = $headline;
	if ($self->{headline_as_id}) {
	    $self->{safe_headline} = $headline;
	    $self->_cache_id; 
	}
    }
    return $self->{headline};
}

=item B<C<< $headline->url >>>

=item B<C<< $headline->url( $url ) >>>

The rss link/url.  URI->canonical is called to attempt to normalize the URL

=cut 

sub url {
    my ($self,$url) = @_;
    # clean the URL up a bit
    $self->{url} = URI->new($url)->canonical if $url;
    return $self->{url};
}

=item B<C<< $headline-E<gt>description >>>

=item B<C<< $headline-E<gt>description( $description ) >>>

The description of the RSS headline.

=cut 

sub description {
    my ($self,$description) = @_;
    if ($description) {
	$self->{description} = decode_entities $description;
	$self->_description_headline unless $self->headline;
    }
    return $self->{description};
}

sub _description_headline {
    my ($self) = @_;
    my $punctuation = qr/[\.\,\?\!\:\;]+/s;

    my $description = $self->{description};
    $description =~ s/<br *\/*>/\n/g; # turn br into newline
    $description =~ s/<.+?>/ /g;

    my $headline = (split $punctuation, $description)[0] || "";
    $headline =~ s/^\s+//;
    $headline =~ s/\s+$//;

    my $build_headline = "";
    for my $word (split /\s+/, $headline) {
	$build_headline .= " " if $build_headline;
	$build_headline .= $word;
	last if length $build_headline > DESCRIPTION_HEADLINE;
    }

    return unless $build_headline;
    $self->headline($build_headline .= '...');
}

=item B<C<< $headline->headline_as_id >>>

=item B<C<< $headline->headline_as_id( $bool ) >>>

A bool value that determines whether the URL will be the unique identifier or 
the if an MD5 checksum of the RSS title will be used instead.  (when the URL
doesn't provide absolute uniqueness or changes within the RSS feed) 

This is used in extreme cases when URLs aren't always unique to new healines
(Use Perl Journals) and when URLs change within a RSS feed (www.debianplanet.org / 
debianplanet.org / search.cpan.org,search.cpan.org:80)

=cut 

sub headline_as_id {
    my ($self,$bool) =  @_;
    if (defined $bool) {
	$self->{headline_as_id} = $bool;
	$self->_cache_id;
    }
    $self->{headline_as_id};
}

=item B<C<< $headline->timestamp >>>

=item B<C<< $headline->timestamp( Time::HiRes::time() ) >>>

A high resolution timestamp that is set using Time::HiRes::time() when the 
object is created.

=cut 

sub timestamp {
    my ($self,$timestamp) = @_;
    $self->{timestamp} = $timestamp if $timestamp;
    return $self->{timestamp};
}

=back

=head1 AUTHOR

Copyright 2004 Jeff Bisbee <jbisbee@cpan.org>

http://search.cpan.org/~jbisbee/

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<POE::Component::RSSAggregator>

=cut

1;