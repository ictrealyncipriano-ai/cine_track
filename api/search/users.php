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

$q = trim($_GET['q'] ?? '');
if (strlen($q) < 2) {
    jsonError('Search query must be at least 2 characters');
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$likeParam = '%' . $q . '%';

$countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE (name LIKE ? OR username LIKE ?) AND deleted_at IS NULL");
$countStmt->execute([$likeParam, $likeParam]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("
    SELECT id, name, username, avatar_url, created_at
    FROM users
    WHERE (name LIKE ? OR username LIKE ?) AND deleted_at IS NULL
    ORDER BY name ASC
    LIMIT $perPage OFFSET $offset
");
$stmt->execute([$likeParam, $likeParam]);
$users = $stmt->fetchAll();

jsonResponse([
    'users' => $users,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
