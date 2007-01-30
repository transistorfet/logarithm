#
# Command Name:	topic.pm
#

use csv;

my $module_info = {
	'help' => [
		"Usage: topic [<category>]",
		"Description: Displays a random topic (from category if specified)"
	]
};

my $config_dir = "../etc";
my $topics = { };

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = lc($msg->{'args'}->[0]);
	return(0) unless ($channel =~ /^#/);

	unless (defined($topics->{ $channel })) {
		(my $dir = $channel) =~ s/^#+//;
		$topics->{ $channel } = csv->open_file("$config_dir/$dir/topics.lst", ':', 1);
		return(-1) unless ($topics->{ $channel });
	}

	my ($topic, $number);
	my $category = (scalar(@{ $msg->{'args'} }) == 2) ? $msg->{'args'}->[1] : undef;
	if ($category =~ /\s*(\d+)\s*/) {
		$number = $1;
		my @entry = $topics->{ $channel }->get_entry($number);
		$topic = $entry[1];
	}
	elsif (defined($category)) {
		my @list = $topics->{ $channel }->find_all_entries($category);
		$number = int(rand(scalar(@list)));
		$topic = $list[$number]->[1];
	}
	else {
		$number = int(rand($topics->{ $channel }->get_size()));
		my @entry = $topics->{ $channel }->get_entry($number);
		$topic = $entry[1];
	}

	if ($topic) {
		$irc->private_msg($msg->{'respond'}, "[$number] " . $topic);
	}
	else {
		$irc->notice($msg->{'nick'}, "Sorry, No Such Topic");
	}
	return(0);
}
