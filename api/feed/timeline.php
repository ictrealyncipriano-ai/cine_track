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

$userId = getAuthUserId();

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$blockFilter = 'AND a.user_id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = ?)';

$countStmt = $pdo->prepare("
    SELECT COUNT(*) as total
    FROM activity_feed a
    WHERE a.user_id IN (SELECT following_id FROM follows WHERE follower_id = ?)
    $blockFilter
");
$countStmt->execute([$userId, $userId]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("
    SELECT a.id, a.user_id, a.action_type, a.target_type, a.target_id, a.metadata, a.created_at,
           u.name as user_name, u.username as user_username, u.avatar_url as user_avatar
    FROM activity_feed a
    JOIN users u ON u.id = a.user_id
    WHERE a.user_id IN (SELECT following_id FROM follows WHERE follower_id = ?)
    $blockFilter
    ORDER BY a.created_at DESC
    LIMIT $perPage OFFSET $offset
");
$stmt->execute([$userId, $userId]);
$activities = $stmt->fetchAll();

$mapped = array_map(function ($row) {
    return [
        'id' => (int) $row['id'],
        'action_type' => $row['action_type'],
        'target_type' => $row['target_type'],
        'target_id' => $row['target_id'] ? (int) $row['target_id'] : null,
        'metadata' => $row['metadata'] ? json_decode($row['metadata'], true) : null,
        'created_at' => $row['created_at'],
        'user' => [
            'id' => (int) $row['user_id'],
            'name' => $row['user_name'],
            'username' => $row['user_username'],
            'avatar_url' => $row['user_avatar'],
        ],
    ];
}, $activities);

jsonResponse([
    'activities' => $mapped,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
