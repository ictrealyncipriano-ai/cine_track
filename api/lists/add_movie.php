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

if (empty($input['list_id']) || empty($input['movie_id'])) {
    jsonError('list_id and movie_id are required');
}

$listId = (int) $input['list_id'];
$movieId = (int) $input['movie_id'];

$pdo = getDb();

$stmt = $pdo->prepare('SELECT user_id, name FROM user_lists WHERE id = ?');
$stmt->execute([$listId]);
$list = $stmt->fetch();

if (!$list) {
    jsonError('List not found', 404);
}

if ((int) $list['user_id'] !== $userId) {
    jsonError('Forbidden', 403);
}

$maxPosStmt = $pdo->prepare('SELECT COALESCE(MAX(position), -1) + 1 as next_pos FROM list_movies WHERE list_id = ?');
$maxPosStmt->execute([$listId]);
$nextPos = (int) $maxPosStmt->fetch()['next_pos'];

$stmt = $pdo->prepare('
    INSERT INTO list_movies (list_id, movie_id, title, poster_path, release_date, vote_average, note, position)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE note = VALUES(note)
');
$stmt->execute([
    $listId,
    $movieId,
    $input['title'] ?? '',
    $input['poster_path'] ?? null,
    $input['release_date'] ?? '',
    (float) ($input['vote_average'] ?? 0),
    $input['note'] ?? null,
    isset($input['position']) ? (int) $input['position'] : $nextPos,
]);

logActivity($userId, 'list_added', 'movie', $movieId, ['list_name' => $list['name'], 'list_id' => $listId]);

jsonResponse(['success' => true]);
