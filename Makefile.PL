use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'XML::RSS::Feed',
    VERSION_FROM => 'lib/XML/RSS/Feed.pm',
    AUTHOR       => 'Jeff Bisbee (cpan@jbisbee.com)',
    ABSTRACT     => 'Encapsulate RSS XML Sources',
    PREREQ_PM    => { 
	'XML::RSS' => 0,
	'Clone' => 0,
	'Storable' => 0,
	'Time::HiRes' => 0,
	'URI' => 0,
	'Digest::MD5' => 0,
    },
);
