<html>
<head>
<title>Urls</title>
</head>
<body>

<?php
	require_once("links.inc");

	$channel = $_GET['channel'];
	if ($channel) {
		print_links("../etc/$channel/url.lst");
	}
?>

</body>
</html>

