<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$adminId = getAuthUserId();
requireRole($adminId, 'admin');

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    jsonError('Invalid request body', 400);
}

$tmdbId = isset($input['tmdb_id']) ? (int) $input['tmdb_id'] : 0;
if ($tmdbId <= 0) {
    jsonError('tmdb_id is required', 400);
}

$pdo = getDb();

// Check if movie already exists
$stmt = $pdo->prepare('SELECT id FROM movies WHERE tmdb_id = ?');
$stmt->execute([$tmdbId]);
if ($stmt->fetch()) {
    jsonError('Movie with this TMDB ID already exists', 409);
}

// Fetch metadata from TMDB
$tmdbKey = getenv('TMDB_API_KEY') ?: '6e7c39152f79deae9cf6c4160eb245fa';
$tmdbUrl = "https://api.themoviedb.org/3/movie/{$tmdbId}?api_key={$tmdbKey}&language=en-US";
$tmdbResponse = @file_get_contents($tmdbUrl);

$metadata = [];
if ($tmdbResponse !== false) {
    $tmdbData = json_decode($tmdbResponse, true);
    if ($tmdbData && !isset($tmdbData['status_code'])) {
        $genreNames = array_map(function ($g) { return $g['name']; }, $tmdbData['genres'] ?? []);
        $metadata = [
            'title' => $tmdbData['title'] ?? '',
            'overview' => $tmdbData['overview'] ?? null,
            'poster_path' => $tmdbData['poster_path'] ?? null,
            'backdrop_path' => $tmdbData['backdrop_path'] ?? null,
            'release_date' => $tmdbData['release_date'] ?? null,
            'vote_average' => $tmdbData['vote_average'] ?? 0.0,
            'vote_count' => $tmdbData['vote_count'] ?? 0,
            'genres' => !empty($genreNames) ? implode(', ', $genreNames) : null,
            'runtime' => $tmdbData['runtime'] ?? 0,
        ];
    }
}

if (empty($metadata['title'])) {
    // Fallback: use provided fields
    $metadata['title'] = $input['title'] ?? "Movie #{$tmdbId}";
    $metadata['overview'] = $input['overview'] ?? null;
    $metadata['poster_path'] = $input['poster_path'] ?? null;
}

// Use explicit overrides from the request
foreach (['title', 'overview', 'poster_path', 'backdrop_path', 'release_date', 'genres', 'runtime', 'status', 'featured'] as $field) {
    if (isset($input[$field])) {
        $metadata[$field] = $input[$field];
    }
}

$stmt = $pdo->prepare('
    INSERT INTO movies (tmdb_id, title, overview, poster_path, backdrop_path, release_date, vote_average, vote_count, genres, runtime, status, featured, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
');

$stmt->execute([
    $tmdbId,
    $metadata['title'],
    $metadata['overview'] ?? null,
    $metadata['poster_path'] ?? null,
    $metadata['backdrop_path'] ?? null,
    $metadata['release_date'] ?? null,
    $metadata['vote_average'] ?? 0.0,
    $metadata['vote_count'] ?? 0,
    $metadata['genres'] ?? null,
    $metadata['runtime'] ?? 0,
    $metadata['status'] ?? 'published',
    $metadata['featured'] ?? 0,
    $adminId,
]);

$movieId = (int) $pdo->lastInsertId();

logAdminAction($adminId, 'add_movie', 'movie', $movieId, "Added movie: {$metadata['title']} (TMDB #{$tmdbId})");

jsonResponse([
    'success' => true,
    'movie_id' => $movieId,
    'tmdb_id' => $tmdbId,
    'title' => $metadata['title'],
]);
