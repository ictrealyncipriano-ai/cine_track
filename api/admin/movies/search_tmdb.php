<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();
requireRole($userId, 'admin');

$query = $_GET['q'] ?? '';
if (empty($query)) {
    jsonError('Search query (q) is required', 400);
}

$tmdbKey = getenv('TMDB_API_KEY') ?: '6e7c39152f79deae9cf6c4160eb245fa';
$page = (int) ($_GET['page'] ?? 1);
$url = "https://api.themoviedb.org/3/search/movie?api_key={$tmdbKey}&language=en-US&query=" . urlencode($query) . "&page={$page}";

$response = @file_get_contents($url);
if ($response === false) {
    jsonError('Failed to search TMDB', 502);
}

$data = json_decode($response, true);
if (!$data) {
    jsonError('Invalid response from TMDB', 502);
}

$results = [];
foreach ($data['results'] as $movie) {
    $genreNames = [];
    if (!empty($movie['genre_ids'])) {
        // We don't have genre names from search endpoint, just ids
    }
    $results[] = [
        'tmdb_id' => $movie['id'],
        'title' => $movie['title'] ?? '',
        'overview' => $movie['overview'] ?? '',
        'poster_path' => $movie['poster_path'],
        'backdrop_path' => $movie['backdrop_path'],
        'release_date' => $movie['release_date'] ?? '',
        'vote_average' => $movie['vote_average'] ?? 0,
        'vote_count' => $movie['vote_count'] ?? 0,
    ];
}

jsonResponse([
    'results' => $results,
    'page' => $data['page'],
    'total_pages' => $data['total_pages'],
    'total_results' => $data['total_results'],
]);
