#
# Module Name:	Channels.pm
# Description:	Channels Manager
#

package Channels;

use strict;
use warnings;

use Misc;
use HashFile;

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

	$channel = lc($channel);
	return(-1) if (defined($self->{ $channel }));
	(my $name = $channel) =~ s/^#+//;
	mkdir("$options_dir/$name") unless (-d "$options_dir/$name");
	$self->{ $channel } = {
		'name' => $channel,
		'options' => HashFile->new("$options_dir/$name/options.conf")
	};
	return(0);
}

sub leave_channel {
	my ($self, $channel) = @_;

	$channel = lc($channel);
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

	$channel = lc($channel);
	return(defined($self->{ $channel }));
}

sub get_options {
	my ($self, $channel, $def) = @_;

	$channel = lc($channel);
	return($def) unless (defined($self->{ $channel }));
	return($self->{ $channel }->{'options'});
}

1;

