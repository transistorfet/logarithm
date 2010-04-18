#
# Module Name:	Hook.pm
# Description:	Hook Manager
#

package Hook;

use strict;
use warnings;

use Misc;
use Handler;

my $hooks = { };

sub new {
	my ($this, $name, $handler) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'name'} = $name;
	$self->{'handler'} = $handler;
	$hooks->{ $name } = [ ] unless defined($hooks->{ $name });
	push(@{ $hooks->{ $name } }, $self);
	return($self);
}

sub remove {
	my ($self) = @_;

	return(-1) unless defined($hooks->{ $self->{'name'} });
	my $list = $hooks->{ $self->{'name'} };
	for my $i (0..$#{ $list }) {
		if ($list->[$i] eq $self) {
			splice(@{ $list }, $i, 1);
			return(0);
		}
	}
	return(-1);
}

# TODO add a function to remove hooks based on the function name

sub do_hook {
	my ($name, @params) = @_;
	return unless defined($hooks->{ $name });
	foreach my $hook (@{ $hooks->{ $name } }) {
		$hook->{'handler'}->handle(@params);
	}
}


sub purge {
	my ($package) = @_;

	foreach my $key (keys(%{ $hooks })) {
		my $list = $hooks->{ $key };
		for my $i (0..$#{ $list }) {
			if ($list->[$i]->{'handler'}->owner() eq $package) {
				splice(@{ $list }, $i, 1);
			}
		}
	}
}

1;


