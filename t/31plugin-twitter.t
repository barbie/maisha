#!perl

use strict;
use warnings;

use Test::More tests => 29;
use App::Maisha::Plugin::Twitter;

my $nomock;
my $mock;

BEGIN {
	eval "use Test::MockObject";
    $nomock = $@;

    unless($nomock) {
        $mock = Test::MockObject->new();
        $mock->fake_module( 'Net::Twitter', 'update' => sub  { return 1; },  get_authorization_url => sub { return 'http://127.0.0.1' } );
        $mock->fake_new( 'Net::Twitter' );

        $mock->set_true(qw(
            update
            show_user
            user_timeline
            friends_timeline
            public_timeline
            replies
            new_direct_message
            direct_messages
            sent_direct_messages
            create_friend
            destroy_friend

            access_token
            access_token_secret
            get_authorization_url
            request_access_token
        ));

        $mock->set_list('friends',   ());
        $mock->set_list('followers', ());
    }
}


SKIP: {
	skip "Test::MockObject required for plugin testing\n", 29   if($nomock);

    ok( my $obj = App::Maisha::Plugin::Twitter->new(), "got object" );
    isa_ok($obj,'App::Maisha::Plugin::Twitter');

    my $ret = $obj->login({ username => 'test', home => '.', test => 1 });
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

