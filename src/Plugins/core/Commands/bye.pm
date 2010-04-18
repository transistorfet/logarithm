#
# Command Name:	bye.pm
#

package Plugins::core::Commands::bye;

sub get_info {{
	'access' => 500,
	'help' => [
		"bye",
		"Causes logarithm to exit"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	if ($privs >= 500) {
		$irc->disconnect();
		exit;
	}
	return(-10);
}

