<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$userId = getAuthUserId();

$pdo = getDb();
$stmt = $pdo->prepare('SELECT movie_id, title, overview, poster_path, backdrop_path, release_date, vote_average, created_at FROM watchlist WHERE user_id = ? ORDER BY created_at DESC');
$stmt->execute([$userId]);
$watchlist = $stmt->fetchAll();

jsonResponse(['watchlist' => $watchlist]);
