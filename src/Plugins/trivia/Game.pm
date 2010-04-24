#
# Plugin Name:	Game.pm
# Description:	A trivia game
#

package Plugins::trivia::Game;

use strict;
use warnings;

use Timer;
use Handler;

my $default_time = 60;
my $default_next_time = 5;
my $default_game_length = 20;

sub new {
	my ($this, $irc, $channel, $dir, $name, $reverse, $max) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);

	my $file;
	if ($name =~ /^(\w+)$/) {
		$file = "$dir/$name.lst";
	}
	else {
		$file = "$dir/trivia.lst";
	}

	if (-e $file) {
		$irc->private_msg($channel, "Get ready to play trivia!");
	}
	else {
		$irc->private_msg($channel, "I Can't Find The Questions! =(");
		return(undef);
	}

	$self->{'running'} = 1;
	$self->{'irc'} = $irc;
	$self->{'channel'} = $channel;
	$self->{'questions'} = [ ];
	$self->{'scores'} = { };
	$self->{'answers'} = "";
	$self->{'reverse'} = $reverse;
	$self->{'time'} = $default_time;
	$self->{'count'} = 0;
	$self->{'max'} = $max;
	$self->{'timer'} = Timer->new($default_next_time, 0, Handler->new("_timer_expire", $self));
	Hook->new("irc_dispatch_msg", Handler->new("_hook_dispatch_msg", $self));

	open(FILE, $file) or return(undef);
	while (<FILE>) {
		if (/\*/) {
			s/(\r|)\n$//;
			s/^\s*//;
			push(@{ $self->{'questions'} }, $_);
		}
	}
	close(FILE);
	return($self);
}

sub release {
	my ($self) = @_;

	rerutrn(1) if ($self->{'running'} == 0);
	$self->{'running'} = 0;
	$self->{'timer'}->remove();
	my $irc = $self->{'irc'};
	if (my @scores = $self->_get_high_scores()) {
		if (scalar(@scores) == 1) {
			$irc->private_msg($self->{'channel'}, "$scores[0]->{'nick'} Is The Winner With $scores[0]->{'score'}!");
		}
		else {
			my $nicks = "$scores[0]->{'nick'}";
			for my $i (1..$#scores) {
				$nicks = "$nicks, $scores[$i]->{'nick'}";
			}
			$irc->private_msg($self->{'channel'}, "Its A Tie Between $nicks With $scores[0]->{'score'}!");
		}
	}
	$irc->private_msg($self->{'channel'}, "K Bye!");
	return(0);
}

sub _hook_dispatch_msg {
	my ($self, $irc, $msg) = @_;

	return(0) unless ($irc eq $self->{'irc'});
	return(0) unless ($msg->{'cmd'} eq "PRIVMSG");
	return(0) unless ($self->{'channel'} eq $msg->{'respond'} and ($msg->{'nick'} ne $irc->{'nick'}));
	return(0) unless ($self->{'answers'});
	foreach my $answer (@{ $self->{'answers'} }) {
		if ($msg->{'text'} =~ /^\Q$answer\E$/i) {
			my $score = $self->_add_score($msg->{'nick'});
			$irc->private_msg($self->{'channel'}, "Correct $msg->{'nick'}!  Your Score Is Now $score");
			$self->{'answers'} = "";
			$self->{'timer'}->set($default_next_time);
			last;
		}
	}
}

sub _next_question {
	my ($self) = @_;

	my $irc = $self->{'irc'};
	my ($ln, $question, $answer);
	$self->{'count'}++;
	if ($self->{'max'} and ($self->{'count'} > $self->{'max'})) {
		$self->release();
	}
	elsif (scalar(@{ $self->{'questions'} }) == 0) {
		$irc->private_msg($self->{'channel'}, "No More Questions Left");
		$self->release();
	}
	else {
		$ln = rand(scalar(@{ $self->{'questions'} }));
		$question = splice(@{ $self->{'questions'} }, $ln, 1);
		($question, $answer) = split(/\s*\*\s*/, $question);
		($question, $answer) = ($answer, $question) if ($self->{'reverse'});
		my @questions = split(/\s*,\s*/, $question);
		$self->{'answers'} = [ split(/\s*,\s*/, $answer) ];
		$irc->private_msg($self->{'channel'}, $questions[0]);
		$self->{'timer'}->set($default_time);
	}
	return(0);
}

sub _time_expired {
	my ($self) = @_;

	my $irc = $self->{'irc'};
	my $answer = $self->{'answers'}->[0];
	$irc->private_msg($self->{'channel'}, "Time's Up!  The correct answer was $answer");
	$self->{'answers'} = "";
	$self->{'timer'}->set($default_next_time);
}

sub _add_score {
	my ($self, $nick) = @_;
	return(++$self->{'scores'}->{ $nick });
}

sub _get_high_scores {
	my ($self) = @_;

	my @scores = ();
	foreach my $nick (keys(%{ $self->{'scores'} })) {
		if (scalar(@scores) < 1 or $self->{'scores'}->{ $nick } > $scores[0]->{'score'}) {
			@scores = ({ 'nick' => $nick, 'score' => $self->{'scores'}->{ $nick } });
		}
		elsif ($self->{'scores'}->{ $nick } == $scores[0]->{'score'}) {
			push(@scores, { 'nick' => $nick, 'score' => $self->{'scores'}->{ $nick } });
		}
	}
	return(@scores);
}

sub _timer_expire {
	my ($self) = @_;
	if ($self->{'answers'} eq "") {
		$self->_next_question();
	}
	else {
		$self->_time_expired();
	}
}

sub is_running {
	my $self = shift(@_);
	return($self->{'running'});
}

1;

