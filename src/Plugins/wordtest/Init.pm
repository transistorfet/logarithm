#
# Plugin Name:	Init.pm
# Description:	A game that tests the players on their vocabulary
#

package Plugins::wordtest::Init;

sub get_info {{
	'help' => [
		"Usage: wordtest on|off [<language>]",
		"Description: Activates the word test game which runs for a sequence of 20 words or until !wordtest stop is said"
	]
}}

my $default_time = 60;
my $default_game_length = 20;

sub init_plugin {
	my ($plugin_dir) = @_;

	my $wordtest = { 'plugin_dir' => $plugin_dir };
	Hook->new("irc_dispatch_msg", Handler->new("hook_msg_dispatch", $wordtest));
	Command->add("wordtest", Handler->new("wordtest_command", $wordtest));
	return(0);
}

sub release_plugin {
	return(0);
}

sub wordtest_command {
	my ($wordtest, $irc, $msg, $privs) = @_;

	if ($msg->{'args'}->[1] eq "on") {
		if (defined($wordtest->{ $msg->{'respond'} })) {
			$irc->notice($msg->{'nick'}, "A game is already started.");
		}
		else {
			my ($name, $reverse) = ($msg->{'args'}->[2], 0);
			($name, $reverse) = ($msg->{'args'}->[3], 1) if (lc($name) eq "reverse");
			wordtest_on($wordtest, $irc, $msg->{'respond'}, $name, $reverse, $default_game_length);
		}
	}
	elsif ($msg->{'args'}->[1] eq "off") {
		if (defined($wordtest->{ $msg->{'respond'} })) {
			wordtest_off($wordtest, $irc, $msg->{'respond'});
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
	my ($wordtest, $irc, $channel, $name, $reverse, $max) = @_;

	my $test = load_questions("$wordtest->{'plugin_dir'}/lists", $name, $reverse, $max);
	if (defined($test)) {
		$wordtest->{ $channel } = $test;
		module->register_timer($channel, $test->{'time'}, 1, "wordtest_timer", $wordtest, $irc, $channel);
		next_question($wordtest, $irc, $channel);
	}
	else {
		$irc->private_msg($channel, "I Can't Find The Questions! =(");
	}
}

sub wordtest_off {
	my ($wordtest, $irc, $channel) = @_;

	if (my @scores = get_high_scores($wordtest->{ $channel }->{'scores'})) {
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
	my ($wordtest, $irc, $msg) = @_;

	my $channel = $msg->{'respond'};
	return(0) unless ($msg->{'cmd'} eq "PRIVMSG");
	return(0) unless (defined($wordtest->{ $channel }) and ($msg->{'nick'} ne $irc->{'nick'}));
	foreach my $answer (@{ $wordtest->{ $channel }->{'answers'} }) {
		if ($msg->{'text'} =~ /^\Q$answer\E$/i) {
			my $score = add_score($wordtest->{ $channel }->{'scores'}, $msg->{'nick'});
			$irc->private_msg($channel, "Correct $msg->{'nick'}!  Your Score Is Now $score");
			module->reset_timer($channel);
			sleep 1;
			next_question($wordtest, $irc, $channel);
			last;
		}
	}
}

sub wordtest_timer {
	my ($wordtest, $irc, $channel) = @_;

	my $answer = $wordtest->{ $channel }->{'answers'}->[0];
	$irc->private_msg($channel, "Time's Up!  The correct answer was $answer");
	sleep 1;
	next_question($wordtest, $irc, $channel);
}

sub next_question {
	my ($wordtest, $irc, $channel) = @_;

	my ($ln, $question, $answer);
	$wordtest->{ $channel }->{'count'}++;
	if ($wordtest->{ $channel }->{'max'} and ($wordtest->{ $channel }->{'count'} > $wordtest->{ $channel }->{'max'})) {
		wordtest_off($wordtest, $irc, $channel);
	}
	elsif (scalar(@{ $wordtest->{ $channel }->{'words'} }) == 0) {
		$irc->private_msg($channel, "No More Questions Left");
		wordtest_off($wordtest, $irc, $channel);
	}
	else {
		$ln = rand(scalar(@{ $wordtest->{ $channel }->{'words'} }));
		$question = splice(@{ $wordtest->{ $channel }->{'words'} }, $ln, 1);
		($question, $answer) = split(/\s*\*\s*/, $question);
		($question, $answer) = ($answer, $question) if ($wordtest->{ $channel }->{'reverse'});
		my @questions = split(/\s*,\s*/, $question);
		$wordtest->{ $channel }->{'answers'} = [ split(/\s*,\s*/, $answer) ];
		$irc->private_msg($channel, $questions[0]);
	}
	return(0);
}

sub load_questions {
	my ($dir, $name, $reverse, $max) = @_;

	my $file;
	if ($name =~ /^(\w+)$/) {
		$file = "$dir/$name.lst";
	}
	else {
		$file = "$dir/wordtest.lst";
	}

	my $test = {
		'words' => [ ],
		'scores' => { },
		'answers' => "",
		'reverse' => $reverse,
		'time' => $default_time,
		'count' => 0,
		'max' => $max
	};

	open(FILE, $file) or return(undef);
	while (<FILE>) {
		if (/\*/) {
			s/(\r|)\n$//;
			s/^\s*//;
			push(@{ $test->{'words'} }, $_);
		}
	}
	close(FILE);
	return($test);
}

sub add_score {
	my ($scores, $nick) = @_;

	return(++$scores->{ $nick });
}

sub get_high_scores {
	my ($list) = @_;

	my @scores = ();
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



