<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();
requireRole($userId, 'admin');

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(100, (int) ($_GET['per_page'] ?? 30)));
$action = $_GET['action'] ?? '';
$search = $_GET['search'] ?? '';

$pdo = getDb();

$where = ['1=1'];
$params = [];

if (!empty($action)) {
    $where[] = 'al.action = ?';
    $params[] = $action;
}

if (!empty($search)) {
    $where[] = '(u.name LIKE ? OR u.email LIKE ? OR al.details LIKE ?)';
    $like = "%{$search}%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$whereClause = implode(' AND ', $where);

// Count total
$stmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM admin_logs al LEFT JOIN users u ON u.id = al.admin_id WHERE {$whereClause}");
$stmt->execute($params);
$total = (int) $stmt->fetch()['cnt'];

// Fetch page
$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT al.id, al.action, al.target_type, al.target_id,
           al.details AS description, al.created_at,
           u.name AS admin_name
    FROM admin_logs al
    LEFT JOIN users u ON u.id = al.admin_id
    WHERE {$whereClause}
    ORDER BY al.created_at DESC
    LIMIT ? OFFSET ?
");
$executeParams = array_merge($params, [$perPage, $offset]);
$stmt->execute($executeParams);
$logs = $stmt->fetchAll();

// Get distinct action types for filter dropdown
$stmt = $pdo->query('SELECT DISTINCT action FROM admin_logs ORDER BY action ASC');
$actionTypes = $stmt->fetchAll(PDO::FETCH_COLUMN);

jsonResponse([
    'logs' => $logs,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
    'action_types' => $actionTypes,
]);
