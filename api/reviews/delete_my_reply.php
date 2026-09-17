<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

$input = json_decode(file_get_contents('php://input'), true);
$replyId = (int) ($input['id'] ?? 0);
if ($replyId <= 0) jsonError('id is required');

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, user_id FROM review_replies WHERE id = ?');
$stmt->execute([$replyId]);
$reply = $stmt->fetch();

if (!$reply) jsonError('Reply not found', 404);

if ((int) $reply['user_id'] !== $userId) {
    jsonError('Not your reply', 403);
}

$stmt = $pdo->prepare('DELETE FROM review_replies WHERE id = ?');
$stmt->execute([$replyId]);

jsonResponse(['success' => true]);
