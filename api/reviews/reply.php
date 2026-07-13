<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

checkAndIncrementRateLimit("review_reply:$userId", 10, 5);

$input = json_decode(file_get_contents('php://input'), true);

$reviewId = (int) ($input['review_id'] ?? 0);
$body = trim($input['body'] ?? '');

if ($reviewId <= 0) jsonError('review_id is required');
if (empty($body)) jsonError('body is required');

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id FROM reviews WHERE id = ?');
$stmt->execute([$reviewId]);
if (!$stmt->fetch()) jsonError('Review not found', 404);

$stmt = $pdo->prepare('INSERT INTO review_replies (review_id, user_id, body) VALUES (?, ?, ?)');
$stmt->execute([$reviewId, $userId, $body]);

$replyId = (int) $pdo->lastInsertId();

jsonResponse(['success' => true, 'id' => $replyId]);
