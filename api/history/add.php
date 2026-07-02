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

try {
    $pdo = getDb();
    $stmt = $pdo->prepare('
        INSERT INTO watch_history (user_id, movie_id, title, overview, poster_path, backdrop_path, release_date, vote_average, watched_at, watch_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), 1)
        ON DUPLICATE KEY UPDATE watched_at = NOW(), watch_count = watch_count + 1
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
} catch (\PDOException $e) {
    jsonError('Failed to add to watch history', 500);
}
