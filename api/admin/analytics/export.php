<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonError('Method not allowed', 405);

$userId = getAuthUserId();
requireRole($userId, 'admin');

$type = $_GET['type'] ?? 'users';
$range = $_GET['range'] ?? 'all';

$pdo = getDb();

$rows = [];
$headers = [];

switch ($type) {
    case 'users':
        $headers = ['ID', 'Name', 'Email', 'Username', 'Role', 'Country', 'Email Verified', 'Created At', 'Banned At'];
        $where = $range !== 'all' ? "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL " . (int)$range . " DAY)" : "WHERE 1=1";
        $stmt = $pdo->query("SELECT id, name, email, username, role, country, email_verified_at, created_at, banned_at FROM users {$where} ORDER BY created_at DESC");
        $rows = $stmt->fetchAll();
        break;

    case 'reviews':
        $headers = ['ID', 'User ID', 'Movie ID', 'Rating', 'Review Text', 'Status', 'Created At', 'Moderated At'];
        $where = $range !== 'all' ? "WHERE r.created_at >= DATE_SUB(CURDATE(), INTERVAL " . (int)$range . " DAY)" : "WHERE 1=1";
        $stmt = $pdo->query("SELECT r.id, r.user_id, r.movie_id, r.rating, r.review_text, r.status, r.created_at, r.moderated_at FROM reviews r {$where} ORDER BY r.created_at DESC");
        $rows = $stmt->fetchAll();
        break;

    case 'movies':
        $headers = ['Movie ID', 'Title', 'Review Count', 'Favorite Count', 'Watchlist Count', 'Total Interactions'];
        $stmt = $pdo->query("
            SELECT m.tmdb_id, m.title,
                   COALESCE(rev.cnt, 0) AS review_count,
                   COALESCE(fav.cnt, 0) AS favorite_count,
                   COALESCE(wl.cnt, 0) AS watchlist_count,
                   COALESCE(rev.cnt, 0) + COALESCE(fav.cnt, 0) + COALESCE(wl.cnt, 0) AS total
            FROM movies m
            LEFT JOIN (SELECT movie_id, COUNT(*) AS cnt FROM reviews GROUP BY movie_id) rev ON rev.movie_id = m.tmdb_id
            LEFT JOIN (SELECT movie_id, COUNT(*) AS cnt FROM favorites GROUP BY movie_id) fav ON fav.movie_id = m.tmdb_id
            LEFT JOIN (SELECT movie_id, COUNT(*) AS cnt FROM watchlist GROUP BY movie_id) wl ON wl.movie_id = m.tmdb_id
            WHERE m.status != 'archived'
            ORDER BY total DESC
        ");
        $rows = $stmt->fetchAll();
        break;

    default:
        jsonError('Invalid type. Use: users, reviews, movies');
}

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="cine_track_' . $type . '_' . date('Y-m-d') . '.csv"');

// Build column mapping based on type
switch ($type) {
    case 'users':
        $columnMap = [
            'ID' => 'id',
            'Name' => 'name',
            'Email' => 'email',
            'Username' => 'username',
            'Role' => 'role',
            'Country' => 'country',
            'Email Verified' => 'email_verified_at',
            'Created At' => 'created_at',
            'Banned At' => 'banned_at',
        ];
        break;
    case 'reviews':
        $columnMap = [
            'ID' => 'id',
            'User ID' => 'user_id',
            'Movie ID' => 'movie_id',
            'Rating' => 'rating',
            'Review Text' => 'review_text',
            'Status' => 'status',
            'Created At' => 'created_at',
            'Moderated At' => 'moderated_at',
        ];
        break;
    case 'movies':
        $columnMap = [
            'Movie ID' => 'tmdb_id',
            'Title' => 'title',
            'Review Count' => 'review_count',
            'Favorite Count' => 'favorite_count',
            'Watchlist Count' => 'watchlist_count',
            'Total Interactions' => 'total',
        ];
        break;
    default:
        $columnMap = [];
}

$out = fopen('php://output', 'w');
fputcsv($out, $headers);
foreach ($rows as $row) {
    $line = [];
    foreach ($headers as $h) {
        $line[] = $row[$columnMap[$h]] ?? $row[str_replace(' ', '_', $h)] ?? '';
    }
    fputcsv($out, $line);
}
fclose($out);
exit;
