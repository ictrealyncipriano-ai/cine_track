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

// ── Stats ────────────────────────────────────────────────────────

// Total users (excl. soft-deleted)
$stmt = $pdo->query('SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL');
$totalUsers = (int) $stmt->fetch()['cnt'];

// New users today
$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL AND DATE(created_at) = CURDATE()");
$newToday = (int) $stmt->fetch()['cnt'];

// New users this week
$stmt = $pdo->query("SELECT COUNT(*) AS cnt FROM users WHERE deleted_at IS NULL AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
$newThisWeek = (int) $stmt->fetch()['cnt'];

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

// Total movies interacted with (across reviews, favorites, watchlist, history)
$stmt = $pdo->query('
    SELECT COUNT(DISTINCT movie_id) AS cnt FROM (
        SELECT movie_id FROM reviews
        UNION
        SELECT movie_id FROM favorites
        UNION
        SELECT movie_id FROM watchlist
        UNION
        SELECT movie_id FROM watch_history
    ) AS all_movies
');
$totalMovies = (int) $stmt->fetch()['cnt'];

// Review status breakdown
$stmt = $pdo->query("
    SELECT status, COUNT(*) AS cnt
    FROM reviews
    GROUP BY status
");
$reviewStatuses = [];
while ($row = $stmt->fetch()) {
    $reviewStatuses[$row['status']] = (int) $row['cnt'];
}

// Pending reviews count (for badge)
$pendingReviewsCount = $reviewStatuses['pending'] ?? 0;

// ── Analytics: Registrations per day (last 14 days) ─────────────
$stmt = $pdo->query("
    SELECT DATE(created_at) AS date, COUNT(*) AS cnt
    FROM users
    WHERE deleted_at IS NULL AND created_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)
    GROUP BY DATE(created_at)
    ORDER BY date ASC
");
$registrations = [];
$regDates = [];
while ($row = $stmt->fetch()) {
    $registrations[] = (int) $row['cnt'];
    $regDates[] = $row['date'];
}

// ── Analytics: Reviews per day (last 14 days) ───────────────────
$stmt = $pdo->query("
    SELECT DATE(created_at) AS date, COUNT(*) AS cnt
    FROM reviews
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)
    GROUP BY DATE(created_at)
    ORDER BY date ASC
");
$reviewsPerDay = [];
$reviewDates = [];
while ($row = $stmt->fetch()) {
    $reviewsPerDay[] = (int) $row['cnt'];
    $reviewDates[] = $row['date'];
}

// ── Top movies (by total interactions: reviews + favorites + watchlist) ──
$stmt = $pdo->query("
    SELECT movie_id,
           MAX(title) AS title,
           MAX(poster_path) AS poster_path,
           COUNT(*) AS total_interactions
    FROM (
        SELECT movie_id, NULL AS title, NULL AS poster_path FROM reviews
        UNION ALL
        SELECT movie_id, title, poster_path FROM favorites
        UNION ALL
        SELECT movie_id, title, poster_path FROM watchlist
    ) AS all_interactions
    WHERE movie_id IS NOT NULL
    GROUP BY movie_id
    ORDER BY total_interactions DESC
    LIMIT 5
");
$topMovies = $stmt->fetchAll();
foreach ($topMovies as &$m) {
    $m['movie_id'] = (int) $m['movie_id'];
    $m['total_interactions'] = (int) $m['total_interactions'];
}
unset($m);

// ── Recent activity (last 20 admin_logs) ─────────────────────────
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

// ── Pending reviews list (for dashboard preview) ─────────────────
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
        'new_this_week' => $newThisWeek,
        'active_7d' => $active7d,
        'total_reviews' => $totalReviews,
        'total_movies' => $totalMovies,
        'pending_reviews' => $pendingReviewsCount,
    ],
    'analytics' => [
        'registrations' => [
            'dates' => $regDates,
            'values' => $registrations,
        ],
        'reviews_per_day' => [
            'dates' => $reviewDates,
            'values' => $reviewsPerDay,
        ],
        'review_statuses' => $reviewStatuses,
    ],
    'top_movies' => $topMovies,
    'recent_activity' => $recentActivity,
    'pending_reviews_list' => $pendingReviewList,
]);
