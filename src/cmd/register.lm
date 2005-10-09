#
# Command Name:	register.lm
# Version:	0.1
# Package:	Users
#

$module_info = {
	'help' => [
		"Usage: register <password>",
		"Description: Registers your nick using password"
	]
};

sub do_register {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) != 2);

	if (user_register($irc->{'users'}, $msg->{'nick'}, $msg->{'params'}->[1])) {
		irc_notice($irc, $msg->{'nick'}, "Sorry, $msg->{'nick'} is Already Registered");
	}
	else {
		irc_notice($irc, $msg->{'nick'}, "$msg->{'nick'} Registered Successfully");
	}
	return(0);
}

