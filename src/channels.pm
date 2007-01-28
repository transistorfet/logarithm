#
# Module Name:	channels.pm
# Description:	Channels Manager
#

package channels;

use strict;

use misc;
use config;

my $options_dir = "../etc";

sub new {
	my ($this, $file) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	return($self);
}

sub join_channel {
	my ($self, $channel) = @_;

	return(-1) if (defined($self->{ $channel }));
	my $name = $channel;
	$name =~ s/^#+//;
	$self->{ $channel } = {
		'name' => $channel,
		'options' => config->new("$options_dir/$name/options.conf")
	};
	return(0);
}

sub leave_channel {
	my ($self, $channel) = @_;

	return(-1) unless (defined($self->{ $channel }));
	delete($self->{ $channel });
	return(0);
}

sub get_channel_list {
	my ($self) = @_;

	return(keys(%{ $self }));	
}

sub in_channel {
	my ($self, $channel) = @_;

	return(defined($self->{ $channel }));
}

sub get_options {
	my ($self, $channel, $def) = @_;

	return($def) unless (defined($self->{ $channel }));
	return($self->{ $channel }->{'options'});
}

1;

