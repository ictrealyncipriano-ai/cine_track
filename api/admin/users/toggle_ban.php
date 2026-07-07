<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$adminId = getAuthUserId();
requireRole($adminId, 'admin');

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['user_id'])) {
    jsonError('user_id is required');
}

$targetUserId = (int) $input['user_id'];
$banned = !empty($input['banned']);

$pdo = getDb();

if ($targetUserId === $adminId) {
    jsonError('Cannot ban yourself', 403);
}

$stmt = $pdo->prepare('SELECT id FROM users WHERE id = ? AND deleted_at IS NULL');
$stmt->execute([$targetUserId]);
if (!$stmt->fetch()) {
    jsonError('User not found', 404);
}

if ($banned) {
    $stmt = $pdo->prepare('UPDATE users SET banned_at = NOW(), updated_at = NOW() WHERE id = ?');
    $stmt->execute([$targetUserId]);
    logAdminAction($adminId, 'ban', 'user', $targetUserId, 'User banned');
    jsonResponse(['success' => true, 'banned' => true]);
} else {
    $stmt = $pdo->prepare('UPDATE users SET banned_at = NULL, updated_at = NOW() WHERE id = ?');
    $stmt->execute([$targetUserId]);
    logAdminAction($adminId, 'unban', 'user', $targetUserId, 'User unbanned');
    jsonResponse(['success' => true, 'banned' => false]);
}
