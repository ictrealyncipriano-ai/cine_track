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

$pdo = getDb();

$stmt = $pdo->prepare('DELETE FROM fcm_tokens WHERE user_id = ? AND token = ?');
$stmt->execute([$userId, $input['token']]);

jsonResponse(['success' => true]);
