#!perl

use strict;
use warnings;

use Test::More tests => 116;
use App::Maisha::Shell;

ok( my $obj = App::Maisha::Shell->new(), "got object" );
isa_ok($obj,'App::Maisha::Shell');

foreach my $k ( qw/
    exit
    followers
    friends
    friends_timeline
    ft
    help
    pt
    public_timeline
    say
    update
    quit
    q

    replies
    re
    direct_messages
    dm
    send_message
    send
    sm
/ ){
  for my $m (qw(smry help)) {
    my $j = "${m}_$k";
    my $label = "[$j]";
    SKIP: {
      ok( $obj->can($j), "$label can" ) or skip "'$j' method missing", 2;
      isnt( $obj->$j(), undef, "$label returns something" );
      like( $obj->$j, qr/\w/, "$label returns some text" );
    }
  };
}

