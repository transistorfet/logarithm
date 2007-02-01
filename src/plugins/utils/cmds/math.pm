#
# Command Name:	math.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: math <math expression>",
		"Description: Calculates the answer to simple math equations containing the operations +, -, *, /, cos, sin, abs, sqrt, exp, log, hex, oct, and int. The variables \$pi and \$ans can also be used."
	]
}}

my $ans = 0;

sub do_command {
	my ($irc, $msg, $privs) = @_;

	if ($msg->{'phrase'} =~ /^(\(|\)|\+|-|\*|\/|\$pi|\$ans|cos|sin|abs|sqrt|exp|hex|oct|int|log|0x(\d|a|b|c|d|e|f)+|\d|\.|\s)*$/) {
		my $pi = 3.141592653589793238462643383279502884197169399375105;
		my $equation = '$ans = ' . $msg->{'phrase'} . ';';
		return(-1) unless (defined(eval "$equation"));
		$irc->private_msg($msg->{'respond'}, "The answer is: $ans");
		return(0);
	}
	return(-20);
}


