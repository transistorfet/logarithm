#
# Module Name:	config.pm
# Description:	Configuration Manager
#

package config;

use strict;
use misc;

sub new {
	my ($this, $file) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->load_config($file);
	return($self);
}

sub set_value {
	my ($self, $config, @values) = @_;

	$config = lc($config);
	$self->check_age();
	$self->{'values'}->{ $config } = [ @values ];
	$self->write_config();
	return(0);
}

sub delete_value {
	my ($self, $config) = @_;

	$config = lc($config);
	$self->check_age();
	delete($self->{'values'}->{ $config });
	$self->write_config();
	return(0);
}

sub add_value {
	my ($self, $config, @values) = @_;

	$config = lc($config);
	$self->check_age();
	foreach my $value (@values) {
		push(@{ $self->{'values'}->{ $config } }, $value) unless ($self->has_value($config, $value));
	}
	$self->write_config();
	return(0);
}

sub remove_value {
	my ($self, $config, @values) = @_;

	$config = lc($config);
	$self->check_age();
	foreach my $value (@values) {
		for my $i (0..scalar(@{ $self->{'values'}->{ $config } })) {
			if ($self->{'values'}->{ $config }->[$i] eq $value) {
				splice(@{ $self->{'values'}->{ $config } }, $i, 1);
				$self->write_config();
				return(0);
			}
		}
	}
	return(-1);
}

sub get_value {
	my ($self, $config, @def) = @_;

	$config = lc($config);
	$self->check_age();
	return(@def) unless (defined($self->{'values'}->{ $config }));
	return(@{ $self->{'values'}->{ $config } });
}

sub get_scalar_value {
	my ($self, $config, $def) = @_;

	$config = lc($config);
	$self->check_age();
	return($def) unless (defined($self->{'values'}->{ $config }));
	return($self->{'values'}->{ $config }->[0]);
}

### Local Functions ###

sub has_value {
	my ($self, $config, $search) = @_;

	$config = lc($config);
	foreach my $value (@{ $self->{'values'}->{ $config } }) {
		return(1) if ($value eq $search);
	}
	return(0);
}

sub check_age {
	my ($self) = @_;

	if ((-M $self->{'file'}) != $self->{'age'}) {
		$self->load_config($self->{'file'});
	}
}

sub load_config {
	my ($self, $file) = @_;

	$self->{'file'} = $file;
	$self->{'values'} = { };
	return(0) unless (-e $file);
	$self->{'age'} = -M $file;
	open(FILE, $file) or return(0);
	while (my $line = <FILE>) {
		$line =~ s/;(.)*$//;
		my ($config, $value) = split(/\s*=\s*/, strip_return($line));
		next unless ($config);
		$config = lc($config);
		$self->{'values'}->{ $config } = [ parse_value($value) ];
	}
	close(FILE);
	return(0);
}

sub write_config {
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

sub parse_value {
	my ($values) = @_;

	my @ret = ();
	while ($values) {
		my $value;
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

