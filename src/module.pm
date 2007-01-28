#
# Module Name:	module.pm
# Description:	Command Modules Manager
#

package module;

use strict;

use misc;

my $modules = { };
my $commands = { };

sub check_age {
	my ($class, $package) = @_;

	if ($modules->{ $package }->{'age'} > -M $modules->{ $package }->{'file'}) {
		module->load($modules->{ $package }->{'type'}, $modules->{ $package }->{'file'})
	}
}

sub load {
	my ($class, $type, $file) = @_;

	return(0) unless (-e $file);
	$type = lc($type);
	my $name = file_to_name($file);
	my $package = "Logarithm::${type}::${name}";

	my $module;
	open(FILE, $file) or return(0);
	{
		local $/ = undef;
		$module = <FILE>;
	}
	close(FILE);

	my $program = join("\n",
		"package $package;",
		$module,
		"1;"
	);

	eval $program;
	status_log($@) if ($@);
	$modules->{ $package } = {
		'package' => $package,
		'type' => $type,
		'file' => $file,
		'age' => -M $file,
		'hooks' => { },
		'timers' => { }
	};
	return($package);
}

sub is_loaded {
	my ($class, $package) = @_;
	return(1) if (defined($modules->{ $package }));
	return(0);
}

sub get_info {
	my ($class, $package) = @_;

	return(0) unless (defined($modules->{ $package }));
	return(eval "${package}::module_info;");
}


sub load_plugin {
	my ($class, $file, @params) = @_;

	my $package = module->load("plugin", $file);
	module->call_function($package, "init_plugin", @params);
}


sub register_hook {
	my ($class, $id, $hook, $function, @params) = @_;

	my $package = caller();
	return(0) unless (defined($modules->{ $package }));
	unless (defined($modules->{ $package }->{'hooks'}->{ $hook })) {
		$modules->{ $package }->{'hooks'}->{ $hook } = [ ];
	}
	push(@{ $modules->{ $package }->{'hooks'}->{ $hook } }, {
		'id' => $id,
		'function' => $function,
		'params' => [ @params ]
	});
	return($id);
}

sub unregister_hook {
	my ($class, $id) = @_;

	my $package = caller();
	return(0) unless (defined($modules->{ $package }));
	foreach my $hook (keys(%{ $modules->{ $package }->{'hooks'} })) {
		my $entries = $modules->{ $package }->{'hooks'}->{ $hook };
		foreach my $i (0..$#{ $entries }) {
			if ($entries->[$i]->{'id'} eq $id) {
				splice(@{ $entries }, $i, 1);
				return(0);
			}
		}
	}
	return(0);
}

sub evaluate_hooks {
	my ($class, $hook, @params) = @_;

	foreach my $package (%{ $modules }) {
		if (defined($modules->{ $package }->{'hooks'}->{ $hook })) {
			foreach my $entry (@{ $modules->{ $package }->{'hooks'}->{ $hook } }) {
				module->call_function($package, $entry->{'function'}, ( @{ $entry->{'params'} }, @params ));
			}
		}
	}
}


sub register_command_module {
	my ($class, $command, $file, @params) = @_;

	my $package = module->load("command", $file);
	return(-1) unless ($package);
	$commands->{ $command } = {
		'package' => $package,
		'function' => "do_command",
		'params' => [ @params ]
	};
}

sub register_command_directory {
	my ($class, $dir, @params) = @_;

	$dir =~ s/(\/|\\)$//;
	opendir(DIR, $dir) or return(-1);
	my @files = readdir(DIR);
	closedir(DIR);

	foreach my $file (@files) {
		if ($file =~ /(.*)\.pm$/) {
			module->register_command_module($1, "$dir/$file", @params);
		}
	}
	return(0);
}

sub register_command {
	my ($class, $command, $function, @params) = @_;

	my $package = caller();
	return(-1) unless (defined($modules->{ $package }));
	$commands->{ $command } = {
		'package' => $package,
		'function' => $function,
		'params' => [ @params ]
	};
}

sub unregister_command {
	my ($class, $command) = @_;

	return(-1) unless (defined($commands->{ $command }));
	delete($commands->{ $command });
}

sub evaluate_command {
	my ($class, $command, @params) = @_;

	return(-1) unless (defined($commands->{ $command }));
	my $entry = $commands->{ $command };
	module->call_function($entry->{'package'}, $entry->{'function'}, ( @{ $entry->{'params'} }, @params ));
}


sub register_timer {
	my ($class, $id, $seconds, $function, @params) = @_;

	my $package = caller();
	return(0) unless (defined($modules->{ $package }));

	$modules->{ $package }->{'timers'}->{ $id } = {
		'id' => $id,
		'seconds' => $seconds,
		'start' => time(),
		'function' => $function,
		'params' => [ @params ]
	};
	return(0);
}

sub unregister_timer {
	my ($class, $id) = @_;

	my $package = caller();
	return(0) unless (defined($modules->{ $package }));
	delete($modules->{ $package }->{'timers'}->{ $id });
	return(0);
}

sub reset_timer {
	my ($class, $id, $seconds) = @_;

	my $package = caller();
	return(0) unless (defined($modules->{ $package }));
	$modules->{ $package }->{'timers'}->{ $id }->{'start'} = time();
	$modules->{ $package }->{'timers'}->{ $id }->{'seconds'} = $seconds if ($seconds);
	return(0);
}

sub check_timers {
	my ($class) = @_;

	foreach my $package (keys(%{ $modules })) {
		foreach my $id (keys(%{ $modules->{ $package }->{'timers'} })) {
			my $timer = $modules->{ $package }->{'timers'}->{ $id };
			if ((time() - $timer->{'start'}) >= $timer->{'seconds'}) {
				module->call_function($package, $timer->{'function'}, @{ $timer->{'params'} });
			}
		}
	}
}


sub call_function {
	my ($class, $package, $function, @params) = @_;

	module->check_age($package);
	my $ret = eval "${package}::$function(\@params);";
	status_log($@) if ($@);
	return($ret);
}

sub file_to_name {
	my ($file) = @_;

	$file =~ tr/A-Za-z0-9/_/cs;
	return($file);
}

1;

