<?php

function print_links ($urlfile) {
	$depth = 0;
	if (file_exists($urlfile) && ($file = fopen($urlfile, "r"))) {
		while ($entry = fgetcsv($file, 5000, ",")) {
			if ($entry[0]) {
				$diff = $depth - strlen($entry[0]) + 1;
				for ($i = 0;$i < $diff;$i++) {
					echo("</ul>\n");
				}
				$diff = strlen($entry[0]) - $depth - 1;
				for ($i = 0;$i < $diff;$i++) {
					echo("<ul>\n");
				}
				$depth = strlen($entry[0]);
				if ($entry[1]) {
					echo("<b>$entry[1]</b>\n");
					echo("<ul>\n");
				}
			}
			else {
				if ($entry[1]) {
					echo("<li><a href=\"$entry[1]\">$entry[2]</a>");
				}
				else {
					echo("<li>$entry[2]");
				}
				if ($entry[3]) {
					echo("  <font size=1>Posted By $entry[3]</font>");
				}
				echo("</li>\n");
			}
		}
		for ($i = 0;$i < $depth;$i++) {
			echo("</ul>\n");
		}
		fclose($file);
	}
}

function print_add_link_form ($urlfile) {
	$ret = false;
	if (isset($_POST['link_submit']) && $_POST['link_url']) {
		if (add_link("$topic_dir/urls.lst", $_POST['link_url'], $_POST['link_title'], $_POST['link_name'])) {
			$ret = true;
			echo("<font color=\"green\">Link Added Successfully</font>\n");
		}
		else {
			echo("<font color=\"red\">Error Adding Link</font>\n");
		}
	}
	$link_name = $link_name ? $link_name : $_COOKIE['user_name'];
	echo("<form method=POST><table>\n");
	echo("<tr><td>Name</td><td><input type=\"text\" name=\"link_name\" size=20 value=\"$link_name\"></td></tr>\n");
	echo("<tr><td>Title</td><td><input type=\"text\" name=\"link_title\" size=50 value=\"$link_title\"></td></tr>\n");
	echo("<tr><td>URL</td><td><input type=\"text\" name=\"link_url\" size=80 value=\"$link_url\"></td></tr>\n");
	echo("<tr><td></td><td><input type=\"submit\" name=\"link_submit\" value=\"Add\"></td></tr>\n");
	echo("</table></form>\n");
	return(true);
}

function add_link ($urlfile, $url, $title, $user) {
	$title = stripslashes($title);
	if ($file = fopen($urlfile, "a")) {
		fwrite($file, ",$url,$title,$user\n");
		fclose($file);
		return(true);
	}
	return(false);
}

?>
