use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'XML::RSS::Feed',
    VERSION_FROM => 'lib/XML/RSS/Feed.pm',
    AUTHOR       => 'Jeff Bisbee (cpan@jbisbee.com)',
    ABSTRACT     => 'Encapsulate RSS XML Sources',
    PREREQ_PM    => { 
	'XML::RSS' => 0.97,
	'Clone' => 0.13,
    },
);
