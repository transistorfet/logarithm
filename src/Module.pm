#
# Module Name:	Module.pm
# Description:	Command Modules Manager
#

package Module;

use strict;
use warnings;

use Misc;
use Handler;

my $modules = { };

sub load {
	my ($this, $file) = @_;
	return(undef) unless (-e $file);

	my $package = _get_package_name($file);
	if (defined($modules->{ $package })) {
		$modules->{ $package }->_check_age();
		return ($modules->{ $package });
	}

	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'package'} = $package;
	$self->{'file'} = $file;
	$self->{'age'} = 0;
	$modules->{ $package } = $self;
	$self->_reload();
	return($self);
}

sub release {
	my ($self) = @_;
	# TODO is this the best way to do this?
	# TODO this no longer works because of the way you do handlers using Module::call()
	Command::purge($self->{'package'});
	Timer::purge($self->{'package'});
	Hook::purge($self->{'package'});
	return(0);
}

sub call {
	my ($self, $func, @params) = @_;

	$self->_check_age();
	return(undef) unless eval("defined(*$self->{'package'}::${func}{CODE})");
	my $ret = eval "$self->{'package'}::$func(\@params);";
	status_log($@) if ($@);
	return($ret);
}

sub make_handler {
	my ($self, $func, @params) = @_;
	return(Handler->new("call", $self, $func, @params));
}


sub get_module {
	my ($name) = @_;
	return($modules->{ _get_package_name($name) }) if (-e $name);
	return($modules->{ $name });
}

sub get_module_list {
	return(keys(%{ $modules }));
}

### Local Functions ###

sub _check_age {
	my ($self) = @_;

	if ($self->{'age'} > -M $self->{'file'}) {
		$self->_reload();
		# TODO you should call init again here
	}
}

sub _reload {
	my ($self) = @_;

	my $file_contents;
	open(FILE, $self->{'file'}) or return(0);
	{
		local $/ = undef;
		$file_contents = <FILE>;
	}
	close(FILE);

	my $program = join("\n",
		"package $self->{'package'};",
		$file_contents,
		"1;"
	);

	eval $program;
	status_log($@) if ($@);
	$self->{'age'} = -M $self->{'file'};
}

sub _get_package_name {
	my ($file) = @_;

	my $name = $file;
	$name =~ tr/A-Za-z0-9/_/cs;
	return("Logarithm::${name}");
}

1;

