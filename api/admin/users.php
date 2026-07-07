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
$perPage = max(1, min(100, (int) ($_GET['per_page'] ?? 20)));
$search = $_GET['search'] ?? '';
$role = $_GET['role'] ?? '';
$sortBy = $_GET['sort_by'] ?? 'created_at';
$sortOrder = strtoupper($_GET['sort_order'] ?? 'DESC');

$allowedSortBy = ['id', 'name', 'username', 'email', 'role', 'created_at', 'banned_at'];
if (!in_array($sortBy, $allowedSortBy)) $sortBy = 'created_at';
if (!in_array($sortOrder, ['ASC', 'DESC'])) $sortOrder = 'DESC';

$pdo = getDb();

$where = ['deleted_at IS NULL'];
$params = [];

if (!empty($search)) {
    $where[] = '(name LIKE ? OR username LIKE ? OR email LIKE ?)';
    $like = "%{$search}%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if (!empty($role)) {
    $where[] = 'role = ?';
    $params[] = $role;
}

$whereClause = implode(' AND ', $where);

// Count total
$stmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM users WHERE {$whereClause}");
$stmt->execute($params);
$total = (int) $stmt->fetch()['cnt'];

// Fetch page
$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT id, name, username, email, phone, role, banned_at, email_verified_at, created_at, updated_at
    FROM users
    WHERE {$whereClause}
    ORDER BY {$sortBy} {$sortOrder}
    LIMIT ? OFFSET ?
");
$executeParams = array_merge($params, [$perPage, $offset]);
$stmt->execute($executeParams);
$users = $stmt->fetchAll();

// Cast ints
foreach ($users as &$u) {
    $u['id'] = (int) $u['id'];
}
unset($u);

jsonResponse([
    'users' => $users,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
