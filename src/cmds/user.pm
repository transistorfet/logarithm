
$module_info = {
	'help' => [
		"Usage: user <password|hostmask> <value>",
		"Description: Changes your password of hostmask"
	]
};

sub do_user {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) != 3);

	if (lc($msg->{'params'}->[1]) eq "password") {
		return(-1) if (user_change_password($irc->{'users'}, $msg->{'nick'}, $msg->{'params'}->[2]));
		irc_notice($irc, $msg->{'nick'}, "Password Changed Successfully");
	}
	elsif (lc($msg->{'params'}->[1]) eq "hostmask") {
		return(-1) if (user_change_hostmask($irc->{'users'}, $msg->{'nick'}, $msg->{'params'}->[2]));
		irc_notice($irc, $msg->{'nick'}, "Hostmask Changed Successfully");
	}
	else {
		return(-20);
	}
}

