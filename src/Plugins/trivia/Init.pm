#
# Plugin Name:	Init.pm
# Description:	A game that tests the players on their vocabulary
#

package Plugins::trivia::Init;

sub get_info {{
	'help' => [
		"Usage: trivia on|off [<category>]",
		"Description: Activates the trivia game which runs for a sequence of 20 questions or until !trivia stop is said"
	]
}}

my $default_time = 60;
my $default_next_time = 5;
my $default_game_length = 20;

sub init_plugin {
	my ($plugin_dir) = @_;

	my $trivia = { 'plugin_dir' => $plugin_dir };
	Hook->new("irc_dispatch_msg", Handler->new("hook_msg_dispatch", $trivia));
	Command->add("trivia", Handler->new("trivia_command", $trivia));
	return(0);
}

sub release_plugin {
	return(0);
}

sub trivia_command {
	my ($trivia, $irc, $msg, $privs) = @_;

	if ($msg->{'args'}->[1] eq "on") {
		if (defined($trivia->{ $msg->{'respond'} })) {
			$irc->notice($msg->{'nick'}, "A game is already started.");
		}
		else {
			my ($name, $reverse) = (lc($msg->{'args'}->[2]), 0);
			($name, $reverse) = (lc($msg->{'args'}->[3]), 1) if ($name eq "reverse");
			trivia_on($trivia, $irc, $msg->{'respond'}, $name, $reverse, $default_game_length);
		}
	}
	elsif ($msg->{'args'}->[1] eq "off") {
		if (defined($trivia->{ $msg->{'respond'} })) {
			trivia_off($trivia, $irc, $msg->{'respond'});
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

sub trivia_on {
	my ($trivia, $irc, $channel, $name, $reverse, $max) = @_;

	my $test = load_questions("$trivia->{'plugin_dir'}/lists", $name, $reverse, $max);
	if (defined($test)) {
		$trivia->{ $channel } = $test;
		module->register_timer("$channel#answer", $test->{'time'}, 0, "trivia_timer", $trivia, $irc, $channel);
		module->register_timer("$channel#next", $default_next_time, 0, "next_question", $trivia, $irc, $channel);
		$irc->private_msg($channel, "Get ready to play trivia!");
	}
	else {
		$irc->private_msg($channel, "I Can't Find The Questions! =(");
	}
}

sub trivia_off {
	my ($trivia, $irc, $channel) = @_;

	if (my @scores = get_high_scores($trivia->{ $channel }->{'scores'})) {
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
	delete($trivia->{ $channel });
	module->unregister_timer("$channel#answer");
	module->unregister_timer("$channel#next");
	$irc->private_msg($channel, "K Bye!");
	return(0);
}

sub hook_msg_dispatch {
	my ($trivia, $irc, $msg) = @_;

	my $channel = $msg->{'respond'};
	return(0) unless ($msg->{'cmd'} eq "PRIVMSG");
	return(0) unless (defined($trivia->{ $channel }) and ($msg->{'nick'} ne $irc->{'nick'}));
	foreach my $answer (@{ $trivia->{ $channel }->{'answers'} }) {
		if ($msg->{'text'} =~ /^\Q$answer\E$/i) {
			my $score = add_score($trivia->{ $channel }->{'scores'}, $msg->{'nick'});
			$irc->private_msg($channel, "Correct $msg->{'nick'}!  Your Score Is Now $score");
			$trivia->{ $channel }->{'answers'} = "";
			module->reset_timer("$channel#next");
			last;
		}
	}
}

sub trivia_timer {
	my ($trivia, $irc, $channel) = @_;

	my $answer = $trivia->{ $channel }->{'answers'}->[0];
	$irc->private_msg($channel, "Time's Up!  The correct answer was $answer");
	module->reset_timer("$channel#next");
}

sub next_question {
	my ($trivia, $irc, $channel) = @_;

	my ($ln, $question, $answer);
	$trivia->{ $channel }->{'count'}++;
	if ($trivia->{ $channel }->{'max'} and ($trivia->{ $channel }->{'count'} > $trivia->{ $channel }->{'max'})) {
		trivia_off($trivia, $irc, $channel);
	}
	elsif (scalar(@{ $trivia->{ $channel }->{'questions'} }) == 0) {
		$irc->private_msg($channel, "No More Questions Left");
		trivia_off($trivia, $irc, $channel);
	}
	else {
		$ln = rand(scalar(@{ $trivia->{ $channel }->{'questions'} }));
		$question = splice(@{ $trivia->{ $channel }->{'questions'} }, $ln, 1);
		($question, $answer) = split(/\s*\*\s*/, $question);
		($question, $answer) = ($answer, $question) if ($trivia->{ $channel }->{'reverse'});
		my @questions = split(/\s*,\s*/, $question);
		$trivia->{ $channel }->{'answers'} = [ split(/\s*,\s*/, $answer) ];
		$irc->private_msg($channel, $questions[0]);
		module->reset_timer("$channel#answer");
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
		$file = "$dir/trivia.lst";
	}

	my $test = {
		'questions' => [ ],
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
			push(@{ $test->{'questions'} }, $_);
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



