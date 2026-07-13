<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();
requireRole($userId, 'admin');

$pdo = getDb();

$stmt = $pdo->query('SELECT `key`, `value`, `type`, `label`, `description` FROM app_settings ORDER BY `key`');
$settings = $stmt->fetchAll();

$result = [];
foreach ($settings as $row) {
    $val = $row['value'];
    if ($row['type'] === 'boolean') {
        $val = $val === 'true' || $val === '1';
    } elseif ($row['type'] === 'integer') {
        $val = (int) $val;
    }
    $result[] = [
        'key' => $row['key'],
        'value' => $val,
        'type' => $row['type'],
        'label' => $row['label'],
        'description' => $row['description'],
    ];
}

jsonResponse(['settings' => $result]);
