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

$pdo = getDb();

// Total users (excl. soft-deleted)
$stmt = $pdo->query('SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL');
$totalUsers = (int) $stmt->fetch()['cnt'];

// New users today
$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL AND DATE(created_at) = CURDATE()");
$newToday = (int) $stmt->fetch()['cnt'];

// Active users in last 7 days (have a review or login)
$stmt = $pdo->query('
    SELECT COUNT(DISTINCT u.id) AS cnt
    FROM users u
    LEFT JOIN reviews r ON r.user_id = u.id AND r.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    LEFT JOIN login_audit la ON la.user_id = u.id AND la.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    WHERE u.deleted_at IS NULL
      AND (r.id IS NOT NULL OR la.id IS NOT NULL)
');
$active7d = (int) $stmt->fetch()['cnt'];

// Total reviews
$stmt = $pdo->query('SELECT COUNT(*) AS cnt FROM reviews');
$totalReviews = (int) $stmt->fetch()['cnt'];

// Recent activity (last 20 admin_logs) — column aliases match Dart field names
$stmt = $pdo->query('
    SELECT al.id, al.action AS action_type, al.target_type, al.target_id,
           al.details AS description, al.created_at,
           u.name AS user_name
    FROM admin_logs al
    LEFT JOIN users u ON u.id = al.admin_id
    ORDER BY al.created_at DESC
    LIMIT 20
');
$recentActivity = $stmt->fetchAll();

// Recent reviews needing attention
$stmt = $pdo->query("
    SELECT r.id, r.rating, r.review_text, r.status, r.created_at,
           u.name AS user_name
    FROM reviews r
    LEFT JOIN users u ON u.id = r.user_id
    WHERE r.status IN ('pending','reported')
    ORDER BY r.created_at DESC
    LIMIT 10
");
$pendingReviewList = $stmt->fetchAll();

jsonResponse([
    'stats' => [
        'total_users' => $totalUsers,
        'new_today' => $newToday,
        'active_7d' => $active7d,
        'total_reviews' => $totalReviews,
    ],
    'recent_activity' => $recentActivity,
    'pending_reviews_list' => $pendingReviewList,
]);
