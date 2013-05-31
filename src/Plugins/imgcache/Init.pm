#
# Plugin Name:	Init.pm
# Description:	IRC Image Caching Module
#

package Plugins::imgcache::Init;

use strict;
use warnings;

use Misc;

my $default_cachedir = "../public_html/cache";

my $size_limit = "6M";
my $user_agent = "Firefox";

sub init_plugin {
	my ($plugin_dir) = @_;

	Hook->new("irc_dispatch_msg", Handler->new("hook_dispatch_msg"));
	Command->add_directory("$plugin_dir/Commands");
	return(0);
}

sub release_plugin {
	return(0);
}

sub hook_dispatch_msg {
	my ($irc, $msg) = @_;

	if ($msg->{'cmd'} eq "PRIVMSG") {
		if ($irc->{'channels'}->in_channel($msg->{'channel'})) {
			my $text = ($msg->{'text'} =~ /^\x01ACTION (.*)\x01$/) ? $1 : $msg->{'text'};
			if ($text =~ /((http|https)\:\/\/\S+\.(png|jpg|jpeg|gif|bmp))/i) {
				cache_image($irc, $msg, $1) if $1 !~ /jabberwocky\.ca\/\~logarithm/;
			}
			elsif ($text =~ /http\:\/\/imgur\.com\/gallery\/(\S+)/i) {
				cache_image($irc, $msg, "http://i.imgur.com/$1.jpg");
			}
		}
	}
}

sub cache_image {
	my ($irc, $channel, $url) = @_;

	my $time = get_time();
	my $cachedir = $irc->{'options'}->get_scalar("cachedir");
	$cachedir = $default_cachedir unless ($cachedir);
	$cachedir =~ s/(\/|\\)$//;
	$cachedir .= sprintf("/%04d-%02d", ($time->{'cent'} * 100) + $time->{'year'}, $time->{'month'});
	create_directory($cachedir) unless (-e $cachedir);

	$url =~ /.*\/(.*?)$/;
	my $file = $1;
	my $user_agent_arg = $user_agent ? "-U $user_agent" : "";
	my $cmd = "wget -qc -Q$size_limit $user_agent_arg -P $cachedir \"$url\" && touch -c \"$cachedir/$file\" &";
	status_log("imgcache: Running \"$cmd\"");
	system($cmd);
}

1;

