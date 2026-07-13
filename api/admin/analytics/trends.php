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
$granularity = $_GET['granularity'] ?? 'day';

$days = match ($range) {
    '7d' => 6,
    '30d' => 29,
    '90d' => 89,
    default => 13,
};

$dateGroup = match ($granularity) {
    'week' => "DATE_FORMAT(created_at, '%Y-%u')",
    'month' => "DATE_FORMAT(created_at, '%Y-%m')",
    default => "DATE(created_at)",
};

$pdo = getDb();

$stmt = $pdo->prepare("
    SELECT {$dateGroup} AS date, COUNT(*) AS cnt
    FROM users
    WHERE deleted_at IS NULL AND created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
    GROUP BY {$dateGroup}
    ORDER BY date ASC
");
$stmt->execute([$days]);
$registrations = $stmt->fetchAll();

$stmt = $pdo->prepare("
    SELECT {$dateGroup} AS date, COUNT(*) AS cnt
    FROM reviews
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
    GROUP BY {$dateGroup}
    ORDER BY date ASC
");
$stmt->execute([$days]);
$reviewsPerDay = $stmt->fetchAll();

$stmt = $pdo->query("SELECT status, COUNT(*) AS cnt FROM reviews GROUP BY status");
$reviewStatuses = $stmt->fetchAll();

$stmt = $pdo->query("
    SELECT r.status, AVG(TIMESTAMPDIFF(HOUR, r.created_at, r.moderated_at)) AS avg_hours
    FROM reviews r
    WHERE r.moderated_at IS NOT NULL
    GROUP BY r.status
");
$moderationTime = $stmt->fetchAll();

$stmt = $pdo->prepare("
    SELECT movie_id, MAX(title) AS title, MAX(poster_path) AS poster_path, COUNT(*) AS total_interactions
    FROM (
        SELECT movie_id, NULL AS title, NULL AS poster_path FROM reviews WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        UNION ALL
        SELECT movie_id, title, poster_path FROM favorites WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        UNION ALL
        SELECT movie_id, title, poster_path FROM watchlist WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
    ) AS all_interactions
    WHERE movie_id IS NOT NULL
    GROUP BY movie_id
    ORDER BY total_interactions DESC
    LIMIT 20
");
$stmt->execute([$days, $days]);
$topMovies = $stmt->fetchAll();

jsonResponse([
    'registrations' => $registrations,
    'reviews_per_day' => $reviewsPerDay,
    'review_statuses' => $reviewStatuses,
    'moderation_time' => $moderationTime,
    'top_movies' => $topMovies,
    'range' => $range,
    'granularity' => $granularity,
]);
