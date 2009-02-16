use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'App::Maisha',
    VERSION_FROM        => 'lib/App/Maisha.pm',
    PREREQ_PM           => {
        'Config::Any'       => '0',
        'Module::Pluggable' => '2.7',
        'Net::Twitter'      => '2.06',
        'Term::Shell'       => '0',

        'Test::More'        => '0.47',  # testing only
    },
	NO_META			    => 1,
    EXE_FILES           => ['script/maisha'],

    ($] >= 5.005 ?
        (ABSTRACT_FROM  => 'lib/App/Maisha.pm',
         AUTHOR         => 'Barbie <barbie@cpan.org>') : ()),
);
