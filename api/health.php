<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'time' => time(),
    'php_version' => PHP_VERSION,
    'env_db_host' => getenv('DB_HOST') ?: '(not set)',
]);
