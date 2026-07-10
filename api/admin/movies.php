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

// Count total distinct movies
$stmt = $pdo->query('
    SELECT COUNT(*) AS cnt FROM (
        SELECT movie_id FROM reviews
        UNION
        SELECT movie_id FROM favorites
        UNION
        SELECT movie_id FROM watchlist
        UNION
        SELECT movie_id FROM watch_history
    ) AS all_movies
    WHERE movie_id IS NOT NULL
');
$total = (int) $stmt->fetch()['cnt'];

// Map sort field
$orderField = 'total_interactions';
if ($sortBy === 'reviews') $orderField = 'review_count';
elseif ($sortBy === 'favorites') $orderField = 'favorite_count';
elseif ($sortBy === 'title') $orderField = 'title';
elseif ($sortBy === 'last_interaction') $orderField = 'last_interaction';

// Get movie stats
$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT
        m.movie_id,
        MAX(COALESCE(m.movie_title, '')) AS title,
        MAX(COALESCE(m.movie_poster, '')) AS poster_path,
        COUNT(DISTINCT m.review_id) AS review_count,
        COUNT(DISTINCT m.favorite_id) AS favorite_count,
        COUNT(DISTINCT m.watchlist_id) AS watchlist_count,
        COUNT(*) AS total_interactions,
        MAX(m.last_date) AS last_interaction
    FROM (
        SELECT r.movie_id, NULL AS movie_title, NULL AS movie_poster, r.id AS review_id, NULL AS favorite_id, NULL AS watchlist_id, r.created_at AS last_date
        FROM reviews r
        UNION ALL
        SELECT f.movie_id, f.title, f.poster_path, NULL, f.id, NULL, f.created_at
        FROM favorites f
        UNION ALL
        SELECT w.movie_id, w.title, w.poster_path, NULL, NULL, w.id, w.created_at
        FROM watchlist w
    ) AS m
    WHERE m.movie_id IS NOT NULL
    GROUP BY m.movie_id
    ORDER BY {$orderField} {$sortOrder}
    LIMIT ? OFFSET ?
");
$stmt->execute([$perPage, $offset]);
$movies = $stmt->fetchAll();

// Apply search filter in PHP (since HAVING on COALESCE/MAX is tricky)
if (!empty($search)) {
    $searchLower = strtolower($search);
    $movies = array_filter($movies, function ($m) use ($searchLower) {
        return str_contains(strtolower($m['title'] ?? ''), $searchLower);
    });
    $total = count($movies);
    // Re-slice after filtering
    $movies = array_slice(array_values($movies), 0, $perPage);
}

foreach ($movies as &$m) {
    $m['movie_id'] = (int) $m['movie_id'];
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
