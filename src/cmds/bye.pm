
$module_info = {
	'help' => [
		"bye",
		"Causes logarithm to exit"
	]
};

sub do_bye {
	local($irc, $msg, $privs) = @_;
	if ($privs >= 500) {
		irc_disconnect($irc);
		exit;
	}
	return(-10);
}
