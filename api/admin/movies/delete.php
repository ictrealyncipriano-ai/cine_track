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

// Soft-delete by setting status to 'archived'
$stmt = $pdo->prepare("UPDATE movies SET status = 'archived' WHERE id = ?");
$stmt->execute([$movieId]);

logAdminAction($adminId, 'delete_movie', 'movie', $movieId, "Deleted movie: {$movie['title']} (ID #{$movieId})");

jsonResponse([
    'success' => true,
    'movie_id' => $movieId,
]);
