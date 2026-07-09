<?php
require_once __DIR__ . '/config/database.php';

header('Content-Type: application/json');

try {
    $pdo = getDb();
    $stmt = $pdo->query('SELECT 1 AS alive');
    $row = $stmt->fetch();
    echo json_encode([
        'status' => 'ok',
        'db' => 'connected',
        'alive' => $row['alive'],
        'php_version' => PHP_VERSION,
    ]);
} catch (\Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'error' => $e->getMessage(),
        'php_version' => PHP_VERSION,
    ]);
}
