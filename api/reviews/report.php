<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

// Banned users cannot report
if (isBanned($userId)) {
    jsonError('Your account has been suspended', 403);
}

checkAndIncrementRateLimit("review_report:$userId", 10, 5);

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['review_id'])) {
    jsonError('review_id is required');
}

if (empty($input['reason'])) {
    jsonError('reason is required');
}

$reviewId = (int) $input['review_id'];
$reason = trim($input['reason']);

if (strlen($reason) > 500) {
    jsonError('Reason must not exceed 500 characters');
}

$pdo = getDb();

// Verify review exists
$stmt = $pdo->prepare('SELECT id, user_id FROM reviews WHERE id = ?');
$stmt->execute([$reviewId]);
$review = $stmt->fetch();

if (!$review) {
    jsonError('Review not found', 404);
}

// Prevent reporting your own review
if ((int) $review['user_id'] === $userId) {
    jsonError('Cannot report your own review', 403);
}

$pdo->beginTransaction();
try {
    // Check if already reported by this user (inside transaction to prevent race)
    $stmt = $pdo->prepare('SELECT id FROM review_reports WHERE review_id = ? AND reported_by = ? FOR UPDATE');
    $stmt->execute([$reviewId, $userId]);
    if ($stmt->fetch()) {
        $pdo->rollBack();
        jsonError('You have already reported this review', 409);
    }

    $stmt = $pdo->prepare('INSERT INTO review_reports (review_id, reported_by, reason) VALUES (?, ?, ?)');
    $stmt->execute([$reviewId, $userId, $reason]);

    $stmt = $pdo->prepare("UPDATE reviews SET status = 'reported', updated_at = NOW() WHERE id = ? AND status = 'approved'");
    $stmt->execute([$reviewId]);

    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    jsonError('Failed to submit report', 500);
}

jsonResponse(['success' => true, 'message' => 'Review reported']);
