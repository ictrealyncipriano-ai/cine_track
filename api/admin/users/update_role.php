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
$newRole = $input['role'] ?? '';

if (!in_array($newRole, ['user', 'moderator', 'admin'])) {
    jsonError('Invalid role. Allowed: user, moderator, admin');
}

$pdo = getDb();

// Prevent self-demotion
if ($targetUserId === $adminId) {
    jsonError('Cannot change your own role', 403);
}

$stmt = $pdo->prepare('SELECT name, role FROM users WHERE id = ? AND deleted_at IS NULL');
$stmt->execute([$targetUserId]);
$target = $stmt->fetch();

if (!$target) {
    jsonError('User not found', 404);
}

$stmt = $pdo->prepare('UPDATE users SET role = ?, updated_at = NOW() WHERE id = ?');
$stmt->execute([$newRole, $targetUserId]);

$oldRole = $target['role'] ?? 'unknown';
logAdminAction($adminId, 'update_role', 'user', $targetUserId, "Role changed from {$oldRole} to {$newRole}");

jsonResponse(['success' => true, 'role' => $newRole]);
