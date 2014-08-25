#!/usr/bin/perl -w
use strict;

use Test::More tests => 66;
use App::Maisha;
use App::Maisha::Shell;

my $CONFIG = {
    'CONFIG' => {
        'order' => 'asc',
        'tag' => 'tag:',
        'prompt' => 'prompt:'
    }
};

# App::Maisha configuration

{
    my $config = 't/data/config.ini';
    ok( my $app = App::Maisha->new(config => $config), "got object" );

    #use Data::Dumper;
    #diag(Dumper($app->config));

    is_deeply($app->config,$CONFIG,   'loaded config file');
    is($app->shell->prompt_str, 'prompt: ',     'correct prompt string');
    is($app->shell->tag_str,    'tag:',         'correct tag string');
    is($app->shell->pager,      '1',            'correct pager');
    is($app->shell->order,      'asc',          'correct order');
    is($app->shell->limit,      '0',            'correct character limit');
    is($app->shell->chars,      '80',           'correct character wrap');
    is($app->shell->format,     '[%U] %M',      'correct format string');
    is($app->shell->debug,      '0',            'correct debug flag');
    is($app->shell->history,    '',             'correct history setting');
}

{
    ok( my $app = App::Maisha->new(config => $CONFIG), "got object" );

    is_deeply($app->config,$CONFIG,   'loaded config file');
    is($app->shell->prompt_str, 'prompt: ',     'correct prompt string');
    is($app->shell->tag_str,    'tag:',         'correct tag string');
    is($app->shell->pager,      '1',            'correct pager');
    is($app->shell->order,      'asc',          'correct order');
    is($app->shell->limit,      '0',            'correct character limit');
    is($app->shell->chars,      '80',           'correct character wrap');
    is($app->shell->format,     '[%U] %M',      'correct format string');
    is($app->shell->debug,      '0',            'correct debug flag');
    is($app->shell->history,    '',             'correct history setting');
}

{
    my $config = 't/data/config.json';
    ok( my $app = App::Maisha->new(config => $config), "got object" );

    isnt($app->config->{CONFIG},undef,          'loaded config file');
    is($app->shell->prompt_str, 'maisha> ',     'correct prompt string');
    is($app->shell->tag_str,    '[from maisha]','correct tag string');
    is($app->shell->pager,      '1',            'correct pager');
    is($app->shell->order,      'desc',         'correct order');
    is($app->shell->limit,      '0',            'correct character limit');
    is($app->shell->chars,      '80',           'correct character wrap');
    is($app->shell->format,     '[%U] %M',      'correct format string');
    is($app->shell->debug,      '0',            'correct debug flag');
    is($app->shell->history,    '',             'correct history setting');
}

{
    my $config = 't/data/config.pl';
    ok( my $app = App::Maisha->new(config => $config), "got object" );

    isnt($app->config->{CONFIG},undef,          'loaded config file');
    is($app->shell->prompt_str, 'maisha> ',     'correct prompt string');
    is($app->shell->tag_str,    '[from maisha]','correct tag string');
    is($app->shell->pager,      '1',            'correct pager');
    is($app->shell->order,      'descending',   'correct order');
    is($app->shell->limit,      '0',            'correct character limit');
    is($app->shell->chars,      '80',           'correct character wrap');
    is($app->shell->format,     '[%U] %M',      'correct format string');
    is($app->shell->debug,      '0',            'correct debug flag');
    is($app->shell->history,    '',             'correct history setting');
}

{
    my $config = 't/data/config.xml';
    ok( my $app = App::Maisha->new(config => $config), "got object" );

    isnt($app->config->{CONFIG},undef,          'loaded config file');
    is($app->shell->prompt_str, 'maisha> ',     'correct prompt string');
    is($app->shell->tag_str,    '',             'correct tag string');
    is($app->shell->pager,      '1',            'correct pager');
    is($app->shell->order,      'descending',   'correct order');
    is($app->shell->limit,      '0',            'correct character limit');
    is($app->shell->chars,      '80',           'correct character wrap');
    is($app->shell->format,     '[%U] %M',      'correct format string');
    is($app->shell->debug,      '1',            'correct debug flag');
    is($app->shell->history,    'history.log',  'correct history setting');
}

{
    my $config = 't/data/config.yml';
    ok( my $app = App::Maisha->new(config => $config), "got object" );

    isnt($app->config->{CONFIG},undef,          'loaded config file');
    is($app->shell->prompt_str, 'maisha> ',     'correct prompt string');
    is($app->shell->tag_str,    '',             'correct tag string');
    is($app->shell->pager,      '0',            'correct pager');
    is($app->shell->order,      'descending',   'correct order');
    is($app->shell->limit,      '100',          'correct character limit');
    is($app->shell->chars,      '72',           'correct character wrap');
    is($app->shell->format,     '[%t,%U] %M',   'correct format string');
    is($app->shell->debug,      '0',            'correct debug flag');
    is($app->shell->history,    '',             'correct history setting');
}

