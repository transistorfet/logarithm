#
# Plugin Name:	wordtest.pm
# Description:	A game that tests the players on their vocabulary
#

sub get_info {{
	'help' => [
		"Usage: wordtest on|off [<language>]",
		"Description: Activates the word test game which runs for a sequence of 20 words or until !wordtest stop is said"
	]
}}

my $default_time = 60;
my $default_game_length = 20;

my $install_dir;
my $wordtest = { };

sub init_plugin {
	my ($dir) = @_;

	$install_dir = $dir;
	module->register_hook("wordtest", "irc_dispatch_msg", "hook_msg_dispatch");
	module->register_command("wordtest", "wordtest_command");
	return(0);
}

sub release_plugin {
	return(0);
}

sub wordtest_command {
	my ($irc, $msg, $privs) = @_;

	if ($msg->{'args'}->[1] eq "on") {
		if (defined($wordtest->{ $msg->{'respond'} })) {
			$irc->notice($msg->{'nick'}, "A game is already started.");
		}
		else {
			wordtest_on($irc, $msg->{'respond'}, $msg->{'args'}->[2], $default_game_length);
		}
	}
	elsif ($msg->{'args'}->[1] eq "off") {
		if (defined($wordtest->{ $msg->{'respond'} })) {
			wordtest_off($irc, $msg->{'respond'});
		}
		else {
			$irc->notice($msg->{'nick'}, "No game is currently running.");
		}
	}
	else {
		return(-20);
	}
	return(0);
}

sub wordtest_on {
	my ($irc, $channel, $file, $max) = @_;

	if (!load_questions($channel, $file, $max)) {
		module->register_timer($channel, $wordtest->{ $channel }->{'time'}, 1, "wordtest_timer", $irc, $channel);
		$wordtest->{ $channel }->{'scores'} = { };
		$wordtest->{ $channel }->{'count'} = 0;
		next_question($irc, $channel);
	}
	else {
		$irc->private_msg($channel, "I Can't Find The Questions! =(");
	}
}

sub wordtest_off {
	my ($irc, $channel) = @_;

	if (my @scores = get_high_scores($channel)) {
		if (scalar(@scores) == 1) {
			$irc->private_msg($channel, "$scores[0]->{'nick'} Is The Winner With $scores[0]->{'score'}!");
		}
		else {
			my $nicks = "$scores[0]->{'nick'}";
			for my $i (1..$#scores) {
				$nicks = "$nicks, $scores[$i]->{'nick'}";
			}
			$irc->private_msg($channel, "Its A Tie Between $nicks With $scores[0]->{'score'}!");
		}
	}
	delete($wordtest->{ $channel });
	module->unregister_timer($channel);
	$irc->private_msg($channel, "K Bye!");
	return(0);
}

sub hook_msg_dispatch {
	my ($irc, $msg) = @_;

	return(0) unless ($msg->{'cmd'} eq "PRIVMSG");
	return(0) unless (defined($wordtest->{ $msg->{'respond'} }) or ($msg->{'nick'} eq $irc->{'nick'}));
	foreach my $answer (@{ $wordtest->{ $msg->{'respond'} }->{'answers'} }) {
		if ($msg->{'text'} =~ /^\Q$answer\E$/i) {
			my $score = add_score($msg->{'respond'}, $msg->{'nick'});
			$irc->private_msg($msg->{'respond'}, "Correct $msg->{'nick'}!  Your Score Is Now $score");
			module->reset_timer($msg->{'respond'});
			sleep 1;
			next_question($irc, $msg->{'respond'});
			last;
		}
	}
}

sub wordtest_timer {
	my ($irc, $channel) = @_;

	$irc->private_msg($channel, "Time's Up");
	sleep 1;
	next_question($irc, $channel);
}

sub next_question {
	my ($irc, $channel) = @_;

	my ($ln, $question, $answers);
	$wordtest->{ $channel }->{'count'}++;
	if ($wordtest->{ $channel }->{'max'} and ($wordtest->{ $channel }->{'count'} > $wordtest->{ $channel }->{'max'})) {
		wordtest_off($irc, $channel);
	}
	elsif (scalar(@{ $wordtest->{ $channel }->{'words'} }) == 0) {
		$irc->private_msg($channel, "No More Questions Left");
		wordtest_off($irc, $channel);
	}
	else {
		$ln = rand(scalar(@{ $wordtest->{ $channel }->{'words'} }));
		$question = splice(@{ $wordtest->{ $channel }->{'words'} }, $ln, 1);
		($question, $answers) = split(/\s*\*\s*/, $question);
		$wordtest->{ $channel }->{'answers'} = [ split(/\s*,\s*/, $answers) ];
		$irc->private_msg($channel, $question);
	}
	return(0);
}

sub load_questions {
	my ($channel, $file, $max) = @_;

	if ($file =~ /^(\w+)$/) {
		$file = "plugins/wordtest/lists/$file.lst";
	}
	else {
		$file = "plugins/wordtest/lists/wordtest.lst";
	}

	$wordtest->{ $channel } = {
		'words' => [ ],
		'scores' => { },
		'answers' => "",
		'time' => $default_time,
		'count' => 0,
		'max' => $max
	};

	open(FILE, $file) or return(-1);
	while (<FILE>) {
		if (/\*/) {
			s/(\r|)\n$//;
			s/^\s*//;
			push(@{ $wordtest->{ $channel }->{'words'} }, $_);
		}
	}
	close(FILE);
	return(0);
}

sub add_score {
	my ($channel, $nick) = @_;

	$wordtest->{ $channel }->{'scores'}->{ $nick }++;
	return(1);
}

sub get_high_scores {
	my ($channel) = @_;

	my @scores = ();
	my $list = $wordtest->{ $channel }->{'scores'};
	foreach my $nick (keys(%{ $list })) {
		if ($list->{ $nick } > $scores[0]->{'score'}) {
			@scores = ({ 'nick' => $nick, 'score' => $list->{ $nick } });
		}
		elsif ($list->{ $nick } == $scores[0]->{'score'}) {
			push(@scores, { 'nick' => $nick, 'score' => $list->{ $nick } });
		}
	}
	return(@scores);
}



