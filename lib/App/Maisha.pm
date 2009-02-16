package App::Maisha;

use strict;
use warnings;

our $VERSION = '0.02';

#----------------------------------------------------------------------------

=head1 NAME

App::Maisha - A command line social micro-blog networking tool.

=head1 SYNOPSIS

  use App::Maisha;
  my $maisha   = App::Maisha->new(config => $file)->run;

=head1 DESCRIPTION

This distribution provides the ability to micro-blog via social networking
websites and services, such as Identica and Twitter.

=cut

#----------------------------------------------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use Carp qw(croak);
use Config::Any;
use App::Maisha::Shell;

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(shell config);

#----------------------------------------------------------------------------
# Public API

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my $config = $self->load_config(@_);
    $self->config($config);
    $self->setup();
    $self;
}

sub load_config {
    my ($self,%hash) = @_;
    my $config = $hash{config};

    if ($config && ! ref $config) {
        my $filename = $config;
        # In the future, we may support multiple configs, but for now
        # just load a single file via Config::Any
        my $list = Config::Any->load_files( { files => [ $filename ], use_ext => 1 } );
        ($config) = $list->[0]->{$filename};
    }

    croak("Could not load configuration file")  if(!$config);
    croak("Maisha expectes a config file that can be decoded to a HASH")    if(ref $config ne 'HASH');

    return $config;
}

sub setup {
    my $self   = shift;
    my $config = $self->config;
    my $shell  = $self->shell(App::Maisha::Shell->new);

    my $tag = $config->{CONFIG}{tag};
    $tag ||= '[from maisha]';
    $tag   = '' if($tag eq '.');

    my $prompt = $config->{CONFIG}{prompt};
    $prompt ||= 'maisha>';
    $prompt =~ s/\s*$/ /;

    $shell->prompt_str($prompt);
    $shell->tag_str($tag);
    $shell->order(defined $config->{CONFIG}{order} ? $config->{CONFIG}{order} : 'descending');
    $shell->limit(defined $config->{CONFIG}{limit} ? $config->{CONFIG}{limit} : 0);

    # connect to the available sites
    for my $plugin (keys %$config) {
        next    if($plugin eq 'CONFIG');
        $self->shell->connect($plugin,$config->{$plugin}{username},$config->{$plugin}{password});
    }

    # in some environments 'Wide Character' warnings are emited where unicode
    # strings are seen in status messages. This suppresses them.
    binmode STDOUT, ":utf8";

}

sub run {
    my $self  = shift;
    my $shell = $self->shell;
    $shell->postcmd();
    $shell->cmdloop();
}

1;

__END__

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Process Methods

=over 4

=item * load_config

Loads the configuration file. See the 'maisha' script to see a fuller
description of the configuration options.

=item * setup

Prepares the interface and internal environment.

=item * run

Starts the command loop shell, and awaits your command.

=back

=head1 SEE ALSO

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

See http://maisha.grango.org

=head1 AUTHOR

Copyright (c) 2009 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
