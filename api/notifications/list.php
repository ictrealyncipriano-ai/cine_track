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

$countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM notifications WHERE user_id = ?');
$countStmt->execute([$userId]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("
    SELECT n.id, n.type, n.target_type, n.target_id, n.metadata, n.read_at, n.created_at,
           u.id as actor_id, u.name as actor_name, u.username as actor_username, u.avatar_url as actor_avatar
    FROM notifications n
    LEFT JOIN users u ON u.id = n.actor_id
    WHERE n.user_id = ?
    ORDER BY n.created_at DESC
    LIMIT $perPage OFFSET $offset
");
$stmt->execute([$userId]);
$notifications = $stmt->fetchAll();

$mapped = array_map(function ($row) {
    return [
        'id' => (int) $row['id'],
        'type' => $row['type'],
        'target_type' => $row['target_type'],
        'target_id' => $row['target_id'] ? (int) $row['target_id'] : null,
        'metadata' => $row['metadata'] ? json_decode($row['metadata'], true) : null,
        'read_at' => $row['read_at'],
        'created_at' => $row['created_at'],
        'actor' => $row['actor_id'] ? [
            'id' => (int) $row['actor_id'],
            'name' => $row['actor_name'],
            'username' => $row['actor_username'],
            'avatar_url' => $row['actor_avatar'],
        ] : null,
    ];
}, $notifications);

jsonResponse([
    'notifications' => $mapped,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
