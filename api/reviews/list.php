<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$movieId = (int) ($_GET['movie_id'] ?? 0);
if ($movieId <= 0) {
    jsonError('movie_id is required');
}

$pdo = getDb();

$stmt = $pdo->prepare('
    SELECT r.id, r.user_id, r.movie_id, r.rating, r.review_text, r.created_at, r.updated_at, u.name as user_name
    FROM reviews r
    JOIN users u ON u.id = r.user_id
    WHERE r.movie_id = ?
    ORDER BY r.created_at DESC
');
$stmt->execute([$movieId]);
$reviews = $stmt->fetchAll();

$summaryStmt = $pdo->prepare('SELECT AVG(rating) as average, COUNT(*) as count FROM reviews WHERE movie_id = ?');
$summaryStmt->execute([$movieId]);
$summary = $summaryStmt->fetch();

$userReview = null;
$headers = getallheaders();
$auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
$token = str_replace('Bearer ', '', $auth);

if (!empty($token)) {
    $tokenStmt = $pdo->prepare('SELECT user_id FROM api_tokens WHERE token = ? AND (expires_at IS NULL OR expires_at > NOW())');
    $tokenStmt->execute([$token]);
    $tokenRow = $tokenStmt->fetch();

    if ($tokenRow) {
        $userId = (int) $tokenRow['user_id'];
        $userStmt = $pdo->prepare('
            SELECT r.id, r.user_id, r.movie_id, r.rating, r.review_text, r.created_at, r.updated_at, u.name as user_name
            FROM reviews r
            JOIN users u ON u.id = r.user_id
            WHERE r.movie_id = ? AND r.user_id = ?
        ');
        $userStmt->execute([$movieId, $userId]);
        $userReview = $userStmt->fetch();
        if ($userReview === false) {
            $userReview = null;
        }
    }
}

jsonResponse([
    'reviews' => $reviews,
    'summary' => [
        'average' => $summary['average'] ? round((float) $summary['average'], 1) : null,
        'count' => (int) $summary['count'],
    ],
    'user_review' => $userReview,
]);
