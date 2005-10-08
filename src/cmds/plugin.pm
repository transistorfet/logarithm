
$module_info = {
	'help' => [
		"Usage: plugin <name>",
		"Description: Loads the named plugin"
	]
};

sub do_plugin {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) < 2);
	($channel, $name) = @{ $msg->{'params'} };
	return(-10) if (user_get_access($irc->{'users'}, $channel, $msg->{'nick'}) < 400);

	$name =~ s/\.pm$//;
	return(-1) unless (-e "plugin/$name.pm");
	channel_append_to_option($irc->{'channels'}, $channel, "plugins", $name);
	return(-1) if (module_execute($irc, $msg, "$name.pm", "init_$name"));
	irc_notice($irc, $msg->{'nick'}, "Plugin $name loaded successfully");
	return(0);
}

