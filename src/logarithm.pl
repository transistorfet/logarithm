#!/usr/bin/perl

use irc;
use misc;
use users;
use module;
use channels;

##### SCRIPT VARIABLES #####

my $time_ping = time();
my $ping_timeout = 900;
my $irc_connection = irc_create();

##### MAIN START #####

parse_config($irc_connection);
irc_connect($irc_connection);
main_loop($irc_connection);

##### MAIN END #####

sub main_loop {
	local($irc) = @_;
	while (1) {
		local($msg) = irc_get_msg($irc);

		if ($msg->{'cmd'} eq "ERROR") {
			status_log("ERROR! Restarting...");
			irc_disconnect($irc);
			irc_connect($irc);
		}
		elsif ($msg->{'cmd'} eq "PING") {
			$time_ping = time();
		}
		elsif (($msg->{'cmd'} eq "JOIN") and ($msg->{'nick'} eq $irc->{'nick'})) {
			foreach $name (channel_get_option($irc->{'channels'}, $msg->{'channel'}, "plugins")) {
				module_execute($irc, $msg, "$name.pm", "init_$name") if ($name);
			}
		}
		elsif ($msg->{'cmd'} eq "PRIVMSG") {
			if (irc_in_channel($irc, $msg->{'channel'})) {
				parse_chat($irc, $msg);
			}
			elsif ($msg->{'channel'} eq $irc->{'nick'}) {
				parse_cmd($irc, $msg);
			}
		}
		elsif ($msg->{'cmd'} eq "KICK") {
			if ($msg->{'msg'}->[1] =~ /\Q$irc->{'nick'}\E/i) {
				irc_leave_channel($irc, $msg->{'channel'});
				irc_join_channel($irc, $msg->{'channel'});
			}
		}

		check_ping_timeout();
		module_execute_chats($irc, $msg);
		module_execute_alarms($irc);
	}
}

sub parse_cmd {
	local($irc, $msg) = @_;

	my $lead = (channel_get_option($irc->{'channels'}, $msg->{'respond'}, "command_designator", "!"))[0];
	$msg->{'text'} =~ s/^\Q$lead\E//;
	run_cmd($irc, $msg);
}

sub parse_chat {
	local($irc, $msg) = @_;

	my $lead = (channel_get_option($irc->{'channels'}, $msg->{'respond'}, "command_designator", "!"))[0];
	if ($msg->{'text'} =~ /^(hi|hey|hello) \Q$irc->{'nick'}\E/i) {
		irc_private_msg($irc, $msg->{'respond'}, "hello $msg->{'nick'}");
	}
	elsif ($msg->{'text'} =~ /^\Q$lead\E/) {
		$msg->{'text'} =~ s/^\Q$lead\E//;
		run_cmd($irc, $msg);
	}
	return(0);
}

sub parse_config {
	local($irc) = @_;
	local($cmd, $value);

	open(CONFIG, "../etc/log.conf") or return(0);
	while (<CONFIG>) {
		chomp;
		s/;(.)*$//;
		s/\r$//;
		($cmd, $value) = split("=");
		if (/server/i) {
			irc_add_server($irc, $value);
		}
		elsif (/nick/i) {
			irc_change_nick($irc, $value);
		}
		elsif (/password/i) {
			irc_change_password($irc, $value);
		}
		elsif (/echo/i) {
			irc_set_echo($irc, $value);
		}
		elsif (/logging/i) {
			irc_set_logging($irc, "", $value);
		}
		elsif (/logs/i) {
			irc_set_log_directory($irc, $value);
		}
		elsif (/join/i) {
			irc_join_channel($irc, $value);
		}
	}
	close(CONFIG);
}

sub run_cmd {
	local($irc, $msg) = @_;

	user_check_hostmask($irc->{'users'}, $msg->{'nick'}, $msg->{'server'}) unless (user_is_authorized($irc->{'users'}, $msg->{'nick'}));

	$msg->{'params'} = [ split(" ", $msg->{'text'}) ];
	my $cmd = lc(shift(@{ $msg->{'params'} }));
	$msg->{'cmd'} = $cmd;
	$msg->{'phrase'} = $msg->{'text'};
	$msg->{'phrase'} =~ s/^\Q$cmd\E\s*//;
	unshift(@{ $msg->{'params'} }, $msg->{'respond'}) unless ($msg->{'params'}->[0] =~ /^\#/);

	my $ret = module_execute($irc, $msg, $cmd);
	if ($ret == -1) {
		irc_notice($irc, $msg->{'nick'}, "Sorry, Command Failed");
	}
	elsif ($ret == -10) {
		irc_notice($irc, $msg->{'nick'}, "Sorry, Permission Denied");
	}
	elsif ($ret == -20) {
		irc_notice($irc, $msg->{'nick'}, "Sorry, Invalid Syntax");
	}
	return(0);
}

sub check_ping_timeout {
	if ((time() - $time_ping) >= $ping_timeout) {
		status_log("Ping Timeout, Restarting...");
		$time_ping = time();
		irc_disconnect($irc);
		irc_connect($irc);
	}
}






