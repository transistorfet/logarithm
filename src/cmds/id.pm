
$module_info = {
	'help' => [
		"Usage: id <password>",
		"Description: Identifies yourself using the given password"
	]
};

sub do_id {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) != 2);

	if (user_login($irc->{'users'}, $msg->{'nick'}, $msg->{'params'}->[1])) {
		irc_notice($irc, $msg->{'nick'}, "Sorry, Invalid Password For $msg->{'nick'}");
	}
	else {
		irc_notice($irc, $msg->{'nick'}, "$msg->{'nick'} Identified");
	}
	return(0);
}

