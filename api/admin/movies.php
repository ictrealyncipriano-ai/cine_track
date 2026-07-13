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

$orderField = 'total_interactions';
if ($sortBy === 'reviews') $orderField = 'review_count';
elseif ($sortBy === 'favorites') $orderField = 'favorite_count';
elseif ($sortBy === 'title') $orderField = 'm.title';
elseif ($sortBy === 'last_interaction') $orderField = 'last_interaction';

// Build query with optional search
$where = "WHERE (m.status IS NULL OR m.status != 'archived')";
$params = [];
if (!empty($search)) {
    $where .= ' AND LOWER(m.title) LIKE LOWER(?)';
    $params[] = "%$search%";
}

// Count total matching movies
$countSql = "SELECT COUNT(*) FROM movies m {$where}";
$stmt = $pdo->prepare($countSql);
$stmt->execute($params);
$total = (int) $stmt->fetchColumn();

// Get paginated results with interaction stats
$offset = ($page - 1) * $perPage;
$dataSql = "
    SELECT
        m.id,
        m.tmdb_id AS movie_id,
        m.title,
        m.poster_path,
        m.backdrop_path,
        m.overview,
        m.release_date,
        m.vote_average,
        m.vote_count,
        m.genres,
        m.runtime,
        m.status,
        m.featured,
        m.created_at,
        m.updated_at,
        COALESCE(r.review_count, 0) AS review_count,
        COALESCE(f.favorite_count, 0) AS favorite_count,
        COALESCE(w.watchlist_count, 0) AS watchlist_count,
        COALESCE(r.review_count, 0) + COALESCE(f.favorite_count, 0) + COALESCE(w.watchlist_count, 0) AS total_interactions,
        GREATEST(
            COALESCE(r.last_review, '1970-01-01'),
            COALESCE(f.last_favorite, '1970-01-01'),
            COALESCE(w.last_watchlist, '1970-01-01')
        ) AS last_interaction
    FROM movies m
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS review_count, MAX(created_at) AS last_review FROM reviews GROUP BY movie_id
    ) r ON r.movie_id = m.tmdb_id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS favorite_count, MAX(created_at) AS last_favorite FROM favorites GROUP BY movie_id
    ) f ON f.movie_id = m.tmdb_id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS watchlist_count, MAX(created_at) AS last_watchlist FROM watchlist GROUP BY movie_id
    ) w ON w.movie_id = m.tmdb_id
    {$where}
    ORDER BY {$orderField} {$sortOrder}
    LIMIT ? OFFSET ?
";
$dataParams = array_merge($params, [$perPage, $offset]);
$stmt = $pdo->prepare($dataSql);
$stmt->execute($dataParams);
$movies = $stmt->fetchAll();

foreach ($movies as &$m) {
    $m['movie_id'] = (int) ($m['movie_id'] ?? $m['id']);
    $m['id'] = (int) ($m['id'] ?? 0);
    $m['review_count'] = (int) $m['review_count'];
    $m['favorite_count'] = (int) $m['favorite_count'];
    $m['watchlist_count'] = (int) $m['watchlist_count'];
    $m['total_interactions'] = (int) $m['total_interactions'];
    $m['featured'] = (bool) $m['featured'];
    $m['vote_average'] = (float) $m['vote_average'];
    $m['vote_count'] = (int) $m['vote_count'];
    $m['runtime'] = (int) $m['runtime'];
}
unset($m);

jsonResponse([
    'movies' => $movies,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
