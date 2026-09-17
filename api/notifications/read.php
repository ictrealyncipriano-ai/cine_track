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

$pdo = getDb();

if (!empty($input['all'])) {
    $stmt = $pdo->prepare('UPDATE notifications SET read_at = NOW() WHERE user_id = ? AND read_at IS NULL');
    $stmt->execute([$userId]);
    $affected = $stmt->rowCount();
    jsonResponse(['success' => true, 'marked_read' => $affected]);
}

if (empty($input['id'])) {
    jsonError('id or all is required');
}

$notificationId = (int) $input['id'];

$stmt = $pdo->prepare('UPDATE notifications SET read_at = NOW() WHERE id = ? AND user_id = ?');
$stmt->execute([$notificationId, $userId]);

if ($stmt->rowCount() === 0) {
    jsonError('Notification not found', 404);
}

jsonResponse(['success' => true]);
