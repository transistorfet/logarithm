#
# Command Name:	help.pm
#

package Plugins::core::Commands::help;

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
		if (my $info = Command::get_info($msg->{'args'}->[1])) {
			@help = @{ $info->{'help'} };
			unshift(@help, "Access Level Required: $info->{'access'}");
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

