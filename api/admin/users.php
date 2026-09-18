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

$where = ['u.deleted_at IS NULL'];
$params = [];

if (!empty($search)) {
    $where[] = '(u.name LIKE ? OR u.username LIKE ? OR u.email LIKE ?)';
    $like = "%{$search}%";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if (!empty($role)) {
    $where[] = 'u.role = ?';
    $params[] = $role;
}

$whereClause = implode(' AND ', $where);

// Count total
$stmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM users u WHERE {$whereClause}");
$stmt->execute($params);
$total = (int) $stmt->fetch()['cnt'];

// Fetch page
$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT u.id, u.name, u.username, u.email, u.phone, u.country, u.role,
           u.avatar_url, u.banned_at,
           CASE WHEN u.email_verified_at IS NOT NULL THEN 1 ELSE 0 END AS email_verified,
           u.created_at, u.updated_at,
           COALESCE(f.cnt, 0) AS favorites_count,
           COALESCE(w.cnt, 0) AS watchlist_count,
           COALESCE(r.cnt, 0) AS reviews_count,
           COALESCE(h.cnt, 0) AS history_count
    FROM users u
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM favorites GROUP BY user_id) f ON f.user_id = u.id
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM watchlist GROUP BY user_id) w ON w.user_id = u.id
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM reviews GROUP BY user_id) r ON r.user_id = u.id
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM watch_history GROUP BY user_id) h ON h.user_id = u.id
    WHERE {$whereClause}
    ORDER BY u.{$sortBy} {$sortOrder}
    LIMIT ? OFFSET ?
");
foreach ($params as $i => $param) {
    $stmt->bindValue($i + 1, $param, PDO::PARAM_STR);
}
$stmt->bindValue(count($params) + 1, $perPage, PDO::PARAM_INT);
$stmt->bindValue(count($params) + 2, $offset, PDO::PARAM_INT);
$stmt->execute();
$users = $stmt->fetchAll();

// Cast ints
foreach ($users as &$u) {
    $u['id'] = (int) $u['id'];
    $u['favorites_count'] = (int) $u['favorites_count'];
    $u['watchlist_count'] = (int) $u['watchlist_count'];
    $u['reviews_count'] = (int) $u['reviews_count'];
    $u['history_count'] = (int) $u['history_count'];
}
unset($u);

jsonResponse([
    'users' => $users,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
