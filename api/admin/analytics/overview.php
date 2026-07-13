<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonError('Method not allowed', 405);

$userId = getAuthUserId();
requireRole($userId, 'admin', 'moderator');

$range = $_GET['range'] ?? '14d';
$days = match ($range) {
    '7d' => 6,
    '30d' => 29,
    '90d' => 89,
    default => 13,
};

$pdo = getDb();

$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL");
$totalUsers = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL AND DATE(created_at) = CURDATE()");
$newToday = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL AND created_at >= DATE_SUB(NOW(), INTERVAL $days DAY)");
$newInRange = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("
    SELECT COUNT(DISTINCT u.id) AS cnt
    FROM users u
    LEFT JOIN reviews r ON r.user_id = u.id AND r.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    LEFT JOIN login_audit la ON la.user_id = u.id AND la.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    WHERE u.deleted_at IS NULL AND (r.id IS NOT NULL OR la.id IS NOT NULL)
");
$active7d = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM reviews");
$totalReviews = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("
    SELECT COUNT(DISTINCT movie_id) AS cnt FROM (
        SELECT movie_id FROM reviews UNION
        SELECT movie_id FROM favorites UNION
        SELECT movie_id FROM watchlist UNION
        SELECT movie_id FROM watch_history
    ) AS all_movies
");
$totalMovies = (int) $stmt->fetch()['cnt'];

$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM reviews WHERE status = 'pending'");
$pendingReviews = (int) $stmt->fetch()['cnt'];

jsonResponse([
    'total_users' => $totalUsers,
    'new_today' => $newToday,
    'new_in_range' => $newInRange,
    'active_7d' => $active7d,
    'total_reviews' => $totalReviews,
    'total_movies' => $totalMovies,
    'pending_reviews' => $pendingReviews,
    'range' => $range,
]);
