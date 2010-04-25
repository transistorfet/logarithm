#
# Module Name:	HashFile.pm
# Description:	File-Based Hash List
#

package HashFile;

use strict;
use warnings;

use Misc;

sub new {
	my ($this, $file) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->_load($file);
	return($self);
}

sub set {
	my ($self, $key, @values) = @_;

	$key = lc($key);
	$self->_check_age();
	$self->{'values'}->{ $key } = [ @values ];
	$self->_write();
	return(0);
}

sub delete {
	my ($self, $key) = @_;

	$key = lc($key);
	$self->_check_age();
	delete($self->{'values'}->{ $key });
	$self->_write();
	return(0);
}

sub add {
	my ($self, $key, @values) = @_;

	$key = lc($key);
	$self->_check_age();
	foreach my $value (@values) {
		push(@{ $self->{'values'}->{ $key } }, $value) unless ($self->contains($key, $value));
	}
	$self->_write();
	return(0);
}

sub remove {
	my ($self, $key, @values) = @_;

	$key = lc($key);
	$self->_check_age();
	return(0) unless (defined($self->{'values'}->{ $key }));
	foreach my $value (@values) {
		for my $i (0..scalar(@{ $self->{'values'}->{ $key } })) {
			if ($self->{'values'}->{ $key }->[$i] eq $value) {
				splice(@{ $self->{'values'}->{ $key } }, $i, 1);
				$self->_write();
				return(0);
			}
		}
	}
	return(-1);
}

sub get_all {
	my ($self, $key, @def) = @_;

	$key = lc($key);
	$self->_check_age();
	return(@def) unless (defined($self->{'values'}->{ $key }));
	return(@{ $self->{'values'}->{ $key } });
}

sub get_scalar {
	my ($self, $key, $def) = @_;

	$key = lc($key);
	$self->_check_age();
	return($def) unless (defined($self->{'values'}->{ $key }));
	return($self->{'values'}->{ $key }->[0]);
}

sub contains {
	my ($self, $key, $search) = @_;

	$key = lc($key);
	foreach my $value (@{ $self->{'values'}->{ $key } }) {
		return(1) if ($value eq $search);
	}
	return(0);
}

### Local Functions ###

sub _check_age {
	my ($self) = @_;

	if ((-M $self->{'file'}) != $self->{'age'}) {
		$self->_load($self->{'file'});
	}
}

sub _load {
	my ($self, $file) = @_;

	$self->{'file'} = $file;
	$self->{'values'} = { };
	unless (-e $file) {
		open(FILE, ">$file") or return(0);
		close(FILE);
	}
	$self->{'age'} = -M $file;
	open(FILE, $file) or return(0);
	while (my $line = <FILE>) {
		$line =~ s/;(.)*$//;
		my ($key, $value) = split(/\s*=\s*/, strip_return($line));
		next unless ($key);
		$key = lc($key);
		$self->{'values'}->{ $key } = [ _parse_value($value) ];
	}
	close(FILE);
	return(0);
}

sub _write{
	my ($self) = @_;

	create_file_directory($self->{'file'});
	open(FILE, ">$self->{'file'}") or return(0);
	foreach my $key (sort(keys(%{ $self->{'values'} }))) {
		my $value = '"' . join('","', @{ $self->{'values'}->{ $key } }) . '"';
		print FILE "$key = $value\n";
	}
	close(FILE);
	$self->{'age'} = -M $self->{'file'};
	return(0);
}

sub _parse_value {
	my ($values) = @_;

	my @ret = ();
	while ($values) {
		my $value;
		if ($values =~ /^\s*\"([^"]+)\"/) {
			$value = $1;
			$values =~ s/^\s*\"([^"]+)\"(,|)//;
		}
		elsif ($values =~ /^\s*([^,"]+)/) {
			$value = $1;
			$values =~ s/^\s*([^,"]+)(,|)//;
		}
		else {
			last;
		}
		push(@ret, $value);
	}
	return(@ret);
}

1;

