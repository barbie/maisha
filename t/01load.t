use strict;
use Test::More (tests => 5);

BEGIN
{
    use_ok("App::Maisha");
    use_ok("App::Maisha::Shell");
    use_ok("App::Maisha::Plugin::Base");
    use_ok("App::Maisha::Plugin::Identica");
    use_ok("App::Maisha::Plugin::Twitter");
}

1;