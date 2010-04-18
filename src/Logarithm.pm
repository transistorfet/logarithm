#
# Name:		Logarithm.pm
# Description:	Logarithm IRC Bot
#

package Logarithm;

use strict;
use warnings;

use IRC;
use Misc;
use Config;
use Module;

use Hook;
use Timer;
use Command;
use Handler;

my $time_last_ping = time();

sub new {
	my ($this) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);

	my $irc = IRC->new();
	Hook->new("irc_dispatch_msg", Handler->new("hook_msg_dispatch"));
	foreach my $plugin ($irc->{'options'}->get_all("plugins")) {
		Module->load_plugin($plugin);
	}
	$irc->connect();

	$self->{'irc'} = $irc;
	return($self);
}

sub loop {
	my($self) = @_;

	my $irc = $self->{'irc'};
	while (Selector::wait_all(Timer::get_max_wait()) >= 0) {
		my $ping_interval = $irc->{'options'}->get_scalar("ping_interval");
		if ($ping_interval and ((time() - $time_last_ping) > $ping_interval)) {
			$irc->send_msg("PING $irc->{'server'}\n");
			$time_last_ping = time();
		}
		Timer::check_timers();
	}
}

sub hook_msg_dispatch {
	my ($irc, $msg) = @_;

	if ($msg->{'cmd'} eq "ERROR") {
		$irc->disconnect();
		status_log("Disconnected.  Waiting 30 seconds before reconnect.");
		sleep(30);
		$irc->connect();
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

	my $lead = $irc->get_scalar_config($msg->{'respond'}, "command_designator", "!");
	return(0) unless (($msg->{'text'} =~ /^\Q$lead\E/) or $allow_bare_commands);

	$msg->{'args'} = [ split(" ", $msg->{'text'}) ];
	my $command = lc(shift(@{ $msg->{'args'} }));
	$command =~ s/^\Q$lead\E//;
	$msg->{'command'} = $command;
	$msg->{'phrase'} = $msg->{'text'};
	$msg->{'phrase'} =~ s/^(\Q$lead\E|)\Q$command\E\s*//;
	unshift(@{ $msg->{'args'} }, $msg->{'respond'}) if (scalar(@{ $msg->{'args'} }) <= 0 or !($msg->{'args'}->[0] =~ /^\#/));

	my $ret = evaluate_command($irc, $msg);
	if ($ret == -1) {
		$irc->notice($msg->{'nick'}, "Sorry, Command Failed");
	}
	elsif ($ret == -10) {
		$irc->notice($msg->{'nick'}, "Sorry, Permission Denied");
	}
	elsif ($ret == -20) {
		$irc->notice($msg->{'nick'}, "Sorry, Invalid Syntax");
	}
	elsif ($ret == -100) {
		$irc->notice($msg->{'nick'}, "Sorry, No Such Command");
	}
	return(0);
}

sub evaluate_command {
	my ($irc, $msg) = @_;

	my $command = $msg->{'command'};
	$irc->{'users'}->check_hostmask($msg->{'nick'}, $msg->{'host'}) unless ($irc->{'users'}->is_authorized($msg->{'nick'}));
	return(0) unless (command_enabled($irc, $msg->{'respond'}, $command));
	my $info = Command::get_info($command);
	return(-100) unless (defined($info));
	my $options = $irc->{'channels'}->get_options($msg->{'respond'});
	my $channel_access = $options ? $options->get_scalar("${command}_access", 0) : 0;
	my $access = $irc->{'options'}->get_scalar("${command}_access", $info ? $info->{'access'} : 500);
	$access = $channel_access if ($channel_access > $access);
	my $privs = $irc->{'users'}->get_access($msg->{'args'}->[0], $msg->{'nick'});
	return(-10) if ($privs < $access);
	return(Command::evaluate_command($command, $irc, $msg, $privs));
}

sub command_enabled {
	my ($irc, $channel, $command) = @_;

	my ($options, $disable_all, @commands);
	$options = $irc->{'channels'}->get_options($channel);
	$disable_all = $options->get_scalar("disable_all") if ($options);
	$disable_all = $irc->{'options'}->get_scalar("disable_all") unless (defined($disable_all));
	if ($disable_all) {
		@commands = $options->get_all("enabled_commands") if ($options);
		push(@commands, $irc->{'options'}->get_all("enabled_commands"));
		foreach my $allowed (@commands) {
			return(1) if ($command eq $allowed);
		}
		return(0);
	}
	else {
		@commands = $options->get_all("disabled_commands") if ($options);
		push(@commands, $irc->{'options'}->get_all("disabled_commands"));
		foreach my $denied (@commands) {
			return(0) if ($command eq $denied);
		}
		return(1);
	}
}

1;

