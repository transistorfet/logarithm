
$module_info = {
	'help' => [
		"Usage: option [<channel>] set|get|add|remove|erase <option> [<value>]",
		"Description: Sets, Displays, Adds to, Removes from, or Erases the specified option (using value if needed) for channel (current if unspecified)"
	]
};

sub do_option {
	local($irc, $msg, $privs) = @_;
	local($channel, $option);

	return(-20) if (scalar(@{ $msg->{'params'} }) < 3);
	($channel, $cmd, $option) = @{ $msg->{'params'} };
	$cmd = lc($cmd);
	return(-10) if (user_get_access($irc->{'users'}, $channel, $msg->{'nick'}) < 300);

	if ($cmd eq "set") {
		$msg->{'text'} =~ s/(.*?)$option\s*//;
		channel_set_option($irc->{'channels'}, $channel, $option, $msg->{'text'});
		irc_notice($irc, $msg->{'nick'}, "$option Set To $msg->{'text'}");
	}
	elsif ($cmd eq "get") {
		my @value = channel_get_option($irc->{'channels'}, $channel, $option);
		my $line = "$option = (" . join(', ', @value) . ")";
		irc_notice($irc, $msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "add") {
		$msg->{'text'} =~ s/(.*?)$option\s*//;
		channel_append_to_option($irc->{'channels'}, $channel, $option, $msg->{'text'});
		my @value = channel_get_option($irc->{'channels'}, $channel, $option);
		my $line = "$option = (" . join(', ', @value) . ")";
		irc_notice($irc, $msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "remove") {
		$msg->{'text'} =~ s/(.*?)$option\s*//;
		channel_remove_from_option($irc->{'channels'}, $channel, $option, $msg->{'text'});
		my @value = channel_get_option($irc->{'channels'}, $channel, $option);
		my $line = "$option = (" . join(', ', @value) . ")";
		irc_notice($irc, $msg->{'nick'}, "$line");
	}
	elsif ($cmd eq "erase") {
		channel_delete_option($irc->{'channels'}, $channel, $option);
		irc_notice($irc, $msg->{'nick'}, "$option Deleted");
	}
	else {
		return(-20);
	}
}

