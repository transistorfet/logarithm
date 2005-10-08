#
# Module Name:	channels.pm
# Version:	0.6
# Description:	Channels Manager
#

package channels;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(
	channel_create
	channel_join
	channel_leave
	channel_list
	channel_in_channel
	channel_set_option
	channel_delete_option
	channel_append_to_option
	channel_remove_from_option
	channel_get_option
	channel_allowed
);


### CHANNELS.PM START ###

use misc;

sub channel_create {
	return({ });
}

sub channel_join {
	local($channels, $channel) = @_;
	return(-1) if (defined($channels->{$channel}) or channel_load_options($channels, $channel));
	return(0);
}

sub channel_leave {
	local($channels, $channel) = @_;
	return(-1) unless (defined($channels->{$channel}));
	channel_save_options($channels, $channel);
	delete($channels->{$channel});
	return(0);
}

sub channel_list {
	local($channels) = @_;
	return(keys(%{ $channels }));	
}

sub channel_in_channel {
	local($channels, $channel) = @_;
	return(defined($channels->{$channel}));
}

sub channel_set_option {
	local($channels, $channel, $option, @values) = @_;
	return(-1) unless (defined($channels->{$channel}));
	$option = lc($option);
	$channels->{$channel}->{$option} = [ @values ];
	channel_save_options($channels, $channel);
	return(0);
}

sub channel_delete_option {
	local($channels, $channel, $option) = @_;
	return(-1) unless (defined($channels->{$channel}));
	$option = lc($option);
	delete($channels->{$channel}->{$option});
	channel_save_options($channels, $channel);
	return(0);
}

sub channel_append_to_option {
	local($channels, $channel, $option, @values) = @_;
	return(-1) unless (defined($channels->{$channel}));
	$option = lc($option);

	foreach $value (@values) {
		channel_subarray_add($channels, $channel, $option, $value);
	}
	channel_save_options($channels, $channel);
	return(0);
}

sub channel_remove_from_option {
	local($channels, $channel, $option, @values) = @_;
	return(-1) unless (defined($channels->{$channel}));
	$option = lc($option);

	foreach $value (@values) {
		channel_subarray_remove($channels, $channel, $option, $value);
	}
	channel_save_options($channels, $channel);
	return(0);
}

sub channel_get_option {
	local($channels, $channel, $option, @def) = @_;
	my $option = lc($option);
	return(@def) unless (defined($channels->{$channel}) and defined($channels->{$channel}->{$option}));
	return(@{ $channels->{$channel}->{$option} });
}

sub channel_allowed {
	local($channels, $channel, $value) = @_;
	return(1) unless ($channel =~ /^\#/);
	return(0) unless (defined($channels->{$channel}));
	if ($channels->{$channel}->{'deny_all'}) {
		foreach $allowed (@{ $channels->{$channel}->{'allowed'} }) {
			return(1) if ($value eq $allowed);
		}
		return(0);
	}
	else {
		foreach $denied (@{ $channels->{$channel}->{'denied'} }) {
			return(0) if ($value eq $denied);
		}
		return(1);
	}
}

### LOCAL SUBS ###

sub channel_load_options {
	local($channels, $channel) = @_;
	$channels->{$channel} = { 'channel' => $channel };
	my $file = $channel;
	$file =~ s/^\#//;
	open(FILE, "../etc/$file/options.conf") or return(0);
	while (<FILE>) {
		s/;(.)*$//;
		($option, $value) = split("=", strip_return($_));
		if ($option) {
			$option = lc($option);
			$channels->{$channel}->{$option} = [ channel_split_values($value) ];
		}
	}
	close(FILE);
	return(0);
}

sub channel_save_options {
	local($channels, $channel) = @_;
	return(-1) unless (defined($channels->{$channel}));
	my $file = $channel;
	$file =~ s/^\#//;
	mkdir("../etc/$file") if (!(-e "../etc/$file"));
	open(FILE, ">../etc/$file/options.conf") or return(0);
	foreach $key (sort(keys(%{ $channels->{$channel} }))) {
		$value = '"' . join('","', @{ $channels->{$channel}->{$key} }) . '"';
		print FILE "$key=$value\r\n";
	}
	close(FILE);
	return(0);
}

sub channel_subarray_add {
	local($channels, $channel, $option, $value) = @_;
	foreach (@{ $channels->{$channel}->{$option} }) {
		return if ($value eq $_);
	}
	push(@{ $channels->{$channel}->{$option} }, $value);
}

sub channel_subarray_remove {
	local($channels, $channel, $option, $value) = @_;
	for $i (0..scalar(@{ $channels->{$channel}->{$option} })) {
		if ($channels->{$channel}->{$option}->[$i] eq $value) {
			splice(@{ $channels->{$channel}->{$option} }, $i, 1);
			return;
		}
	}
}

sub channel_split_values {
	local($values) = @_;
	my @ret = ();
	while ($values) {
		if ($values =~ /\"([^"]+)\"/) {
			$value = $1;
			$values =~ s/\"([^"]+)\"(,|)//;
		}
		elsif ($values =~ /([^,"]+)/) {
			$value = $1;
			$values =~ s/([^,"]+)(,|)//;
		}
		else {
			last;
		}
		push(@ret, $value);
	}
	return(@ret);
}


1;

### END OF CHANNELS.PM ###
