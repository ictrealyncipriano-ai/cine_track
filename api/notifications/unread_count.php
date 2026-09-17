<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

$pdo = getDb();

$stmt = $pdo->prepare('SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND read_at IS NULL');
$stmt->execute([$userId]);
$row = $stmt->fetch();

jsonResponse(['count' => (int) $row['count']]);
