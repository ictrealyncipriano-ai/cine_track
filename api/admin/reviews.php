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
requireRole($userId, 'admin', 'moderator');

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(100, (int) ($_GET['per_page'] ?? 20)));
$status = $_GET['status'] ?? 'pending';

$pdo = getDb();

$where = [];
$params = [];

if ($status !== 'all') {
    $allowedStatuses = ['pending', 'approved', 'rejected', 'reported'];
    if (in_array($status, $allowedStatuses)) {
        $where[] = 'r.status = ?';
        $params[] = $status;
    }
}

$whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

// Count
$stmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM reviews r {$whereClause}");
$stmt->execute($params);
$total = (int) $stmt->fetch()['cnt'];

// Fetch
$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT r.id, r.user_id, r.movie_id, r.rating, r.review_text, r.status,
           r.moderated_by, r.moderated_at, r.moderation_note, r.created_at, r.updated_at,
           u.name AS user_name, u.username AS user_username, u.avatar_url AS user_avatar,
           m.name AS moderator_name,
           rr.report_reason
    FROM reviews r
    LEFT JOIN users u ON u.id = r.user_id
    LEFT JOIN users m ON m.id = r.moderated_by
    LEFT JOIN (
        SELECT review_id, GROUP_CONCAT(reason SEPARATOR '; ') AS report_reason
        FROM review_reports
        GROUP BY review_id
    ) rr ON rr.review_id = r.id
    {$whereClause}
    ORDER BY r.created_at DESC
    LIMIT ? OFFSET ?
");
$executeParams = array_merge($params, [$perPage, $offset]);
$stmt->execute($executeParams);
$reviews = $stmt->fetchAll();

// Cast ints
foreach ($reviews as &$r) {
    $r['id'] = (int) $r['id'];
    $r['user_id'] = (int) $r['user_id'];
    $r['movie_id'] = (int) $r['movie_id'];
    $r['rating'] = (int) $r['rating'];
}
unset($r);

jsonResponse([
    'reviews' => $reviews,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
