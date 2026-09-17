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

if (empty($input['list_id']) || empty($input['movies']) || !is_array($input['movies'])) {
    jsonError('list_id and movies array are required');
}

$listId = (int) $input['list_id'];

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

$updateStmt = $pdo->prepare('UPDATE list_movies SET position = ? WHERE list_id = ? AND movie_id = ?');

foreach ($input['movies'] as $item) {
    if (!isset($item['movie_id'], $item['position'])) {
        continue;
    }
    $updateStmt->execute([(int) $item['position'], $listId, (int) $item['movie_id']]);
}

jsonResponse(['success' => true]);
