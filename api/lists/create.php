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

if (empty($input['name'])) {
    jsonError('name is required');
}

$name = trim($input['name']);
if (strlen($name) > 255) {
    jsonError('name must not exceed 255 characters');
}

$description = $input['description'] ?? null;
$coverPath = $input['cover_path'] ?? null;
$isPublic = isset($input['is_public']) ? ($input['is_public'] ? 1 : 0) : 1;
$isRanked = isset($input['is_ranked']) ? ($input['is_ranked'] ? 1 : 0) : 0;

$pdo = getDb();

$stmt = $pdo->prepare('
    INSERT INTO user_lists (user_id, name, description, cover_path, is_public, is_ranked)
    VALUES (?, ?, ?, ?, ?, ?)
');
$stmt->execute([$userId, $name, $description, $coverPath, $isPublic, $isRanked]);
$listId = (int) $pdo->lastInsertId();

logActivity($userId, 'list_created', 'list', $listId, ['name' => $name]);

jsonResponse(['success' => true, 'id' => $listId]);
