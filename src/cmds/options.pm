#
# Command Name:	options.pm
#

my $module_info = {
	'help' => [
		"Usage: options [<channel>] set|get|add|remove|erase <option> [<value>]",
		"Description: Sets, Displays, Adds to, Removes from, or Erases the specified option (using value if needed) for channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 3);
	my ($channel, $cmd, $option) = @{ $msg->{'args'} };
	$cmd = lc($cmd);
	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("options_privs", 300));

	my $options;
	if ($channel =~ /^#/) {
		return(-1) unless ($options = $irc->{'channels'}->get_options($channel));
	}
	else {
		$options = $irc->{'options'};
	}

	if ($cmd eq "set") {
		$msg->{'phrase'} =~ s/(.*?)\Q$option\E\s*//;
		return(-1) if ($options->set_value($option, $msg->{'phrase'}));
		$irc->notice($msg->{'nick'}, "$option Set To $msg->{'phrase'}");
	}
	elsif ($cmd eq "get") {
		my @values = $options->get_value($option);
		my $line = "$option = (" . join(', ', @values) . ")";
		$irc->notice($msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "add") {
		$msg->{'phrase'} =~ s/(.*?)\Q$option\E\s*//;
		return(-1) if ($options->add_value($option, $msg->{'phrase'}));
		my @values = $options->get_value($option);
		my $line = "$option = (" . join(', ', @values) . ")";
		$irc->notice($msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "remove") {
		$msg->{'phrase'} =~ s/(.*?)\Q$option\E\s*//;
		return(-1) if ($options->remove_value($option, $msg->{'phrase'}));
		my @values = $options->get_value($option);
		my $line = "$option = (" . join(', ', @values) . ")";
		$irc->notice($msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "erase") {
		return(-1) if ($options->delete_value($option, $msg->{'phrase'}));
		$irc->notice($msg->{'nick'}, "$option Deleted");
	}
	else {
		return(-20);
	}
}

