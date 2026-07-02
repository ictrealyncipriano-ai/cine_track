<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$userId = getAuthUserId();

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$sortBy = $_GET['sort_by'] ?? 'recent';
$orderClause = match ($sortBy) {
  'title' => 'ORDER BY title ASC',
  'rating' => 'ORDER BY vote_average DESC',
  default => 'ORDER BY created_at DESC',
};

$pdo = getDb();

$countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM watchlist WHERE user_id = ?');
$countStmt->execute([$userId]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("SELECT movie_id, title, overview, poster_path, backdrop_path, release_date, vote_average, created_at FROM watchlist WHERE user_id = ? $orderClause LIMIT $perPage OFFSET $offset");
$stmt->execute([$userId]);
$watchlist = $stmt->fetchAll();

jsonResponse([
    'watchlist' => $watchlist,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
