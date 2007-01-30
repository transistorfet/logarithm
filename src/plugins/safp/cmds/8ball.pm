#
# Command Name:	8ball.pm
# Author:	kaos havoc
#

my $module_info = {	
	'help' => [
		"Ask me any question and the answer is yours.",
		"Just type !8ball <Your question here>"
	]
};

my @answers = (
	"Signs point to yes.",
	"Yes.",
	"Reply hazy, try again.",
	"Without a doubt.",
	"My sources say no.",
	"As I see it, yes.",
	"You may rely on it.",
	"Concentrate and ask again.",
	"Outlook not so good.",
	"It is decidedly so.",
	"Better not tell you now.",
	"Very doubtful.",
	"Yes - definitely.",
	"It is certain.",
	"Cannot predict now.",
	"Most likely.",
	"Ask again later.",
	"My reply is no.",
	"Outlook good.",
	"Don't count on it."
);

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("8ball_privs", 1));
	if($msg->{'args'}->[1]) {
        	my $ln = int(rand(scalar(@answers)));
        	my $answer = $answers[$ln];
		$irc->private_msg($msg->{'respond'}, $answer);
	}
	return(0);
}

