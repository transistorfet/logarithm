<html>
<head>
<title>Urls</title>
</head>
<body>

<?php
	require_once("links.inc");

	if ($channel) {
		print_links("../etc/$channel/url.lst");
	}
?>

</body>
</html>

