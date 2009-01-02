#
# Module Name:	Command.pm
# Description:	Commands Manager
#

package Command;

use strict;
use warnings;

use Misc;
use Handler;

my $commands = { };

sub add {
	my ($this, $name, $handler) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'name'} = $name;
	$self->{'handler'} = $handler;
	$commands->{ $name } = $self;
	return($self);
}

sub add_file {
	my ($class, $command, $file, @params) = @_;
	my $module = Module->load($file);
	return(add($class, $command, $module->make_handler("do_command", @params)));
}

sub add_directory {
	my ($class, $dir, @params) = @_;

	$dir =~ s/(\/|\\)$//;
	opendir(DIR, $dir) or return(-1);
	my @files = readdir(DIR);
	closedir(DIR);

	foreach my $file (@files) {
		if ($file =~ /(.*)\.pm$/) {
			add_file($class, $1, "$dir/$file", @params);
		}
	}
	return(0);
}

sub remove {
	my ($self) = @_;

	return(0) unless defined($commands->{ $self->{'name'} });
	delete($commands->{ $self->{'name'} });
	return(1);
}

sub evaluate {
	my ($self, @params) = @_;
	return($self->{'handler'}->handle(@params));
}

sub handler {
	my $self = shift(@_);
	$self->{'handler'} = shift(@_) if (scalar(@_));
	return($self->{'handler'});
}

sub module {
	my ($self) = @_;
	return(Module::get_module($self->{'handler'}->package));
}


sub get {
	my ($name) = @_;
	return($commands->{ $name });
}

sub get_module {
	my ($name) = @_;
	return(undef) unless defined($commands->{ $name });
	return($commands->{ $name }->module);
}

sub get_info {
	my ($name) = @_;
	my $module = get_module($name);
	return(undef) unless defined($module);
	return($module->call("get_info"));
}

sub get_list {
	return(keys(%{ $commands }));
}

sub evaluate_command {
	my ($name, @params) = @_;
	return(-1) unless defined($commands->{ $name });
	return($commands->{ $name }->evaluate(@params));
}

### Local Functions ###

sub _purge {
	my ($package) = @_;

	foreach my $key (keys(%{ $commands })) {
		if ($commands->{ $key }->{'handler'}->package() eq $package) {
			delete($commands->{ $key });
		}
	}
}

1;


