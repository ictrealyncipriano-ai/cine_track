<?php
$host = 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com';
$port = 4000;

echo "Test 1: TCP connect, read 10s...\n";
$start = microtime(true);
$fp = @stream_socket_client("tcp://$host:$port", $e, $s, 5);
if ($fp) {
    echo "Connected in " . (microtime(true) - $start) . "s\n";
    stream_set_timeout($fp, 10);
    $d = @fread($fp, 4096);
    echo "Read: " . strlen($d) . " bytes in " . (microtime(true) - $start) . "s\n";
    if (strlen($d) > 0) echo "Hex: " . bin2hex($d) . "\n";
    else echo "Server sent no data (timeout or hang)\n";
    fclose($fp);
} else {
    echo "FAIL: $s ($e)\n";
}
echo "Done.\n";
