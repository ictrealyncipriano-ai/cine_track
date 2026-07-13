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
requireRole($adminId, 'admin', 'moderator');

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['review_id'])) {
    jsonError('review_id is required');
}

$reviewId = (int) $input['review_id'];

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id FROM reviews WHERE id = ?');
$stmt->execute([$reviewId]);
if (!$stmt->fetch()) {
    jsonError('Review not found', 404);
}

    $stmt = $pdo->prepare('DELETE FROM review_reports WHERE review_id = ?');
    $stmt->execute([$reviewId]);

    $stmt = $pdo->prepare('DELETE FROM review_replies WHERE review_id = ?');
    $stmt->execute([$reviewId]);

    $stmt = $pdo->prepare('DELETE FROM reviews WHERE id = ?');
    $stmt->execute([$reviewId]);

logAdminAction($adminId, 'delete', 'review', $reviewId, 'Review permanently deleted');

jsonResponse(['success' => true]);
