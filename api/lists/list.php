<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$authUserId = null;
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ')) {
    try {
        $authUserId = getAuthUserId();
    } catch (\Throwable $e) {
        // Not authenticated
    }
}

$profileId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
if ($profileId <= 0) {
    jsonError('user_id is required');
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$isOwner = $authUserId && $authUserId === $profileId;

if ($isOwner) {
    $countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM user_lists WHERE user_id = ?');
    $countStmt->execute([$profileId]);
} else {
    $countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM user_lists WHERE user_id = ? AND is_public = 1');
    $countStmt->execute([$profileId]);
}
$total = (int) $countStmt->fetch()['total'];

if ($isOwner) {
    $stmt = $pdo->prepare("
        SELECT id, name, description, cover_path, is_public, is_ranked, created_at, updated_at
        FROM user_lists
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT $perPage OFFSET $offset
    ");
    $stmt->execute([$profileId]);
} else {
    $stmt = $pdo->prepare("
        SELECT id, name, description, cover_path, is_public, is_ranked, created_at, updated_at
        FROM user_lists
        WHERE user_id = ? AND is_public = 1
        ORDER BY created_at DESC
        LIMIT $perPage OFFSET $offset
    ");
    $stmt->execute([$profileId]);
}
$lists = $stmt->fetchAll();

$mapped = array_map(function ($row) {
    return [
        'id' => (int) $row['id'],
        'name' => $row['name'],
        'description' => $row['description'],
        'cover_path' => $row['cover_path'],
        'is_public' => (bool) $row['is_public'],
        'is_ranked' => (bool) $row['is_ranked'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
    ];
}, $lists);

jsonResponse([
    'lists' => $mapped,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
