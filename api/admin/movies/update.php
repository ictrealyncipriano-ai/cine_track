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

$movieId = isset($input['id']) ? (int) $input['id'] : 0;
if ($movieId <= 0) {
    jsonError('id is required', 400);
}

$pdo = getDb();

// Check movie exists
$stmt = $pdo->prepare('SELECT id, title FROM movies WHERE id = ?');
$stmt->execute([$movieId]);
$movie = $stmt->fetch();
if (!$movie) {
    jsonError('Movie not found', 404);
}

$allowedFields = ['title', 'overview', 'poster_path', 'backdrop_path', 'release_date', 'genres', 'runtime', 'status', 'featured'];
$updates = [];
$params = [];

foreach ($allowedFields as $field) {
    if (isset($input[$field])) {
        $updates[] = "{$field} = ?";
        $params[] = $input[$field];
    }
}

if (empty($updates)) {
    jsonError('No valid fields to update', 400);
}

$params[] = $movieId;
$sql = 'UPDATE movies SET ' . implode(', ', $updates) . ' WHERE id = ?';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

logAdminAction($adminId, 'update_movie', 'movie', $movieId, "Updated movie: {$movie['title']} (ID #{$movieId})");

jsonResponse([
    'success' => true,
    'movie_id' => $movieId,
]);
