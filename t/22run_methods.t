#!/usr/bin/perl -w
use strict;

use Test::More tests => (2 + 30);
use App::Maisha::Shell;

ok( my $obj = App::Maisha::Shell->new(), "got object" );
isa_ok($obj,'App::Maisha::Shell');
$obj->networks('');

for my $k ( qw/
    followers
    friends
    friends_timeline
    ft
    pt
    public_timeline
    say
    update
    replies
    re
    direct_messages
    dm
    send_message
    send
    sm
    user
    user_timeline
    ut
    follow
    unfollow

    about
    version
    debug

    help
    connect
    disconnect
    use
    exit
    quit
    q
/ ){
  for my $m (qw(run)) {
    my $j = "${m}_$k";
    my $label = "[$j]";
    SKIP: {
      ok( $obj->can($j), "$label can" );
#      or skip "'$j' method missing", 1;
#      if($k =~ /^(exit|quit|q|connect|disconnect|use|help)$/) {
#          ok(1);
#      } else {
#          eval { $obj->$j() };
#          is( $@, '' );
#      }
    }
  };
}
