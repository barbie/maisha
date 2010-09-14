package App::Maisha::Plugin::Identica;

use strict;
use warnings;

our $VERSION = '0.15';

#----------------------------------------------------------------------------
# Library Modules

use base qw(App::Maisha::Plugin::Base);
use base qw(Class::Accessor::Fast);
use File::Path;
use Net::Twitter;
use Storable;

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(api users);

#----------------------------------------------------------------------------
# Public API

#http://identi.ca/settings/oauthapps/show/185

sub new {
    my $class = shift;
    my $self = {
        consumer_key    => 'fb8163dcdb32e6c8e60734e961187553',
        consumer_secret => '8251970fb08ea39a90f6b494e3a2aabc',
    };

    bless $self, $class;
    return $self;
}

sub login {
    my ($self,$config) = @_;

    unless($config->{username}) { warn "No username supplied\n"; return }

    my $api = Net::Twitter->new(
        traits              => [qw/API::REST OAuth/],
        consumer_key        => $self->{consumer_key},
        consumer_secret     => $self->{consumer_secret},
        identica            => 1,
        ssl                 => 1
    );

    unless($api) {
        warn "Unable to establish connection to Identica API\n";
        return 0;
    }

    # for testing purposes we don't want to login
    if(!$config->{test}) {
        my $datafile = $config->{home} . '/.maisha/identica.dat';
        my $access_tokens = eval { retrieve($datafile) } || {};

        if ( $access_tokens && $access_tokens->{$config->{username}}) {
            $api->access_token($access_tokens->{$config->{username}}->[0]);
            $api->access_token_secret($access_tokens->{$config->{username}}->[1]);
        }
        else {
            my $auth_url = $api->get_authorization_url;
            print " Authorize this application at: $auth_url\nThen, enter the PIN# provided to continue: ";

            my $pin = <STDIN>; # wait for input
            chomp $pin;

            # request_access_token stores the tokens in $nt AND returns them
            my @access_tokens = $api->request_access_token(verifier => $pin);
            $access_tokens->{$config->{username}} = \@access_tokens;

            mkpath( $config->{home} . '/.maisha' );

            # save the access tokens
            store $access_tokens, $datafile;
        }
    }

    $self->api($api);

    if(!$config->{test}) {
        print "...building user cache for Identica\n";
        $self->_build_users();
    }

    return 1;
}

sub _build_users {
    my $self = shift;
    my %users;

    my $f = $self->api->friends();
    if($f && @$f)   { for(@$f) { next unless($_); $users{$_->{screen_name}} = 1 } }
    $f = $self->api->followers();
    if($f && @$f)   { for(@$f) { next unless($_); $users{$_->{screen_name}} = 1 } }

    $self->users(\%users);
}

sub api_update {
    my $self = shift;
    $self->api->update(@_);
}

sub api_user {
    my $self = shift;
    $self->api->show_user(@_);
}

sub api_user_timeline {
    my $self = shift;
    $self->api->user_timeline(@_);
}

sub api_friends {
    my $self = shift;
    $self->api->friends();
}

sub api_friends_timeline {
    my $self = shift;
    $self->api->friends_timeline();
}

sub api_public_timeline {
    my $self = shift;
    $self->api->public_timeline();
}

sub api_followers {
    my $self = shift;
    $self->api->followers();
}

sub api_replies {
    my $self = shift;
    $self->api->replies();
}

sub api_send_message {
    my $self = shift;
    $self->api->new_direct_message(@_);
}

sub api_direct_messages_to {
    my $self = shift;
    $self->api->direct_messages();
}

sub api_direct_messages_from {
    my $self = shift;
    $self->api->sent_direct_messages();
}

1;

__END__

=head1 NAME

App::Maisha::Plugin::Identica - Maisha interface to Identi.ca

=head1 SYNOPSIS

   maisha
   maisha> use Identica
   use ok

=head1 DESCRIPTION

App::Maisha::Plugin::Identica is the gateway for Maisha to access the Identi.ca
API.

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Process Methods

=over 4

=item * login

Login to the service.

=back

=head2 API Methods

The API methods are used to interface to with the Identica API.

=over 4

=item * api_user

=item * api_user_timeline

=item * api_friends

=item * api_friends_timeline

=item * api_public_timeline

=item * api_followers

=item * api_update

=item * api_replies

=item * api_send_message

=item * api_direct_messages_to

=item * api_direct_messages_from

=back

=head1 AUTHENTICATION

As Twitter has now disabled Basic Authentication to access their API, to be 
consistent Maisha now requires that access to both Twitter and Identica uses
OAuth.

With this new method of authentication, the application will provide a URL,
which the user needs to cut-n-paste into a browser to logging in to the 
service, using your regular username/password, then 'Allow' Maisha to access 
your account. This will then allow Maisha to post to your account. You will 
then be given a PIN, which should then be entered at the prompt on the Maisha
command line.

Once you have completed authentication, the application will then store your 
access tokens permanently under your profile on your computer. Then when you
next use the application it will retrieve these access tokens automatically and
you will no longer need to register the application.

For further information please see the Identica FAQ - 
L<http://status.net/wiki/TwitterCompatibleAPI>

=head1 SEE ALSO

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

L<App::Maisha>

L<Net::Identica>

=head1 WEBSITES

=over 4

=item * Main Site: L<http://maisha.grango.org>
=item * Git Repo:  L<http://github.com/barbie/maisha/tree/master>
=item * RT Queue:  L<RT: http://rt.cpan.org/Public/Dist/Display.html?Name=App-Maisha>

=back

=head1 AUTHOR

  Copyright (c) 2009-2010 Barbie <barbie@cpan.org> for Grango.org.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  See http://www.perl.com/perl/misc/Artistic.html

=cut
