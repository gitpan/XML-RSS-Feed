package XML::RSS::Feed::Headline;
use strict;
use Digest::MD5 qw(md5_base64);
use URI;

BEGIN {
    use vars qw ($VERSION);
    $VERSION     = 0.01;
}

=head1 NAME

XML::RSS::Feed::Headline - Encapsulate RSS Items

=head1 SYNOPSIS

  use XML::RSS::Feed::Headline
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Jeff Bisbee
	CPAN ID: JBISBEE
	cpan@jbisbee.com
	http://www.jbisbee.com/perl/modules/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

sub new
{
    my $class = shift @_;
    my $self = bless {}, $class;
    my %args = @_;
    foreach my $method (keys %args) {
	if ($self->can($method)) {
	    $self->$method($args{$method})
	}
	else {
	    die "Invalid argument '$method'";
	}
    }
    $self->_generate_id if $self->headline && $self->url;
    return $self;
}

sub _generate_id
{
    my ($self) = @_;
    # to many problems with urls not staying the same within a source
    # www.debianplanet.org || debianplanet.org
    # search.cpan.org || search.cpan.org:80
    #$self->{id} = md5_base64($self->url . $self->headline);

    # just using headline
    if ($self->headline_as_id) {
	$self->{id} = md5_base64($self->headline);
    }
    else {
	$self->{id} = $self->url;
    }
}

sub id
{
    my ($self) = shift @_;
    return $self->{id};
}

sub headline
{
    my ($self,$headline) = @_;
    if ($headline) {
	$self->{headline} = $headline;
	$self->_generate_id if $self->headline_as_id
    }
    return $self->{headline};
}

sub multiline_headline
{
    my ($self) = @_;
    my @multiline_headlines = split /\n/, $self->headline;
    return \@multiline_headlines;
}

sub url
{
    my ($self,$url) = @_;
    if ($url) {
	# hack to fix debian planet and CPAN urls
	# they sometims have :80 in the URL
	$self->{url} = URI->new($url)->canonical;
	$self->_generate_id unless $self->headline_as_id;
    }
    return $self->{url};
}

sub headline_as_id
{
    my $self = shift @_;
    $self->{headline_as_id} = shift if @_;
    $self->{headline_as_id};
}

sub item
{
    my $self = shift @_;
    $self->{item} = shift if @_;
    $self->{item};
}

sub feed
{
    my $self = shift @_;
    $self->{feed} = shift if @_;
    $self->{feed};
}

1;
