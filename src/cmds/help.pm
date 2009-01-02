#
# Command Name:	help.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: help [<command>]",
		"Description: Displays a list of commands or the help description for a specified command"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my @help = ();
	if (scalar(@{ $msg->{'args'} }) > 1) {
		my $command = Command::get($msg->{'args'}->[1]);
		if (!defined($command)) {
			$irc->notice($msg->{'nick'}, "Sorry, The command $msg->{'args'}->[1] is not available");
			return(0);
		}
		my $module = Module->get_module($command->handler()->package());
		if (defined($module) and (my $info = $module->call("get_info"))) {
			@help = @{ $info->{'help'} };
		}
		else {
			$irc->notice($msg->{'nick'}, "Sorry, No help available on $msg->{'args'}->[1]");
			return(0);
		}
	}
	else {
		my $line;
		my $i = 0;
		my @commands = sort(Command::get_list());
		foreach my $command (@commands) {
			$command = uc($command);
			my $blank = "";
			for (1..(15 - length($command))) {
				$blank .= '.';
			}
			$line .= " [$command$blank]";
			if (++$i >= 3) {
				push(@help, $line);
				$line = "";
				$i = 0;
			}
		}
		push(@help, $line) if ($line);
	}

	foreach (@help) {
		$irc->notice($msg->{'nick'}, $_);
	}

	return(0);
}

