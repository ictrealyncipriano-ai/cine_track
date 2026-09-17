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

if (empty($input['list_id']) || empty($input['movie_id'])) {
    jsonError('list_id and movie_id are required');
}

$listId = (int) $input['list_id'];
$movieId = (int) $input['movie_id'];

$pdo = getDb();

$stmt = $pdo->prepare('SELECT user_id FROM user_lists WHERE id = ?');
$stmt->execute([$listId]);
$list = $stmt->fetch();

if (!$list) {
    jsonError('List not found', 404);
}

if ((int) $list['user_id'] !== $userId) {
    jsonError('Forbidden', 403);
}

$stmt = $pdo->prepare('DELETE FROM list_movies WHERE list_id = ? AND movie_id = ?');
$stmt->execute([$listId, $movieId]);

jsonResponse(['success' => true]);
