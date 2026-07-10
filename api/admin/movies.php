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

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(100, (int) ($_GET['per_page'] ?? 20)));
$sortBy = $_GET['sort_by'] ?? 'interactions';
$sortOrder = strtoupper($_GET['sort_order'] ?? 'DESC');
$search = $_GET['search'] ?? '';

$allowedSortBy = ['interactions', 'reviews', 'favorites', 'title', 'last_interaction'];
if (!in_array($sortBy, $allowedSortBy)) $sortBy = 'interactions';
if (!in_array($sortOrder, ['ASC', 'DESC'])) $sortOrder = 'DESC';

// Aggregate all movie interactions from reviews, favorites, watchlist, history
$where = ['1=1'];
$params = [];

if (!empty($search)) {
    $where[] = 'm.title LIKE ?';
    $params[] = "%{$search}%";
}

$whereClause = implode(' AND ', $where);

// Count total distinct movies
$stmt = $pdo->prepare("
    SELECT COUNT(*) AS cnt FROM (
        SELECT tmdb_id FROM reviews
        UNION
        SELECT tmdb_id FROM favorites
        UNION
        SELECT tmdb_id FROM watchlist
        UNION
        SELECT tmdb_id FROM watch_history
    ) AS all_movies
    WHERE tmdb_id IS NOT NULL
");
$stmt->execute();
$total = (int) $stmt->fetch()['cnt'];

// Get movie stats
$orderField = match ($sortBy) {
    'reviews' => 'review_count',
    'favorites' => 'favorite_count',
    'title' => 'title',
    'last_interaction' => 'last_interaction',
    default => 'total_interactions',
};

$stmt = $pdo->prepare("
    SELECT
        m.tmdb_id,
        MAX(COALESCE(m.title, '')) AS title,
        MAX(COALESCE(m.poster_path, '')) AS poster_path,
        COUNT(DISTINCT m.review_id) AS review_count,
        COUNT(DISTINCT m.favorite_id) AS favorite_count,
        COUNT(DISTINCT m.watchlist_id) AS watchlist_count,
        COUNT(*) AS total_interactions,
        MAX(m.last_date) AS last_interaction
    FROM (
        SELECT r.tmdb_id, r.title, r.poster_path, r.id AS review_id, NULL AS favorite_id, NULL AS watchlist_id, r.created_at AS last_date
        FROM reviews r
        UNION ALL
        SELECT f.tmdb_id, f.title, f.poster_path, NULL, f.id, NULL, f.created_at
        FROM favorites f
        UNION ALL
        SELECT w.tmdb_id, w.title, w.poster_path, NULL, NULL, w.id, w.created_at
        FROM watchlist w
    ) AS m
    WHERE m.tmdb_id IS NOT NULL
    GROUP BY m.tmdb_id
    HAVING {$whereClause}
    ORDER BY {$orderField} {$sortOrder}
    LIMIT ? OFFSET ?
");
$offset = ($page - 1) * $perPage;
$executeParams = array_merge($params, [$perPage, $offset]);
$stmt->execute($executeParams);
$movies = $stmt->fetchAll();

foreach ($movies as &$m) {
    $m['tmdb_id'] = (int) $m['tmdb_id'];
    $m['review_count'] = (int) $m['review_count'];
    $m['favorite_count'] = (int) $m['favorite_count'];
    $m['watchlist_count'] = (int) $m['watchlist_count'];
    $m['total_interactions'] = (int) $m['total_interactions'];
}
unset($m);

jsonResponse([
    'movies' => $movies,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
