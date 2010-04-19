#
# Command Name:	topic.pm
#

package Plugins::topicifier::Commands::topic;

use Misc;
use ListFile;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: topic [<category>]",
		"Description: Displays a random topic (from category if specified)"
	]
}}

my $config_dir = config_dir();

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = lc($msg->{'args'}->[0]);
	return(0) unless ($channel =~ /^#/);

	$irc->{'safp-topics'} = { } unless(defined($irc->{'safp-topics'}));
	my $topics = $irc->{'safp-topics'};

	unless (defined($topics->{ $channel })) {
		(my $dir = $channel) =~ s/^#+//;
		$topics->{ $channel } = ListFile->new("$config_dir/$dir/topics.lst", ':', 1);
		return(-1) unless ($topics->{ $channel });
	}

	my ($topic, $number);
	my $category = (scalar(@{ $msg->{'args'} }) == 2) ? $msg->{'args'}->[1] : undef;
	if ($category =~ /\s*(\d+)\s*/) {
		$number = $1;
		my @entry = $topics->{ $channel }->get($number);
		$topic = $entry[1];
	}
	elsif (defined($category)) {
		my @list = $topics->{ $channel }->find_all($category);
		$number = int(rand(scalar(@list)));
		$topic = $list[$number]->[1];
	}
	else {
		$number = int(rand($topics->{ $channel }->size()));
		my @entry = $topics->{ $channel }->get($number);
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
