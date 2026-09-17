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

if (isBanned($userId)) {
    jsonError('Your account has been suspended', 403);
}

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['user_id'])) {
    jsonError('user_id is required');
}

$targetId = (int) $input['user_id'];

if ($targetId === $userId) {
    jsonError('Cannot block yourself');
}

$pdo = getDb();

$targetUser = getUserById($targetId);
if (!$targetUser || $targetUser['deleted_at'] !== null) {
    jsonError('User not found', 404);
}

$stmt = $pdo->prepare('SELECT 1 FROM user_blocks WHERE blocker_id = ? AND blocked_id = ?');
$stmt->execute([$userId, $targetId]);
$alreadyBlocked = (bool) $stmt->fetch();

if ($alreadyBlocked) {
    $stmt = $pdo->prepare('DELETE FROM user_blocks WHERE blocker_id = ? AND blocked_id = ?');
    $stmt->execute([$userId, $targetId]);
    jsonResponse(['success' => true, 'blocking' => false]);
}

$stmt = $pdo->prepare('INSERT INTO user_blocks (blocker_id, blocked_id) VALUES (?, ?)');
$stmt->execute([$userId, $targetId]);

jsonResponse(['success' => true, 'blocking' => true]);
