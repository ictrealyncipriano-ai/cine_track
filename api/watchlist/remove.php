<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$userId = getAuthUserId();

$input = json_decode(file_get_contents('php://input'), true);
$movieId = (int) ($input['movie_id'] ?? $_GET['movie_id'] ?? 0);

if ($movieId <= 0) {
    jsonError('movie_id is required');
}

$pdo = getDb();
$stmt = $pdo->prepare('DELETE FROM watchlist WHERE user_id = ? AND movie_id = ?');
$stmt->execute([$userId, $movieId]);

jsonResponse(['success' => true]);
