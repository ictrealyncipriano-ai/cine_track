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

$pdo = getDb();

$countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM watch_history WHERE user_id = ?');
$countStmt->execute([$userId]);
$total = (int) $countStmt->fetch()['total'];

$stmt = $pdo->prepare("SELECT movie_id, title, overview, poster_path, backdrop_path, release_date, vote_average, watched_at, watch_count FROM watch_history WHERE user_id = ? ORDER BY watched_at DESC LIMIT $perPage OFFSET $offset");
$stmt->execute([$userId]);
$history = $stmt->fetchAll();

jsonResponse([
    'history' => $history,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
