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
requireRole($adminId, 'admin', 'moderator');

$input = json_decode(file_get_contents('php://input'), true);
$replyId = (int) ($input['id'] ?? 0);
if ($replyId <= 0) jsonError('id is required');

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id FROM review_replies WHERE id = ?');
$stmt->execute([$replyId]);
if (!$stmt->fetch()) jsonError('Reply not found', 404);

$stmt = $pdo->prepare('DELETE FROM review_replies WHERE id = ?');
$stmt->execute([$replyId]);

logAdminAction($adminId, 'delete_reply', 'review_reply', $replyId, 'Deleted reply');

jsonResponse(['success' => true]);
