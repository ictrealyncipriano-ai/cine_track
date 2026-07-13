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

if (empty($input['review_ids']) || !is_array($input['review_ids'])) {
    jsonError('review_ids array is required');
}

if (empty($input['action'])) {
    jsonError('action is required');
}

$reviewIds = array_map('intval', $input['review_ids']);
$action = $input['action'];
$note = $input['moderation_note'] ?? null;

$allowedActions = ['approve', 'reject'];
if (!in_array($action, $allowedActions)) {
    jsonError('Invalid action. Allowed: approve, reject');
}

if (count($reviewIds) > 100) {
    jsonError('Maximum 100 reviews per bulk operation');
}

$newStatus = $action === 'approve' ? 'approved' : 'rejected';

$pdo = getDb();
$placeholders = implode(',', array_fill(0, count($reviewIds), '?'));

$stmt = $pdo->prepare("UPDATE reviews SET status = ?, moderated_by = ?, moderated_at = NOW(), moderation_note = COALESCE(?, moderation_note) WHERE id IN ($placeholders)");
$stmt->execute(array_merge([$newStatus, $adminId, $note], $reviewIds));

$affected = $stmt->rowCount();

logAdminAction($adminId, "bulk_$action", 'review', null, "Moderated $affected reviews");

jsonResponse(['success' => true, 'affected' => $affected]);
