#!/usr/bin/perl
#
# Name:		logarithm.pl
# Description:	Logarithm IRC Bot
#

use strict;

use irc;
use misc;
use module;

my $ping_timeout = 300;
my $time_last_msg = time();

main();
exit(0);

sub main {
	my $irc = irc->new();
	foreach my $plugin ($irc->{'options'}->get_value("plugins")) {
		module->load_plugin("plugins/$plugin/$plugin.pm");
	}
	foreach my $dir ($irc->{'options'}->get_value("command_path")) {
		module->register_command_directory($dir);
	}
	$irc->connect();
	main_loop($irc);
}

sub main_loop {
	my ($irc) = @_;

	while (1) {
		my $msg = $irc->receive_msg();
		$time_last_msg = time() if ($msg->{'cmd'} ne "TICK");

		if ($msg->{'cmd'} eq "ERROR") {
			status_log("ERROR! Restarting...");
			$irc->disconnect();
			$irc->connect();
		}
		elsif (($msg->{'cmd'} eq "JOIN") and ($msg->{'nick'} eq $irc->{'nick'})) {
			#foreach my $name (channel_get_option($irc->{'channels'}, $msg->{'channel'}, "plugins")) {
			#	module_execute($irc, $msg, "$name.pm", "init_$name") if ($name);
			#}
		}
		elsif ($msg->{'cmd'} eq "PRIVMSG") {
			if ($irc->{'channels'}->in_channel($msg->{'channel'})) {
				parse_chat($irc, $msg);
			}
			elsif ($msg->{'channel'} eq $irc->{'nick'}) {
				parse_cmd($irc, $msg, 1);
			}
		}
		elsif ($msg->{'cmd'} eq "KICK") {
			if ($msg->{'params'}->[1] =~ /\Q$irc->{'nick'}\E/i) {
				$irc->join_channel($msg->{'channel'});
			}
		}

		check_ping_timeout($irc);
		module->check_timers();
	}
}

sub parse_chat {
	my ($irc, $msg) = @_;

	if ($msg->{'text'} =~ /^(hi|hey|hello) \Q$irc->{'nick'}\E$/i) {
		$irc->private_msg($msg->{'respond'}, "hello $msg->{'nick'}");
	}
	else {
		parse_cmd($irc, $msg, 0);
	}
	return(0);
}

sub parse_cmd {
	my ($irc, $msg, $allow_bare_commands) = @_;

	my ($options, $lead);
	$options = $irc->{'channels'}->get_options($msg->{'respond'});
	$lead = $options->get_scalar_value("command_designator") if ($options);
	$lead = $irc->{'options'}->get_scalar_value("command_designator", "!") unless ($lead);
	return(0) unless (($msg->{'text'} =~ /^\Q$lead\E/) or $allow_bare_commands);
	$msg->{'text'} =~ s/^\Q$lead\E//;
	$irc->{'users'}->check_hostmask($msg->{'nick'}, $msg->{'host'}) unless ($irc->{'users'}->is_authorized($msg->{'nick'}));

	$msg->{'args'} = [ split(" ", $msg->{'text'}) ];
	my $command = lc(shift(@{ $msg->{'args'} }));
	$msg->{'command'} = $command;
	$msg->{'phrase'} = $msg->{'text'};
	$msg->{'phrase'} =~ s/^\Q$command\E\s*//;
	unshift(@{ $msg->{'args'} }, $msg->{'respond'}) unless ($msg->{'args'}->[0] =~ /^\#/);

	return(0) unless (command_enabled($irc, $msg->{'respond'}, $command));
	my $privs = $irc->{'users'}->get_access($msg->{'args'}->[0], $msg->{'nick'});

	my $ret = module->evaluate_command($command, $irc, $msg, $privs);
	if ($ret == -1) {
		$irc->notice($msg->{'nick'}, "Sorry, Command Failed");
	}
	elsif ($ret == -10) {
		$irc->notice($msg->{'nick'}, "Sorry, Permission Denied");
	}
	elsif ($ret == -20) {
		$irc->notice($msg->{'nick'}, "Sorry, Invalid Syntax");
	}
	return(0);
}

sub check_ping_timeout {
	my ($irc) = @_;

	if ((time() - $time_last_msg) >= $ping_timeout) {
		status_log("Ping Timeout, Restarting...");
		$time_last_msg = time();
		$irc->disconnect();
		$irc->connect();
	}
}

sub command_enabled {
	my ($irc, $channel, $command) = @_;

	my ($options, $disable_all, @commands);
	$options = $irc->{'channels'}->get_options($channel);
	$disable_all = $options->get_scalar_value("disable_all") if ($options);
	$disable_all = $irc->{'options'}->get_scalar_value("disable_all") unless (defined($disable_all));
	if ($disable_all) {
		@commands = $options->get_value("enabled_commands") if ($options);
		push(@commands, $irc->{'options'}->get_value("enabled_commands"));
		foreach my $allowed (@commands) {
			return(1) if ($command eq $allowed);
		}
		return(0);
	}
	else {
		@commands = $options->get_value("disabled_commands") if ($options);
		push(@commands, $irc->{'options'}->get_value("disabled_commands"));
		foreach my $denied (@commands) {
			return(0) if ($command eq $denied);
		}
		return(1);
	}
}




