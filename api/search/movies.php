<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$q = trim($_GET['q'] ?? '');
if (strlen($q) < 2) {
    jsonError('Search query must be at least 2 characters');
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$likeParam = '%' . $q . '%';

$conditions = ['(title LIKE ? OR overview LIKE ?)'];
$params = [$likeParam, $likeParam];

if (!empty($_GET['genre'])) {
    $conditions[] = 'genres LIKE ?';
    $params[] = '%' . $_GET['genre'] . '%';
}

if (!empty($_GET['year'])) {
    $year = (int) $_GET['year'];
    $conditions[] = 'release_date LIKE ?';
    $params[] = "$year%";
}

if (!empty($_GET['rating_min'])) {
    $conditions[] = 'vote_average >= ?';
    $params[] = (float) $_GET['rating_min'];
}

if (!empty($_GET['rating_max'])) {
    $conditions[] = 'vote_average <= ?';
    $params[] = (float) $_GET['rating_max'];
}

$whereClause = implode(' AND ', $conditions);

$sortBy = $_GET['sort_by'] ?? 'title';
$orderClause = match ($sortBy) {
    'release_date' => 'ORDER BY release_date DESC',
    'rating' => 'ORDER BY vote_average DESC',
    'created' => 'ORDER BY created_at DESC',
    default => 'ORDER BY title ASC',
};

$countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM movies WHERE $whereClause AND status = 'published'");
$countStmt->execute($params);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("
    SELECT id, tmdb_id, title, overview, poster_path, backdrop_path, release_date,
           vote_average, vote_count, genres, runtime, featured
    FROM movies
    WHERE $whereClause AND status = 'published'
    $orderClause
    LIMIT $perPage OFFSET $offset
");
$stmt->execute($params);
$movies = $stmt->fetchAll();

jsonResponse([
    'movies' => $movies,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
