<?php

require_once("misc.inc");

$log_dir = "/home/logarithm/logs";

function print_chat ($channel, $logs) {
	if (isset($_POST['chat_say'])) {
		say_chat($channel, $_POST['chat_text']);
	}
	print_chat_logs($channel, $_GET['date'], $logs);
	if (isset($_COOKIE['user_name'])) {
		echo("<form method=\"POST\">\n");
		echo("<input type=\"text\" name=\"chat_text\" size=\"80\">\n");
		echo("<input type=\"submit\" name=\"chat_say\" value=\"say\">\n");
		echo("</form>\n");
	}
}

function print_chat_logs ($channel, $date, $logs) {
	global $log_dir;
	if (!$channel) {
		return(false);
	}
	$date = $date ? $date : date("y-m-d");
	$logs = $logs ? $logs : $log_dir;
	$_GET['date'] = date("y-m-d", strtotime("-1 day", strtotime($date)));
	$yest_link = build_query($_SERVER['PHP_SELF'], $_GET);
	$filename = "$logs/$channel/$date.txt";
	if (file_exists($filename) && ($file = fopen($filename, "r"))) {
		echo("<a href=\"$yest_link\">Yesterday's Logs</a><br>\n");
		echo("<table>\n");
		while ($line = fgets($file)) {
			$line = rtrim($line);
			$line = str_replace("<", "&lt;", $line);
			$line = str_replace(">", "&gt;", $line);
			echo("<tr><td>$line</td></tr>\n");
		}
		echo("</table>\n");
		fclose($file);
		return(true);
	}
	return(false);
}

function say_chat ($channel, $text) {

}

?>
