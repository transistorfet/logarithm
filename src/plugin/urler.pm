#
# Command Name:	urler.pm
# Version:	0.1
# Package:	Urler
#

$module_info = {
	'help' => [
		"Description: Controls the automatic url catcher which catches urls posted in the channel"
	]
};

sub init_urler {
	local($irc, $msg, $privs) = @_;

	return(-1) if (module_register_chat("urler.pm", "do_urler_chat", $msg->{'respond'}, "PRIVMSG"));
}

sub do_urler_chat {
	local($irc, $msg, $privs) = @_;

	if ($msg->{'text'} =~ /(http\:|www\.)(\S*)/) {
		csv_add($msg->{'respond'}, "url.lst", '', ",$1$2,$msg->{'text'},$msg->{'nick'}");
	}
}
