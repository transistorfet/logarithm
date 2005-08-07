
Logarithm Perl IRC Bot
07/08/2005


Installing:
	To install, uncompress the core code into a directory of your choice which
	will create a sub-directory called logarithm with the code.  Uncompress any
	optional modules inside this logarithm directory.  By default, logs will be
	kept in a directory called logs in the directory containing the logarithm
	sub-directory.

	Modify the logarithm/etc/log.conf file to set the nick, nickserv password,
	list of irc servers, and any additional settings you wish to specify.
	Modify the logarithm/etc/access file to contain a line with your nick
	followed by a colon and the number 500 (enabling all possible commands for
	your nick).  Once you start logarithm for the first time, you must run the
	register command on your nick in order to access any functions.

Running:
	To run, cd to the logarithm directory and type
		perl logarithm.pl
	The bot will print the status and while connected, echo the chat messages it
	receives.

Using:
	Logarithm will automatically log all the chat messages in the channels which
	it occupies.  Special commands can be executed by users in the channel.
	Some of these commands require a certain level of access privalleges which is
	a number between 0 and 500.  Each user who is not authorized has a level of
	0.  Logarithm maintains a list of access levels for each channel.  The
	etc/access file contains global access levels.  Anyone who has an access
	level specified in this global file will have that access level in all
	channels.  All other users must be given an access level in each channel.

	Each user must register their nick with logarithm supplying a password and
	optionally specifying a hostmask which is used to identify the user.  The
	user registration is global so a user needs only one password for all
	channels.  The hostmask is your ident and hostname pair of the format
	ident@dns-ip-name.  The * wildcard character can be used when specifying
	the hostmask.  Each user must identify themselves using the id command or
	by irc'ing from the location specified in your hostmask or the user will
	have an access of 0.  The hostmask can be specified using the user command.

	Access number are divided into 6 groups.  Users with an access level of 0
	can run all of the unprivalleged commands such as access, help, id, register,
	and user.  Users with an access of 50-299 are privalleged users and can
	run the say and me commands (200) as well as the commands in the optional
	modules.  The access levels required for specific commands can be specifed
	on a per-channel basis using the option command.  Channel admins have a level
	of 300 and are able to use the option command to change the options for a
	channel.  Privalleged channel admins have an access of 350 and can run the
	add, del, and mod commands to control the access list for the channel.  A
	level greater than that of the user controlling access cannot be set.
	A user with access level of 450 is a Logarithm admin and can run the join
	and leave commands to make logarithm join and leave channels.  A level of
	500 can use the bye command which causes logarithm to terminate.  Only one
	person (you) should have this level.

Options:
	Commands can be allowed or denied for each channel using the options.  By
	setting the 'deny_all' option to 1, all commands can be denied for the
	channel.  If this option is set, the 'allowed' option is checked for any
	commands which are explicitly allowed.  If this option is not set, the
	'denied' option is checked for any commands which are explicitly denied.

	The commands which can use a variable access level will check for an option
	named '<command>_access' and use the value as the access level.


Commands:
	All commands can either be sent to logarithm as a private message or sent to
	the channel occupied by logarithm with a special prefix append to the command
	name.  Certain commands will assume the channel is the current channel if
	one is not provided.  The prefix is '!' by default but can be changed later.

	access [<channel>] [<nick>]
		Outputs the access granted to the nick for the specified channel.  If
		no nick is specified, your nick is assumed.  Your hostmask
		(regardless of whether you specify a nick) is printed in brackets at
		the end of the message.

	add [<channel>] <nick> <access>
		Adds the nick to the access list for the specified channel with the
		specified access level.

	bye
		Terminate logarithm.

	del [<channel>] <nick>
		Delete the nick from the access list for the specified channel.

	help
		Print a list of commands available to the current channel

	id <password>
		Identify yourself to logarithm.

	join <channel>
		Cause logarithm to join the specified channel.

	leave <channel>
		Cause logarithm to leave the specified channel.

	me [<channel>] <message>
		Cause logarithm to output the specified message as an action.

	mod [<channel>] <nick> <access>
		Modify the access level of the specified nick for the specified
		channel.

	option (set|get|add|remove|erase) [<channel>] <option> [<value>]
		Control channel options.  The format of value is either a single
		value or a list of values seperated by commas and surrounded by
		brackets.  For example, a list of "foo" and "bar" would be (foo,bar).

		Set sets the option to the value(s) replacing any previous value.
		Get returns the value(s) of the specified option.
		Add adds the value(s) to the existing list of values for option.
		Remove removes the value(s) from the current list of values.
		Erase deletes the option entirely.

	register <nick> <password>
		Registers the nick with the specified password.

	say [<channel>] <message>
		Cause logarithm to say the specified message.

	user (password|hostmask) <value>
		Changes user options.  You must identified.  Password will change
		the current password for your nick.  Hostmask will change the
		hostmask to use for automatic identification.




