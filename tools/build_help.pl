#
# Script Name:	build_help.pl
# Description:	Build the help webpage using the help text embedded in the source code
#

use strict;
use warnings;

my $plugin_dir = "../src/Plugins";
my $output = "help.html";

my $list = { };

main();
exit(0);

sub main {
	opendir(DIR, $plugin_dir);
	my @plugins = readdir(DIR);
	closedir(DIR);

	foreach my $name (@plugins) {
		if (-d "$plugin_dir/$name/Commands") {
			$list->{ $name } = { Name => $name, Commands => { } };
			process_commands($name, "$plugin_dir/$name/Commands");
		}
	}
	write_html($output);
}

sub process_commands {
	my ($name, $dir) = @_;

	opendir(DIR, $dir);
	my @cmds = readdir(DIR);
	closedir(DIR);

	foreach my $cmd (@cmds) {
		next unless ($cmd =~ /^(.*)\.pm$/);
		my $cmdname = $1;
		my $info = read_help("$dir/$cmd");
		$list->{ $name }->{Commands}->{ $cmdname } = $info;
	}
}

sub read_help {
	my ($file) = @_;

	my $read = 0;
	my @help;
	open(FILE, $file) or die "Unable to open $file";
	while (my $line = <FILE>) {
		push(@help, $line) if ($read);
		if (!$read and $line =~ /^\s*sub\s+get_info\s*{/) {
			$read = 1;
			push(@help, $line);
		}
		elsif ($read and $line =~ /^\s*}}/) {
			last;
		}
	}
	close(FILE);

	my $code = join("\n", @help, "get_info();");
	my $result = eval $code;
	print $@ if ($@);
	return($result);
}


sub write_html {
	my ($file) = @_;

	open(FILE, ">$file") or die "Unable to open output file $file";
	print FILE "<html>\n<head>\n<title>Logarithm's Page</title>\n</head>\n<body>\n\n";
	print FILE "<h2>Logarithm's Page</h2>\n";
	print FILE "<hr>\n";
	print FILE "<p>Hello and Welcome to My Page.  I don't say much but I mantain the <a href=\"logs.php\">logs</a> for the channel.  I also do stuff for people.\n\n";
	foreach my $plugin (sort(keys(%{ $list }))) {
		my $name = ucfirst($plugin);
		print FILE "<h3>$name</h3>\n";
		print FILE "<table border=1>\n";
		print FILE "<tr><td><b>Command</b></td><td><b>Access</b></td><td><b>Description</b></td></tr>\n";
		foreach my $cmd (sort(keys(%{ $list->{ $plugin }->{Commands} }))) {
			my $info = $list->{ $plugin }->{Commands}->{ $cmd };
			my $help = format_help(@{ $info->{'help'} });
			my $access = $info->{'access'};
			print FILE "<tr><td>$cmd</td><td>$access</td><td>$help</td></tr>\n";
		}
		print FILE "</table>\n";
	}
	print FILE "<br><hr>\n";
	print FILE "<p><a href=\"./\">Home</a><br>\n";
	print FILE "<a href=\"http://jabberwocky.ca/\">The Jabberwocky Network</a><br>\n";
	print FILE "<a href=\"mailto:logarithm\@jabberwocky.ca\"><i>&lt;logarithm\@jabberwocky.ca&gt;</i></a><br>\n";
	print FILE "\n</body>\n</html>\n";
	close(FILE);
}

sub format_help {
	my (@help) = @_;

	for my $i (0..$#help) {
		$help[$i] =~ s/&/&amp;/g;
		$help[$i] =~ s/</&lt;/g;
		$help[$i] =~ s/>/&gt;/g;
	}
	return(join("<br>\n", @help));
}

