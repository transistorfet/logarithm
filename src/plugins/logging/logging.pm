#
# Plugin Name:	logging.pm
# Description:	IRC Logging Module
#

use misc;

my $install_dir;

my $default_logdir = "../logs";
my $last_time = get_time();

sub init_plugin {
	my ($dir) = @_;

	$install_dir = $dir;
	module->register_hook("log", "irc_connect", "hook_connect");
	module->register_hook("log", "irc_disconnect", "hook_disconnect");
	module->register_hook("log", "irc_dispatch_msg", "hook_dispatch_msg");
	module->register_hook("log", "irc_change_nick", "hook_change_nick");
	module->register_hook("log", "irc_quit_channel", "hook_quit_channel");

	module->register_command_directory("$install_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}

sub hook_connect {
	my ($irc) = @_;

	unless (defined($irc->{'logging'})) {
		my $logdir = $irc->{'options'}->get_scalar_value("logdir");
		$logdir = $default_logdir unless ($logdir);
		create_directory($logdir);
		$irc->{'logging'} = {
			'logdir' => $logdir,
			'logging' => 1,
			'echo' => 1
		};
	}

	status_log("Starting Logs...");
	foreach my $channel ($irc->{'channels'}->get_channel_list()) {
		start_logs($irc, $channel);
	}
}

sub hook_disconnect {
	my ($irc) = @_;

	foreach my $channel ($irc->{'channels'}->get_channel_list()) {
		end_logs($irc, $channel);
	}
}

sub hook_dispatch_msg {
	my ($irc, $msg) = @_;

	check_all_logs($irc);
	if ($msg->{'cmd'} eq "PRIVMSG") {
		if ($irc->{'channels'}->in_channel($msg->{'channel'})) {
			if ($msg->{'text'} =~ /^\x01ACTION (.*)\x01$/) {
				print_log($irc, $msg->{'channel'}, "* $msg->{'nick'} $1");
			}
			else {
				print_log($irc, $msg->{'channel'}, "<$msg->{'nick'}> $msg->{'text'}");
			}
		}
	}
	elsif ($msg->{'cmd'} eq "TOPIC" or $msg->{'cmd'} eq "332") {
		print_log($irc, $msg->{'channel'}, "--- topic: ($msg->{'channel'}) $msg->{'text'}");
	}
	elsif ($msg->{'cmd'} eq "JOIN") {
		start_logs($irc, $msg->{'channel'}) if ($msg->{'nick'} eq $irc->{'nick'});
		print_log($irc, $msg->{'channel'}, "--- join: $msg->{'nick'} ($msg->{'host'}) $msg->{'channel'}");
	}
	elsif ($msg->{'cmd'} eq "PART") {
		print_log($irc, $msg->{'channel'}, "--- part: $msg->{'nick'} ($msg->{'text'}) $msg->{'channel'}");
		end_logs($irc, $msg->{'channel'}) if ($msg->{'nick'} eq $irc->{'nick'});
	}
	elsif ($msg->{'cmd'} eq "NAMES" or $msg->{'cmd'} eq "353") {
		print_log($irc, $msg->{'channel'}, "--- names: $msg->{'channel'} ($msg->{'text'})");
	}
	elsif ($msg->{'cmd'} eq "MODE") {
		print_log($irc, $msg->{'channel'}, "--- mode: ($msg->{'nick'}) @{ $msg->{'params'} }");
	}
	elsif ($msg->{'cmd'} eq "KICK") {
		print_log($irc, $msg->{'channel'}, "--- kick: $msg->{'params'}->[1] by $msg->{'nick'} ($msg->{'text'}) $msg->{'channel'}");
	}
}

sub hook_change_nick {
	my ($irc, $msg, $channel) = @_;

	print_log($irc, $channel, "--- nick: $msg->{'nick'} -> $msg->{'text'}");
}

sub hook_quit_channel {
	my ($irc, $msg, $channel) = @_;

	print_log($irc, $channel, "--- quit: $msg->{'nick'} ($msg->{'text'})");
}


sub print_log {
	my ($irc, $channel, $msg) = @_;
	return unless ($channel =~ /^#/);

	my $time = get_time();
	$msg = strip_colour($msg);
	return if (open_logs($irc, $channel, $last_time));
	printf FILE ("%02d:%02d:%02d ", $time->{'hour'}, $time->{'min'}, $time->{'sec'});
	print FILE "$msg\n";
	print "$channel:$msg\n" if ($irc->{'logging'}->{'echo'});
	close_logs();
}

sub check_all_logs {
	my ($irc) = @_;

	my $time = get_time();
	my $temp_time = $last_time;
	foreach my $channel ($irc->{'channels'}->get_channel_list()) {
		if ($last_time->{'day'} != $time->{'day'}) {
			end_logs($irc, $channel);
			$last_time = $time;
			start_logs($irc, $channel);
			$last_time = $temp_time;
		}
	}
	$last_time = get_time();
}

sub start_logs {
	my ($irc, $channel) = @_;

	my $time = get_time();
	return if (open_logs($irc, $channel, $last_time));
	printf FILE ("%02d:%02d:%02d --- log started ($channel) %02d-%02d-%02d\n", $time->{'hour'}, $time->{'min'}, $time->{'sec'}, $time->{'year'}, $time->{'month'}, $time->{'day'});
	close_logs();
}

sub end_logs {
	my ($irc, $channel) = @_;

	my $time = get_time();
	return if (open_logs($irc, $channel, $last_time));
	printf FILE ("%02d:%02d:%02d --- log ended ($channel) %02d-%02d-%02d\n", $time->{'hour'}, $time->{'min'}, $time->{'sec'}, $time->{'year'}, $time->{'month'}, $time->{'day'});
	close_logs();
}

sub open_logs {
	my ($irc, $channel, $time) = @_;

	return(1) unless (is_enabled($irc, $channel));
	if ($irc->{'connected'}) {
		$channel =~ s/^#+//;
		mkdir "$irc->{'logging'}->{'logdir'}/$channel" if (!(-e "$irc->{'logging'}->{'logdir'}/$channel"));
		$file = sprintf("$irc->{'logging'}->{'logdir'}/$channel/%02d-%02d-%02d.txt", $time->{'year'}, $time->{'month'}, $time->{'day'});
		open(FILE, ">>$file") or (status_log("Cannot Open Log $file") and return(-1));
		return(0);
	}
	return(-1);
}

sub close_logs {
	close FILE;
}

sub strip_colour {
	my ($msg) = @_;

	$msg =~ s/(\x03)+\d{1,2}(,\d{1,2})?//g;
	$msg =~ s/(\x03)*//g;
	$msg =~ s/(\x02|\x06|\x07|\x16)//g;
	return($msg);
}

sub is_enabled {
	my ($irc, $channel) = @_;

	my $default = $irc->{'options'}->get_scalar_value("enable_logging");
	my $options = $irc->{'channels'}->get_options($channel);
	return($default) unless ($options);
	my $enabled = $options->get_scalar_value("enable_logging");
	return(defined($enabled) ? $enabled : $default);
}

1;

