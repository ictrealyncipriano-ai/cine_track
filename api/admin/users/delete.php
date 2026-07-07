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

$pdo = getDb();

if ($targetUserId === $adminId) {
    jsonError('Cannot delete yourself', 403);
}

$stmt = $pdo->prepare('SELECT id FROM users WHERE id = ? AND deleted_at IS NULL');
$stmt->execute([$targetUserId]);
if (!$stmt->fetch()) {
    jsonError('User not found', 404);
}

$pdo->beginTransaction();
try {
    // Soft-delete user
    $stmt = $pdo->prepare('UPDATE users SET deleted_at = NOW(), updated_at = NOW() WHERE id = ?');
    $stmt->execute([$targetUserId]);

    // Revoke all sessions
    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = ?');
    $stmt->execute([$targetUserId]);

    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    jsonError('Failed to delete user', 500);
}

logAdminAction($adminId, 'delete', 'user', $targetUserId, 'User soft-deleted');

jsonResponse(['success' => true]);
