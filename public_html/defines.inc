<?php

function find_define($def_file, $def) {
	if ($def) {
		$found = 0;
		if (file_exists($def_file) && ($file = fopen($def_file, "r"))) {
			echo("<table>\n");
			while ($entry = fgetcsv($file, 5000, "\t")) {
				if (!strcasecmp($entry[0], $def)) {
					$found = 1;
					echo("<tr><td><b>$entry[0]&nbsp;&nbsp;</b></td><td>$entry[1]</td></tr>\n");
				}
			}
			echo("</table>\n");
			fclose($file);
		}
		if (!($found)) {
			echo("<b>Sorry, $def Not Found</b><br>\n");
		}
		echo("<br><hr><br>\n");
	}
	return(false);
}

?>
