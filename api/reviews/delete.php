<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$userId = getAuthUserId();

if (isBanned($userId)) {
    jsonError('Your account has been suspended', 403);
}

$input = json_decode(file_get_contents('php://input'), true);
$movieId = (int) ($input['movie_id'] ?? $_GET['movie_id'] ?? 0);

if ($movieId <= 0) {
    jsonError('movie_id is required');
}

$pdo = getDb();

$stmt = $pdo->prepare('SELECT user_id FROM reviews WHERE movie_id = ? AND user_id = ?');
$stmt->execute([$movieId, $userId]);
$review = $stmt->fetch();

if (!$review) {
    jsonError('Review not found or not yours', 404);
}

$stmt = $pdo->prepare('DELETE FROM reviews WHERE movie_id = ? AND user_id = ?');
$stmt->execute([$movieId, $userId]);

jsonResponse(['success' => true]);
