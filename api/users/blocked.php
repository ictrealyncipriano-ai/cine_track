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

$page = isset($_GET['page']) ? max(1, (int) $_GET['page']) : 1;
$perPage = isset($_GET['per_page']) ? min(50, max(1, (int) $_GET['per_page'])) : 20;
$offset = ($page - 1) * $perPage;

$pdo = getDb();

try {
    $countStmt = $pdo->prepare('SELECT COUNT(*) FROM user_blocks WHERE blocker_id = ?');
    $countStmt->execute([$userId]);
    $total = (int) $countStmt->fetchColumn();
} catch (\Throwable $e) {
    error_log('blocked.php COUNT query failed: ' . $e->getMessage());
    throw $e;
}

try {
    $stmt = $pdo->prepare('
        SELECT u.id, u.name, u.username, u.avatar_url, ub.created_at AS blocked_at
        FROM user_blocks ub
        JOIN users u ON u.id = ub.blocked_id
        WHERE ub.blocker_id = ?
        ORDER BY ub.created_at DESC
        LIMIT ? OFFSET ?
    ');
    $stmt->bindValue(1, $userId, PDO::PARAM_INT);
    $stmt->bindValue(2, $perPage, PDO::PARAM_INT);
    $stmt->bindValue(3, $offset, PDO::PARAM_INT);
    $stmt->execute();
    $blocked = $stmt->fetchAll();
} catch (\Throwable $e) {
    error_log('blocked.php SELECT query failed: ' . $e->getMessage());
    throw $e;
}

jsonResponse([
    'users' => $blocked,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
