#!perl

use strict;
use warnings;

use Test::More tests => 42;
use App::Maisha;
use App::Maisha::Shell;

# App::Maisha attributes

ok( my $obj = App::Maisha->new(config => 'examples/config.pl'), "got object" );

for my $k ( qw/
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

for my $k ( qw/
	services
	prompt_str
	tag_str
	order
	limit
    pager
    format
    chars
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $obj->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    eval { is( $obj->$k(), undef, "$label has no default" ) };
    eval { is( $obj->$k(123), undef, "$label set" ) };
    eval { is( $obj->$k, 123, "$label get" ) };
  };
}

