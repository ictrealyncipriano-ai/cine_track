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

if (empty($input['review_id']) || empty($input['action'])) {
    jsonError('review_id and action are required');
}

$reviewId = (int) $input['review_id'];
$action = $input['action'];
$note = $input['moderation_note'] ?? null;

$allowedActions = ['approve', 'reject', 'dismiss_report'];
if (!in_array($action, $allowedActions)) {
    jsonError('Invalid action. Allowed: approve, reject, dismiss_report');
}

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, status FROM reviews WHERE id = ?');
$stmt->execute([$reviewId]);
$review = $stmt->fetch();

if (!$review) {
    jsonError('Review not found', 404);
}

$newStatus = match ($action) {
    'approve' => 'approved',
    'reject' => 'rejected',
    'dismiss_report' => 'approved', // dismiss report = un-report it
};

$stmt = $pdo->prepare('
    UPDATE reviews
    SET status = ?, moderated_by = ?, moderated_at = NOW(), moderation_note = COALESCE(?, moderation_note)
    WHERE id = ?
');
$stmt->execute([$newStatus, $adminId, $note, $reviewId]);

logAdminAction($adminId, $action, 'review', $reviewId, $note ? "Note: {$note}" : null);

jsonResponse(['success' => true, 'status' => $newStatus]);
