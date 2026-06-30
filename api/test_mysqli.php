<?php
header('Content-Type: text/plain');
ob_implicit_flush(true);
ob_end_flush();

echo "Step 1: mysqli_init...\n";
$conn = @mysqli_init();
if (!$conn) { die("mysqli_init failed\n"); }

echo "Step 2: Setting SSL...\n";
@mysqli_ssl_set($conn, null, null, __DIR__ . '/config/certs/isrg-root-x1.pem', null, null);

echo "Step 3: mysqli_real_connect with SSL (timeout 5)...\n";
ini_set('mysql.connect_timeout', 5);
$start = microtime(true);
$r = @mysqli_real_connect($conn, 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com', '36GFbHrVqfx4rvQ.root', '23UIxsPOM3R68jCG', 'cinetracker', 4000, null, MYSQLI_CLIENT_SSL);
$elapsed = microtime(true) - $start;

if ($r) {
    echo "CONNECTED in {$elapsed}s\n";
    $q = mysqli_query($conn, 'SELECT 1 AS test');
    if ($q) {
        $row = mysqli_fetch_assoc($q);
        echo "Query result: "; var_dump($row);
    } else {
        echo "Query failed: " . mysqli_error($conn) . "\n";
    }
    mysqli_close($conn);
} else {
    echo "FAILED in {$elapsed}s: " . mysqli_connect_error() . " (" . mysqli_connect_errno() . ")\n";
}

echo "\nDone.\n";
