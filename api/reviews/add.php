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

if (empty($input['movie_id'])) {
    jsonError('movie_id is required');
}

$movieId = (int) $input['movie_id'];
$rating = isset($input['rating']) ? (int) $input['rating'] : 0;

if ($rating < 1 || $rating > 10) {
    jsonError('rating must be between 1 and 10');
}

$reviewText = $input['review_text'] ?? '';

$pdo = getDb();
$stmt = $pdo->prepare('
    INSERT INTO reviews (user_id, movie_id, rating, review_text)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE rating = VALUES(rating), review_text = VALUES(review_text), updated_at = NOW()
');
$stmt->execute([$userId, $movieId, $rating, $reviewText]);

jsonResponse(['success' => true]);
