#
# Module Name:	Timer.pm
# Description:	Timer Manager
#

package Timer;

use strict;
use warnings;

use Misc;
use Handler;

my $min_wait = 0.5;

my $timers = [ ];

sub new {
	my ($this, $seconds, $autoreset, $handler) = @_;
	return(undef) if ($seconds <= 0);
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'seconds'} = $seconds;
	$self->{'autoreset'} = $autoreset;
	$self->{'expire'} = time() + $seconds;
	$self->{'handler'} = $handler;
	$self->add();
	return($self);
}

sub add {
	my ($self) = @_;

	for my $i (0..$#{ $timers }) {
		if ($self->{'expire'} <= $timers->[$i]->{'expire'}) {
			splice(@{ $timers }, $i, 0, $self);
			return;
		}
	}
	push(@{ $timers }, $self);
}

sub remove {
	my ($self) = @_;

	for my $i (0..$#{ $timers }) {
		if ($timers->[$i] eq $self) {
			splice(@{ $timers }, $i, 1);
			return(1);
		}
	}
	return(0);
}

sub set {
	my ($self, $seconds) = @_;

	$self->{'seconds'} = $seconds;
	$self->reset();
}

sub reset {
	my ($self) = @_;

	$self->remove();
	$self->{'expire'} = time() + $self->{'seconds'};
	return($self->add());
}

sub get_next_expire {
	return(undef) unless scalar(@{ $timers });
	return($timers->[0]->{'expire'});
}

sub get_max_wait {
	return(undef) unless scalar(@{ $timers });
	my $wait = $timers->[0]->{'expire'} - time();
	$wait = $min_wait if ($wait <= 0);
	return($wait);
}

sub check_timers {

	my $current = time();
	while (scalar(@{ $timers })) {
		return if ($timers->[0]->{'expire'} > $current);
		my $timer = shift(@{ $timers });
		$timer->{'handler'}->handle();
		if ($timer->{'autoreset'}) {
			$timer->{'expire'} = time() + $timer->{'seconds'};
			$timer->add();
		}
	}
	return(0);
}

sub purge {
	my ($package) = @_;

	for my $i (0..$#{ $timers }) {
		if ($timers->[$i]->{'handler'}->owner() eq $package) {
			splice(@{ $timers }, $i, 1);
		}
	}
}

1;

