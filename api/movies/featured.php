<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$pdo = getDb();

$stmt = $pdo->query("
    SELECT id, tmdb_id, title, overview, poster_path, backdrop_path,
           release_date, vote_average, vote_count, genres, runtime
    FROM movies
    WHERE featured = 1 AND status = 'published'
    ORDER BY updated_at DESC
    LIMIT 20
");
$movies = $stmt->fetchAll();

jsonResponse(['movies' => $movies]);
