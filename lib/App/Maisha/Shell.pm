package App::Maisha::Shell;

use strict;
use warnings;

our $VERSION = '0.16';

#----------------------------------------------------------------------------

=head1 NAME

App::Maisha::Shell - A command line social micro-blog networking tool.

=head1 SYNOPSIS

  use App::Maisha::Shell;
  my $shell = App::Maisha::Shell->new;

=head1 DESCRIPTION

This distribution provides the ability to micro-blog via social networking
websites and services, such as Identica and Twitter.

=cut

#----------------------------------------------------------------------------
# Library Modules

use base qw(Term::Shell);
use Module::Pluggable   instantiate => 'new', search_path => ['App::Maisha::Plugin'];
use Text::Wrap;

#----------------------------------------------------------------------------
# Variables

$Text::Wrap::columns = 80;

my %plugins;    # contains all available plugins

#----------------------------------------------------------------------------
# Accessors

sub networks   { shift->_elem('networks',   @_) }
sub prompt_str { shift->_elem('prompt_str', @_) }
sub tag_str    { shift->_elem('tag_str',    @_) }
sub order      { shift->_elem('order',      @_) }
sub limit      { shift->_elem('limit',      @_) }
sub services   { shift->_elem('services',   @_) }
sub pager      { shift->_elem('pager',      @_) }
sub format     { shift->_elem('format',     @_) }
sub chars      { shift->_elem('chars',      @_) }

#----------------------------------------------------------------------------
# Public API


sub connect {
    my ($self,$plug,$config) = @_;

    unless($plug) { warn "No plugin supplied\n";   return }

    $self->_load_plugins    unless(%plugins);
    my $plugin = $self->_get_plugin($plug);
    if(!$plugin) {
        warn "Unable to establish plugin '$plug'\n";
        return;
    }

    my $status = $plugin->login($config);
    if(!$status) {
        warn "Login to '$plug' failed\n";
        return;
    }

    my $services = $self->services;
    push @$services, $plugin;
    $self->services($services);
    $self->_reset_networks;
}

#
# Connect/Disconnect
#

*run_connect = \&connect;
sub smry_connect { "connect to a service" }
sub help_connect {
    <<'END';
Connects to a named service. Requires the name of the service, together with
the username and password to access the service.
END
}


sub run_disconnect {
    my ($self,$plug) = @_;

    unless($plug) { warn "No plugin supplied\n";   return }

    my $services = $self->services;
    my @new = grep {ref($_) !~ /^App::Maisha::Plugin::$plug$/} @$services;
    $self->services(\@new);
    $self->_reset_networks;
}
sub smry_disconnect { "disconnect from a service" }
sub help_disconnect {
    <<'END';
Disconnects from the named service.
END
}


#
# Use
#

sub run_use {
    my ($self,$plug) = @_;
    if(my $p = $self->_get_plugin($plug)) {
        my $services = $self->services;
        my @new = grep {ref($_) !~ /^App::Maisha::Plugin::$plug$/} @$services;
        unshift @new, $self->_get_plugin($plug);
        $self->services(\@new);
        $self->_reset_networks;
    } else {
        warn "Unknown plugin\n";
    }
}
sub smry_use { "set primary service" }
sub help_use {
    <<'END';
Set the primary service for message list commands.
END
}

sub comp_use {
    my ($self, $word, $line, $start_index) = @_;
    my $services = $self->services;
    my @networks = map {
	ref($_) =~ /^App::Maisha::Plugin::(.+)/; $1;
    } @$services;
    return grep { /^$word/ } @networks;
}

#
# Followers
#

sub run_followers {
    my $self = shift;
    $self->_run_snapshot('followers',@_);
}
sub smry_followers { "display followers' status" }
sub help_followers {
    <<'END';
Displays the most recent status messages from each of your followers.
END
}


#
# Friends
#

sub run_friends {
    my $self = shift;
    $self->_run_snapshot('friends',@_);
}
sub smry_friends { "display friends' status" }
sub help_friends {
    <<'END';
Displays the most recent status messages from each of your friends.
END
}


#
# Show User
#

sub run_user {
    my ($self,$user) = @_;

    $user =~ s/^\@//    if($user);
    unless($user) {
        print "no user specified\n\n";
        return;
    }

    my $ref = { id => $user };
    my $ret = $self->_command('user', $ref);

    print "\n";
    print "user:        $ret->{screen_name}\n"      if($ret->{screen_name});
    print "name:        $ret->{name}\n"             if($ret->{name});
    print "location:    $ret->{location}\n"         if($ret->{location});
    print "description: $ret->{description}\n"      if($ret->{description});
    print "url:         $ret->{url}\n"              if($ret->{url});
    print "friends:     $ret->{friends_count}\n"    if($ret->{friends_count});
    print "followers:   $ret->{followers_count}\n"  if($ret->{followers_count});
    print "statuses:    $ret->{statuses_count}\n"   if($ret->{statuses_count});
    print "status:      $ret->{status}{text}\n"     if($ret->{status}{text});

    #use Data::Dumper;
    #print Dumper($ret);
}
sub smry_user { "display a user profile" }
sub help_user {
    <<'END';
Displays a user profile.
END
}

sub comp_user {
    my ($self, $word, $line, $start_index) = @_;
    my $services = $self->services;
    my $service  = $services->[0] || return;
    return  unless($service && $service->can('users'));

    my $users = $service->users;
    return grep { /^$word/ } keys %$users;
}


#
# Follow/Unfollow
#

sub run_follow {
    my ($self,$user) = @_;

    $user =~ s/^\@//    if($user);
    unless($user) {
        print "no user specified\n\n";
        return;
    }

    my $ref = { id => $user };
    my $ret = $self->_command('follow', $ref);
}
sub smry_follow { "follow a named user" }
sub help_follow {
    <<'END';
Sends a follow request to the name user. If status updates are not protected
you can start seeing that user's updates immediately. Otherwise you will have
to wait until the user accepts your request.
END
}


sub run_unfollow {
    my ($self,$user) = @_;

    $user =~ s/^\@//    if($user);
    unless($user) {
        print "no user specified\n\n";
        return;
    }

    my $ref = { id => $user };
    my $ret = $self->_command('unfollow', $ref);
}
sub smry_unfollow { "unfollow a named user" }
sub help_unfollow {
    <<'END';
Allows you to unfollow a user.
END
}


#
# Friends Timeline
#

sub run_friends_timeline {
    my $self = shift;
    $self->_run_timeline('friends_timeline',undef,@_);
}

sub smry_friends_timeline { "display friends' status as a timeline" }
sub help_friends_timeline {
    <<'END';
Displays the most recent status messages within your friends timeline.
END
}

*run_ft = \&run_friends_timeline;
sub smry_ft { "alias to friends_timeline" }
*help_ft = \&help_friends_timeline;


#
# Public Timeline
#

sub run_public_timeline {
    my $self = shift;
    $self->_run_timeline('public_timeline',undef,@_);
}

sub smry_public_timeline { "display public status as a timeline" }
sub help_public_timeline {
    <<'END';
Displays the most recent status messages within the public timeline.
END
}

*run_pt = \&run_public_timeline;
sub smry_pt { "alias to public_timeline" }
*help_pt = \&help_public_timeline;


#
# User Timeline
#

sub run_user_timeline {
    my $self = shift;
    my $user = shift;

    $user =~ s/^\@//    if($user);
    unless($user) {
        print "no user specified\n\n";
        return;
    }

    $self->_run_timeline('user_timeline',$user,@_);
}

sub smry_user_timeline { "display named user statuses as a timeline" }
sub help_user_timeline {
    <<'END';
Displays the most recent status messages for a specified user.
END
}
*comp_user_timeline = \&comp_user;

*run_ut = \&run_user_timeline;
sub smry_ut { "alias to user_timeline" }
*help_ut = \&help_user_timeline;
*comp_ut = \&comp_user;


#
# Replies
#

sub run_replies {
    my $self = shift;
    $self->_run_timeline('replies',undef,@_);
}

sub smry_replies { "display reply messages that refer to you" }
sub help_replies {
    <<'END';
Displays the most recent reply messages that refer to you.
END
}

*run_re = \&run_replies;
sub smry_re { "alias to replies" }
*help_re = \&help_replies;


#
# Direct Messages
#

sub run_direct_messages {
    my $self = shift;
    my $frto = @_ && $_[0] =~ /^from|to$/ ? shift : 'to';

    my ($limit,$max) = $self->_get_limits(@_);

    my @res;
    for my $page (1..$max) {
        my $ref = {page => $page};
        my $ret = $self->_command('direct_messages_' . $frto,$ref);
        push @res, @$ret;
    }

    return  unless(@res);
    $self->_print_messages($limit,($frto eq 'to' ? 'sender' : 'recipient'),\@res);
}

sub smry_direct_messages { "display direct messages that have been sent to you" }
sub help_direct_messages {
    <<'END';
Displays the direct messages that have been sent to you.
END
}

*run_dm = \&run_direct_messages;
sub smry_dm { "alias to direct_messages" }
*help_dm = \&help_direct_messages;


#
# Send Message
#

sub run_send_message {
    my $self = shift;
    my (undef,$user,$mess) = split(/\s+/,$self->line(),3);

    $user =~ s/^\@//    if($user);
    unless($user) {
        print "no user specified\n\n";
        return;
    }

    unless(defined $mess && $mess =~ /\S/) {
        print "cannot send an empty message\n\n";
        return;
    }

    $mess =~ s/^\s+//;
    $mess =~ s/\s+$//;
    my $len = length $mess;
    if($len > 140) {
        print "message too long: $len/140\n\n";
        return;
    }

    my $ref = { user => $user, text => $mess };
    $self->_command('send_message', $ref);
}

sub smry_send_message { "send a direct message" }
sub help_send_message {
    <<'END';
Posts a message (upto 140 characters), to a named user.
END
}

*comp_send_message = \&comp_user;
*comp_send = \&comp_user;
*comp_sm = \&comp_user;

*run_send = \&run_send_message;
sub smry_send { "alias to send_message" }
*help_send = \&help_send_message;

*run_sm = \&run_send_message;
*smry_sm = \&smry_send;
*help_sm = \&help_send_message;


#
# Update/Say
#

sub run_update {
    my $self = shift;
    my (undef,$text) = split(' ',$self->line(),2);
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    unless($text) {
        print "cannot send an empty message\n\n";
        return;
    }

    my $len = length $text;
    if($len < 140) {
        my $tag = $self->tag_str;
        $text .= " " if ($text =~ /\S/);
        $text .= $tag   if(length "$text$tag" <= 140);
    } elsif($len > 140) {
        print "message too long: $len/140\n\n";
        return;
    }

    $self->_commands('update', $text);
}
sub smry_update { "post a message" }
sub help_update {
    <<'END';
Posts a message (upto 140 characters).
END
}

*comp_update = \&comp_user;

# help
*run_say = \&run_update;
sub smry_say { "alias to 'update'" }
*help_say = \&help_update;
*comp_say = \&comp_user;


#
# About
#

sub smry_about { "brief summary of maisha" }
sub help_about {
    <<'END';
Provides a brief summary about maisha.
END
}
sub run_about {
    print <<ABOUT;

Maisha is a command line application that can interface with a number of online
social networking sites. Referred to as micro-blogging, users can post status
updates to the likes of Twitter and Identi.ca. Maisha provides the abilty to
follow the status updates of friends and see who is following you, as well as
allowing you to send updates and send and receive direct messages too.

Maisha means "life" in Swahili, and as the application is not tied to any
particular online service, it seemed an appropriate choice of name. After all
you are posting status updates about your life :)

Maisha is written in Perl, and freely available as Open Source under the Perl
Artistic license. Copyright (c) 2009 Barbie for Grango.org, the Open Source
development outlet of Miss Barbell Productions. See http://maisha.grango.org.

Version: $VERSION

ABOUT
}


#
# Version
#

sub smry_version { "display the current version of maisha" }
sub help_version {
    <<'END';
Displays the current version of maisha.
END
}
sub run_version {
    print "\nVersion: $VERSION";
}


#
# Quit/Exit
#

sub smry_quit { "alias to exit" }
sub help_quit {
    <<'END';
Exits the program.
END
}
sub run_quit {
    my $self = shift;
    $self->stoploop;
}

*run_q = \&run_quit;
*smry_q = \&smry_quit;
*help_q = \&help_quit;

sub postcmd {
    my ($self, $handler, $cmd, $args) = @_;
    print $self->networks   unless ($handler && ($$handler =~ /^comp_/));
}

#----------------------------------------------------------------------------
# Private Methods

sub _reset_networks {
    my $self = shift;
    my $first = 1;
    my $str = "\nNetworks: ";
    my $services = $self->services;
    for my $item (@$services) {
        my $ref = ref($item);
        $ref =~ s/^App::Maisha::Plugin:://;
        $str .= $first ? "[$ref]" : " $ref";
        $first = 0;
    }
    $str .= "\n";
    $self->networks($str);
}

sub _elem {
    my $self = shift;
    my $name = shift;
    my $value = $self->{$name};
    if (@_) {
        $self->{$name} = shift;
    }
    return $value;
}

sub _run_snapshot {
    my $self = shift;
    my $cmd  = shift;

    my ($limit,$max) = $self->_get_limits_all(@_);

    my @res;
    if($max) {
        for my $page (1..$max) {
            my $ref = {page => $page};
            my $ret = $self->_command($cmd,$ref);
            push @res, @$ret;
        }
    } else {
        my $ret = $self->_command($cmd);
        push @res, @$ret;
    }

    return  unless(@res);
    $self->_print_messages($limit,undef,\@res);
}

sub _run_timeline {
    my $self = shift;
    my $cmd  = shift;
    my $user = shift;
    my ($limit,$max) = $self->_get_limits(@_);

    my @res;
    for my $page (1..$max) {
        my $ref = {id => $user, page => $page};
        my $ret = $self->_command($cmd,$ref);
        next    unless($ret);
        push @res, @$ret;
    }

    return  unless(@res);
    $self->_print_messages($limit,'user',\@res);
}

sub _command {
    my $self = shift;
    my $cmd  = shift;

    my $services = $self->services;
    return  unless(defined $services && @$services);

    my $service  = $services->[0];
    return  unless(defined $service);

    my $method = "api_$cmd";
    my $ret;
    eval { $ret = $service->$method(@_) };

    if ($@) {
        print "Command $cmd failed :( [$@]\n";
    } elsif(!$ret) {
        print "Command $cmd failed :(\n";
    } else {
        #print "$cmd ok\n";
    }

    return $ret;
}

sub _commands {
    my $self = shift;
    my $cmd  = shift;

    my $services = $self->services;
    return  unless(defined $services && @$services);

    for my $service (@$services) {
        next  unless(defined $service);

        my $class  = ref($service);
        $class =~ s/^App::Maisha::Plugin:://;

        my $method = "api_$cmd";
        my $ret;
        eval { $ret = $service->$method(@_) };

        if ($@) {
            print "[$class] Command $cmd failed :( [$@]\n";
        } elsif(!$ret) {
            print "[$class] Command $cmd failed :(\n";
        } else {
            print "[$class] $cmd ok\n";
        }
    }

    return;
}

sub _print_messages {
    my ($self,$limit,$who,$ret) = @_;

    $Text::Wrap::columns = $self->chars;

    my @recs = $self->order =~ /^asc/i ? @$ret : reverse @$ret;
    splice(@recs,$limit)  if($limit && $limit < scalar(@recs));
    @recs = reverse @recs;

    my $msgs = "\n" .
        join("\n",  map {
                        wrap('','    ',$self->_format_message($_,$who))
                    } @recs ) . "\n";
    if ($self->pager) {
        $self->page($msgs);
    } else {
        print $msgs;
    }
}

sub _format_message {
    my ($self,$mess,$who) = @_;
    my ($user,$text);

    my $network = $self->networks();
    $network =~ s!^.*?\[([^\]]+)\].*!$1!s;

    my $timestamp = $mess->{created_at};
    if($who) {
        $user = $mess->{$who}{screen_name};
        $text = $mess->{text};
    } else {
        $user = $mess->{screen_name};
        $text = $mess->{status}{text};
        $text ||= '';
    }

    my $format = $self->format;
    $format =~ s!\%U!$user!g;
    $format =~ s!\%M!$text!g;
    $format =~ s!\%T!$timestamp!g;
    $format =~ s!\%N!$network!g;
    return $format;
}

sub _get_limits {
    my $self = shift;
    my $limit = @_ && $_[0] =~ /^\d+$/ ? shift : $self->limit;
    my $max   = $limit ? int($limit / 20) + ($limit % 20 ? 1 : 0) : 1;
    return($limit,$max);
}

sub _get_limits_all {
    my $self = shift;
    my $limit = @_ && $_[0] =~ /^\d+$/ ? shift : undef;
    my $max   = $limit ? int($limit / 20) + ($limit % 20 ? 1 : 0) : undef;
    return($limit,$max);
}

sub _load_plugins {
    my $self = shift;
    for my $plugin ($self->plugins()) {
        my $class = ref($plugin);
        $class =~ s/^App::Maisha::Plugin:://;
        #print STDERR "CLASS=$class, PLUGIN=$plugin\n";
        $plugins{$class} = $plugin  unless($class eq 'Base');
    }
}

sub _get_plugin {
    my $self  = shift;
    my $class = shift or return;
    return $plugins{$class} || undef;
}

1;

__END__

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Configuration Methods

=over 4

=item * context

Used internally to reference the current shell for command handlers.

=item * limit

Used by timeline commands to limit the number of messages displayed. The
default setting will display the last 20 messages.

=item * order

Used by timeline commands to order the messages displayed. The default is to
display messages in descending order, with the most recent first and the oldest
last.

To reverse this order, set the 'order' as 'ascending' (or 'asc') in your
configuration file. (case insensitive).

=item * networks

Sets the networks list that will appear above the command line.

=item * prompt_str

Sets the prompt string that will appear on the command line.

=item * tag_str

Sets the text that will appear at the end of your message.

In order to suppress the tag string set the 'tag' option to '.' in your
configuration file.

=item * services

Provides the order of services available, the first is always the primary
service.

=item * pager

Enables the use of a pager when viewing timelines.  Defaults to true
if not specified.

=item * format

When printing a list of status messages, the default format of printing the
username followed by the status message is not always suitable for everyone. As
such you can define your own formatting.

The default format is "[%U] %M", with the available formatting patterns defined
as:

  %U - username or screen name
  %M - status message
  %T - timestamp
  %N - network

=item * chars

As Maisha is run from the command line, it is most likely being run within a
terminal window. Unfortunately there isn't currently a detection method for
knowing the exact screen width being used. As such you can specify a width for
the wrapper to use to ensure the messages are correctly line wrapped. The
default setting is 80.

=back

=head2 Run Methods

The run methods are handlers to run the specific command requested.

=head2 Help Methods

The help methods are handlers to provide additional information about the named
command when the 'help' command is used, with the name of a command as an
argument.

=head2 Summary Methods

When the 'help' command is requested, with no additonal arguments, a summary
of the available commands is display, with the text from each specific command
summary method handler.

=head2 Completion Methods

For some commands completion methods are available to help complete the command
request. for example with the 'use' command, pressing <TAB> will attempt to
complete the name of the Network plugin name for you.

=head2 Connect Methods

The connect methods provide the handlers to connect to a service. This is
performed automatically on startup for all the services provided in your
configuration file.

=over 4

=item * connect

=item * run_connect
=item * help_connect
=item * smry_connect

=back

=head2 Disconnect Methods

The disconnect methods provide the handlers to disconnect from a service.

=over 4

=item * run_disconnect
=item * help_disconnect
=item * smry_disconnect

=back

=head2 Use Methods

The use methods provide the handlers change the primary service. The primary
service is used by the main messaging commands. All available services are
used when 'update' or 'say' are used.

=over 4

=item * run_use
=item * help_use
=item * smry_use
=item * comp_use

=back

=head2 Followers Methods

The followers methods provide the handlers for the 'followers' command.

=over 4

=item * run_followers
=item * help_followers
=item * smry_followers

=back

=head2 Follow Methods

The follow methods provide the handlers for the 'follow' command.

=over 4

=item * run_follow
=item * help_follow
=item * smry_follow

=back

=head2 Unfollow Methods

The unfollow methods provide the handlers for the 'unfollow' command.

=over 4

=item * run_unfollow
=item * help_unfollow
=item * smry_unfollow

=back

=head2 User Methods

The user methods provide the handlers display the profile of a named user.

=over 4

=item * run_user
=item * help_user
=item * smry_user
=item * comp_user

=back

=head2 User Timeline Methods

The user timeline methods provide the handlers for the 'user_timeline'
command. Note that the 'ut' is an alias to 'user_timeline'.

=over 4

=item * run_user_timeline
=item * help_user_timeline
=item * smry_user_timeline
=item * comp_user_timeline

=item * run_ut
=item * help_ut
=item * smry_ut
=item * comp_ut

=back

=head2 Friends Methods

The friends methods provide the handlers for the 'friends' command.

=over 4

=item * run_friends
=item * help_friends
=item * smry_friends

=back

=head2 Friends Timeline Methods

The friends timeline methods provide the handlers for the 'friends_timeline'
command. Note that the 'ft' is an alias to 'friends_timeline'.

=over 4

=item * run_friends_timeline
=item * help_friends_timeline
=item * smry_friends_timeline

=item * run_ft
=item * help_ft
=item * smry_ft

=back

=head2 Public Timeline Methods

The public timeline methods provide the handlers for the 'public_timeline'
command. Note that the 'pt' is an alias to 'public_timeline'.

=over 4

=item * run_public_timeline
=item * help_public_timeline
=item * smry_public_timeline

=item * run_pt
=item * help_pt
=item * smry_pt

=back

=head2 Update Methods

The update methods provide the handlers for the 'update' command. Note that
'say' is an alias for 'update'.

=over 4

=item * run_update
=item * help_update
=item * smry_update
=item * comp_update

=item * run_say
=item * help_say
=item * smry_say
=item * comp_say

=back

=head2 Reply Methods

The reply methods provide the handlers for the 'replies' command. Note that
're' is an aliases for 'replies'

=over 4

=item * run_replies
=item * help_replies
=item * smry_replies

=item * run_re
=item * help_re
=item * smry_re

=back

=head2 Direct Message Methods

The direct message methods provide the handlers for the 'direct_message'
command. Note that 'dm' is an aliases for 'direct_message'.

The direct_message command has to optional parameters:

  maisha> dm [from|to] [limit]

  maisha> dm from
  maisha> dm to 10
  maisha> dm 5
  maisha> dm

The first above is the usage, with the keywords 'from' and 'to' both being
optional. If neither is specified, 'to' is assumed. In addition a limit for
the number of message can be provided. If no limit is given, your configured
default, or the system default (20) is used.

=over 4

=item * run_direct_messages
=item * help_direct_messages
=item * smry_direct_messages

=item * run_dm
=item * help_dm
=item * smry_dm

=back

=head2 Send Message Methods

The send message methods provide the handlers for the 'send_message' command.
Note that both 'send' and 'sm' are aliases to 'send_message'

=over 4

=item * run_send_message
=item * help_send_message
=item * smry_send_message
=item * comp_send_message

=item * run_send
=item * help_send
=item * smry_send
=item * comp_send

=item * run_sm
=item * help_sm
=item * smry_sm
=item * comp_sm

=back

=head2 About Methods

The quit methods provide the handlers for the 'about' command.

=over 4

=item * run_about
=item * help_about
=item * smry_about

=back

=head2 Version Methods

The quit methods provide the handlers for the 'version' command.

=over 4

=item * run_version
=item * help_version
=item * smry_version

=back

=head2 Quit Methods

The quit methods provide the handlers for the 'quit' command. Note that both
'quit' and 'q' are aliases to 'exit'

=over 4

=item * run_quit
=item * help_quit
=item * smry_quit

=item * run_q
=item * help_q
=item * smry_q

=back

=head2 Post Command Methods

Used to display the current networks list above the command line.

=over 4

=item * postcmd

=back

=head1 SEE ALSO

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

L<App::Maisha>

L<Term::Shell>

=head1 WEBSITES

=over 4

=item * Main Site: L<http://maisha.grango.org>
=item * Git Repo:  L<http://github.com/barbie/maisha/tree/master>
=item * RT Queue:  L<RT: http://rt.cpan.org/Public/Dist/Display.html?Name=App-Maisha>

=back

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2012 by Barbie

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
