#
# Plugin Name:	imgcache.pm
# Description:	IRC Image Caching Module
#

use misc;

my $default_cachedir = "../public_html/cache";

sub init_plugin {
	my ($plugin_dir) = @_;

	module->register_hook("cache", "irc_dispatch_msg", "hook_dispatch_msg");
	module->register_command_directory("$plugin_dir/cmds");
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
			if ($text =~ /(http\:\/\/\S+\.(png|jpg|gif))/) {
				cache_image($irc, $msg, $1);
			}
		}
	}
}

sub cache_image {
	my ($irc, $channel, $url) = @_;

	my $cachedir = $irc->{'options'}->get_scalar_value("cachedir");
	$cachedir = $default_cachedir unless ($cachedir);
	create_directory($cachedir) unless (-e $cachedir);

	my $cmd = "wget -qc -Q2M -P $cachedir \"$1\" &";
	status_log("imgcache: Running \"$cmd\"");
	system($cmd);
}

1;

