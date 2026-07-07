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

// Total reviews
$stmt = $pdo->query('SELECT COUNT(*) AS cnt FROM reviews');
$totalReviews = (int) $stmt->fetch()['cnt'];

// Pending reviews
$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM reviews WHERE status = 'pending'");
$pendingReviews = (int) $stmt->fetch()['cnt'];

// Reported reviews
$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM reviews WHERE status = 'reported'");
$reportedReviews = (int) $stmt->fetch()['cnt'];

// Recent activity (last 20 admin_logs)
$stmt = $pdo->query('
    SELECT al.id, al.action, al.target_type, al.target_id, al.details, al.created_at,
           u.name AS admin_name
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
    'total_users' => $totalUsers,
    'total_reviews' => $totalReviews,
    'pending_reviews' => $pendingReviews,
    'reported_reviews' => $reportedReviews,
    'recent_activity' => $recentActivity,
    'pending_reviews_list' => $pendingReviewList,
]);
