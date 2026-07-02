<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

try {
    $pdo = getDb();
    $stmt = $pdo->prepare('DELETE FROM watch_history WHERE user_id = ?');
    $stmt->execute([$userId]);

    jsonResponse(['success' => true, 'deleted' => $stmt->rowCount()]);
} catch (\PDOException $e) {
    jsonError('Failed to clear watch history', 500);
}
