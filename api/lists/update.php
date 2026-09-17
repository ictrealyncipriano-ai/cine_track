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

if (empty($input['id'])) {
    jsonError('id is required');
}

$listId = (int) $input['id'];

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

$fields = [];
$params = [];

if (isset($input['name'])) {
    $name = trim($input['name']);
    if (strlen($name) > 255) {
        jsonError('name must not exceed 255 characters');
    }
    $fields[] = 'name = ?';
    $params[] = $name;
}

if (array_key_exists('description', $input)) {
    $fields[] = 'description = ?';
    $params[] = $input['description'];
}

if (array_key_exists('cover_path', $input)) {
    $fields[] = 'cover_path = ?';
    $params[] = $input['cover_path'];
}

if (isset($input['is_public'])) {
    $fields[] = 'is_public = ?';
    $params[] = $input['is_public'] ? 1 : 0;
}

if (isset($input['is_ranked'])) {
    $fields[] = 'is_ranked = ?';
    $params[] = $input['is_ranked'] ? 1 : 0;
}

if (empty($fields)) {
    jsonError('No fields to update');
}

$params[] = $listId;
$setClause = implode(', ', $fields);

$stmt = $pdo->prepare("UPDATE user_lists SET $setClause WHERE id = ?");
$stmt->execute($params);

jsonResponse(['success' => true]);
