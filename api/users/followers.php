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

$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
if ($userId <= 0) {
    jsonError('user_id is required');
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM follows WHERE following_id = ?');
$countStmt->execute([$userId]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare('
    SELECT u.id, u.name, u.username, u.avatar_url, f.created_at as followed_at
    FROM follows f
    JOIN users u ON u.id = f.follower_id
    WHERE f.following_id = ?
    ORDER BY f.created_at DESC
    LIMIT $perPage OFFSET $offset
');
$stmt->execute([$userId]);
$followers = $stmt->fetchAll();

jsonResponse([
    'followers' => $followers,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
