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

if (empty($input['movie_id'])) {
    jsonError('movie_id is required');
}

$pdo = getDb();
$stmt = $pdo->prepare('
    INSERT INTO watchlist (user_id, movie_id, title, overview, poster_path, backdrop_path, release_date, vote_average)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE title = VALUES(title), overview = VALUES(overview), poster_path = VALUES(poster_path), backdrop_path = VALUES(backdrop_path), release_date = VALUES(release_date), vote_average = VALUES(vote_average)
');
$stmt->execute([
    $userId,
    (int) $input['movie_id'],
    $input['title'] ?? '',
    $input['overview'] ?? '',
    $input['poster_path'] ?? null,
    $input['backdrop_path'] ?? null,
    $input['release_date'] ?? '',
    (float) ($input['vote_average'] ?? 0),
]);

jsonResponse(['success' => true]);
