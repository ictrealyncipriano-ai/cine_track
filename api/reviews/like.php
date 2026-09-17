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

if (empty($input['review_id'])) {
    jsonError('review_id is required');
}

$reviewId = (int) $input['review_id'];

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, user_id FROM reviews WHERE id = ?');
$stmt->execute([$reviewId]);
$review = $stmt->fetch();

if (!$review) {
    jsonError('Review not found', 404);
}

$stmt = $pdo->prepare('SELECT 1 FROM review_likes WHERE review_id = ? AND user_id = ?');
$stmt->execute([$reviewId, $userId]);
$alreadyLiked = (bool) $stmt->fetch();

if ($alreadyLiked) {
    $stmt = $pdo->prepare('DELETE FROM review_likes WHERE review_id = ? AND user_id = ?');
    $stmt->execute([$reviewId, $userId]);
    $liked = false;
} else {
    $stmt = $pdo->prepare('INSERT INTO review_likes (review_id, user_id) VALUES (?, ?)');
    $stmt->execute([$reviewId, $userId]);
    $liked = true;

    if ((int) $review['user_id'] !== $userId) {
        createNotification((int) $review['user_id'], 'review_like', $userId, 'review', $reviewId);
    }
}

$countStmt = $pdo->prepare('SELECT COUNT(*) as count FROM review_likes WHERE review_id = ?');
$countStmt->execute([$reviewId]);
$likesCount = (int) $countStmt->fetch()['count'];

jsonResponse([
    'success' => true,
    'liked' => $liked,
    'likes_count' => $likesCount,
]);
