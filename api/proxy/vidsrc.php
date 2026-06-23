<?php
header('Content-Type: text/html; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$tmdb = isset($_GET['tmdb']) ? (int) $_GET['tmdb'] : 0;

if ($tmdb <= 0) {
    http_response_code(400);
    echo '<html><body><h2>Missing tmdb parameter</h2></body></html>';
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Stream</title>
<style>
* { margin: 0; padding: 0; }
html, body { width: 100%; height: 100%; background: #111; overflow: hidden; color: #fff; font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; text-align: center; padding: 20px; box-sizing: border-box; }
a { color: #FFC107; }
p { opacity: 0.8; margin-top: 8px; font-size: 14px; }
</style>
</head>
<body>
<div>
<h2>VidSrc source unavailable</h2>
<p>VidSrc.net is no longer reachable. Use the 2Embed or GDrive Player source instead.</p>
<p style="margin-top:20px;font-size:12px;opacity:0.5;">TMDB: <?php echo $tmdb; ?></p>
</div>
</body>
</html>
