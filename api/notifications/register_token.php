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

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['token'])) {
    jsonError('token is required');
}

$platform = $input['platform'] ?? 'web';

$pdo = getDb();

$stmt = $pdo->prepare('
    INSERT INTO fcm_tokens (user_id, token, platform)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE platform = VALUES(platform), updated_at = NOW()
');
$stmt->execute([$userId, $input['token'], $platform]);

jsonResponse(['success' => true]);
