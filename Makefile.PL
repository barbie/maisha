use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'App::Maisha',
    VERSION_FROM        => 'lib/App/Maisha.pm',
    PREREQ_PM           => {
        'Class::Accessor::Fast' => '0',
        'Config::Any'           => '0',
        'Module::Pluggable'     => '2.7',
        'Net::Twitter'          => '2.06',
        'Term::Shell'           => '0',

        'File::HomeDir'         => '0',     # used by maisha script
        'FindBin'               => '0',     # used by maisha script
        'Getopt::Long'          => '0',     # used by maisha script
        'Pod::Usage'            => '0',     # used by maisha script

        'Test::More'            => '0.47',  # testing only
    },
	NO_META			    => 1,
    EXE_FILES           => ['script/maisha'],

    ($] >= 5.005 ?
        (ABSTRACT       => 'A command line social micro-blog networking tool.',
         AUTHOR         => 'Barbie <barbie@cpan.org>') : ()),
);
