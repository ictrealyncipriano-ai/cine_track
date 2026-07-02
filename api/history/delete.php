<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['movie_id'])) {
    jsonError('movie_id is required');
}

try {
    $pdo = getDb();
    $stmt = $pdo->prepare('DELETE FROM watch_history WHERE user_id = ? AND movie_id = ?');
    $stmt->execute([$userId, (int) $input['movie_id']]);

    if ($stmt->rowCount() === 0) {
        jsonError('History entry not found', 404);
    }

    jsonResponse(['success' => true]);
} catch (\PDOException $e) {
    jsonError('Failed to delete history entry', 500);
}
