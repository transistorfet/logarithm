#
# Module Name:	ListFile.pm
# Description:	File-Based Array (Stored as CSV File)
#

package ListFile;

use strict;
use warnings;

use Misc;

sub new {
	my ($this, $file, $delim, $case_insensitive) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'file'} = $file;
	$self->{'delim'} = $delim ? $delim : ":";
	$self->{'insensitive'} = $case_insensitive;
	$self->_load();
	return($self);
}

sub add {
	my ($self, @values) = @_;

	$self->_check_age();
	push(@{ $self->{'entries'} }, [ @values ]);
	$self->_write();
	return(0);
}

sub remove {
	my ($self, $index) = @_;

	$self->_check_age();
	$index = lc($index) if ($self->{'insensitive'});
	for my $i (0..$#{ $self->{'entries'} }) {
		my $key = $self->{'entries'}->[$i]->[0];
		$key = lc($key) if ($self->{'insensitive'});
		if ($key eq $index) {
			splice(@{ $self->{'entries'} }, $i, 1);
			$self->_write();
			return(0);
		}
	}
	return(-1);
}

sub replace {
	my ($self, $index, @values) = @_;

	$self->_check_age();
	$index = lc($index) if ($self->{'insensitive'});
	for my $i (0..$#{ $self->{'entries'} }) {
		my $key = $self->{'entries'}->[$i]->[0];
		$key = lc($key) if ($self->{'insensitive'});
		if ($key eq $index) {
			$self->{'entries'}->[$i] = [ $index, @values ];
			$self->_write();
			return(0);
		}
	}
	return(0);
}

sub get {
	my ($self, $index) = @_;

	$self->_check_age();
	return(undef) if ($index > $#{ $self->{'entries'} });
	return(@{ $self->{'entries'}->[$index] });
}

sub find {
	my ($self, $index) = @_;

	$self->_check_age();
	$index = lc($index) if ($self->{'insensitive'});
	for my $i (0..$#{ $self->{'entries'} }) {
		my $key = $self->{'entries'}->[$i]->[0];
		$key = lc($key) if ($self->{'insensitive'});
		if ($key eq $index) {
			return(@{ $self->{'entries'}->[$i] });
		}
	}
	return(undef);
}

sub find_all {
	my ($self, $index) = @_;

	$self->_check_age();
	my @entries = ();
	$index = lc($index) if ($self->{'insensitive'});
	for my $i (0..$#{ $self->{'entries'} }) {
		my $key = $self->{'entries'}->[$i]->[0];
		$key = lc($key) if ($self->{'insensitive'});
		if ($key eq $index) {
			push(@entries, $self->{'entries'}->[$i]);
		}
	}
	return(@entries);
}

sub size {
	my ($self) = @_;

	$self->_check_age();
	return(scalar(@{ $self->{'entries'} }));
}

### Local Functions ###

sub _check_age {
	my ($self) = @_;

	if ((-M $self->{'file'}) != $self->{'age'}) {
		$self->_load();
	}
}

sub _load {
	my ($self) = @_;

	$self->{'entries'} = [ ];
	return(0) unless (-e $self->{'file'});
	$self->{'age'} = -M $self->{'file'};
	open(FILE, $self->{'file'}) or return;
	while (my $line = <FILE>) {
		$line = strip_return($line);
		#push(@{ $self->{'entries'} }, [ split($self->{'delim'}, $line) ]) if ($line);
		push(@{ $self->{'entries'} }, [ _parse_value($self->{'delim'}, $line) ]) if ($line);
	}
	close(FILE);
}

sub _write {
	my ($self) = @_;

	create_file_directory($self->{'file'});
	open(FILE, ">$self->{'file'}") or return(-1);
	foreach my $entry (@{ $self->{'entries'} }) {
		print FILE join($self->{'delim'}, @{ $entry }) . "\n";
	}
	close(FILE);
}

sub _parse_value {
	my ($delim, $values) = @_;

	my @ret = ();
	while ($values) {
		my $value;
		if ($values =~ /\"([^"]+)\"/) {
			$value = $1;
			$values =~ s/\"([^"]+)\"($delim|)//;
		}
		elsif ($values =~ /([^$delim"]+)/) {
			$value = $1;
			$values =~ s/([^$delim"]+)($delim|)//;
		}
		else {
			last;
		}
		push(@ret, $value);
	}
	return(@ret);
}

1;

