<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$reviewId = (int) ($_GET['review_id'] ?? 0);
if ($reviewId <= 0) jsonError('review_id is required');

$pdo = getDb();

$stmt = $pdo->prepare('
    SELECT r.id, r.review_id, r.body, r.created_at,
           u.id AS user_id, u.name AS user_name, u.avatar_url AS user_avatar
    FROM review_replies r
    LEFT JOIN users u ON r.user_id = u.id
    WHERE r.review_id = ?
    ORDER BY r.created_at ASC
');
$stmt->execute([$reviewId]);
$replies = $stmt->fetchAll();

jsonResponse(['replies' => $replies]);
