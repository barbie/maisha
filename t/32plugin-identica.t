#!perl

use strict;
use warnings;

use Test::More tests => 29;
use App::Maisha::Plugin::Identica;

my $nomock;
my $mock;

BEGIN {
	eval "use Test::MockObject";
    $nomock = $@;

    unless($nomock) {
        $mock = Test::MockObject->new();
        $mock->fake_module( 'Net::Identica', 'update' => sub  { return 1; } );
        $mock->fake_new( 'Net::Identica' );

        $mock->set_true(qw(
            update
            show_user
            user_timeline
            friends
            friends_timeline
            public_timeline
            followers
            replies
            new_direct_message
            direct_messages
            sent_direct_messages
            create_friend
            destroy_friend
        ));
    }
}


SKIP: {
	skip "Test::MockObject required for plugin testing\n", 29   if($nomock);

    ok( my $obj = App::Maisha::Plugin::Identica->new(), "got object" );
    isa_ok($obj,'App::Maisha::Plugin::Identica');

    my $ret = $obj->login('Identica','blah','blah');
    is($ret, 1, '.. login done');

    my $api = $obj->api();

    for my $k ( qw/
        followers
        friends
        friends_timeline
        public_timeline
        update

        replies
        direct_messages_from
        direct_messages_to
        send_message

        user
        user_timeline
        follow
        unfollow

    / ){
      for my $m (qw(api)) {
        my $j = "${m}_$k";
        my $label = "[$j]";
        SKIP: {
          ok( $obj->can($j), "$label can" ) or skip "'$j' method missing", 2;
          isnt($obj->$j(), undef, "$label returns nothing" );
        }
      }
    }
}

