#
# Module Name:	csv.pm
# Description:	CSV Module
#

package csv;

use strict;
use misc;

sub open_file {
	my ($this, $file, $delim) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'file'} = $file;
	$self->{'delim'} = $delim ? $delim : ":";
	$self->load_file();
	return($self);
}

sub close_file {
	my ($self) = @_;

	$self->write_file();
}

sub add_entry {
	my ($self, @values) = @_;

	$self->check_age();
	push(@{ $self->{'entries'} }, [ @values ]);
	$self->write_file();
	return(0);
}

sub remove_entry {
	my ($self, $index) = @_;

	$self->check_age();
	for my $i (0..$#{ $self->{'entries'} }) {
		if ($self->{'entries'}->[$i]->[0] eq $index) {
			splice(@{ $self->{'entries'} }, $i, 1);
			$self->write_file();
			return(0);
		}
	}
	return(-1);
}

sub replace_entry {
	my ($self, $index, @values) = @_;

	$self->check_age();
	for my $i (0..$#{ $self->{'entries'} }) {
		if ($self->{'entries'}->[$i]->[0] eq $index) {
			$self->{'entries'}->[$i] = [ $index, @values ];
			$self->write_file();
			return(0);
		}
	}
	return(0);
}

sub find_entry {
	my ($self, $index) = @_;

	$self->check_age();
	for my $i (0..$#{ $self->{'entries'} }) {
		if ($self->{'entries'}->[$i]->[0] eq $index) {
			return(@{ $self->{'entries'}->[$i] });
		}
	}
	return(undef);
}

sub find_all_entries {
	my ($self, $index) = @_;

	$self->check_age();
	my @entries = ();
	for my $i (0..$#{ $self->{'entries'} }) {
		if ($self->{'entries'}->[$i]->[0] eq $index) {
			push(@entries, $self->{'entries'}->[$i]);
		}
	}
	return(@entries);
}

### Local Functions ###

sub check_age {
	my ($self) = @_;

	if ((-M $self->{'file'}) != $self->{'age'}) {
		$self->load_file();
	}
}

sub load_file {
	my ($self) = @_;

	$self->{'entries'} = [ ];
	return(0) unless (-e $self->{'file'});
	$self->{'age'} = -M $self->{'file'};
	open(FILE, $self->{'file'}) or return;
	while (my $line = <FILE>) {
		$line = strip_return($line);
		push(@{ $self->{'entries'} }, [ split($self->{'delim'}, $line) ]);
	}
	close(FILE);
}

sub write_file {
	my ($self) = @_;

	create_file_directory($self->{'file'});
	open(FILE, ">$self->{'file'}") or return(-1);
	foreach my $entry (@{ $self->{'entries'} }) {
		print FILE join($self->{'delim'}, @{ $entry }) . "\n";
	}
	close(FILE);
}

1;

