#!perl

use strict;
use warnings;

use Test::More tests => 30;
use App::Maisha;
use App::Maisha::Shell;

# App::Maisha attributes

ok( my $obj = App::Maisha->new(config => 't/data/config.yml'), "got object" );

foreach my $k ( qw/
	shell
	config
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $obj->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    isnt( $obj->$k(), undef, "$label has default" );
    is( $obj->$k(123), 123, "$label set" );
    is( $obj->$k, 123, "$label get" );
  };
}


# App::Maisha::Shell attributes

ok( $obj = App::Maisha::Shell->new(), "got object" );

foreach my $k ( qw/
	services
	prompt_str
	tag_str
	order
	limit
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $obj->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    is( $obj->$k(), undef, "$label has no default" );
    is( $obj->$k(123), undef, "$label set" );
    is( $obj->$k, 123, "$label get" );
  };
}

