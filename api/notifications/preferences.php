<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$userId = getAuthUserId();

$pdo = getDb();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->prepare('SELECT * FROM notification_preferences WHERE user_id = ?');
    $stmt->execute([$userId]);
    $prefs = $stmt->fetch();

    if (!$prefs) {
        $prefs = [
            'follow_enabled' => 1,
            'review_like_enabled' => 1,
            'reply_enabled' => 1,
            'moderation_enabled' => 1,
            'list_add_enabled' => 1,
        ];
    }

    jsonResponse([
        'follow' => (bool) $prefs['follow_enabled'],
        'review_like' => (bool) $prefs['review_like_enabled'],
        'reply' => (bool) $prefs['reply_enabled'],
        'moderation' => (bool) $prefs['moderation_enabled'],
        'list_add' => (bool) $prefs['list_add_enabled'],
    ]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $stmt = $pdo->prepare('
        INSERT INTO notification_preferences (user_id, follow_enabled, review_like_enabled, reply_enabled, moderation_enabled, list_add_enabled)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            follow_enabled = VALUES(follow_enabled),
            review_like_enabled = VALUES(review_like_enabled),
            reply_enabled = VALUES(reply_enabled),
            moderation_enabled = VALUES(moderation_enabled),
            list_add_enabled = VALUES(list_add_enabled),
            updated_at = NOW()
    ');
    $stmt->execute([
        $userId,
        isset($input['follow']) ? ($input['follow'] ? 1 : 0) : 1,
        isset($input['review_like']) ? ($input['review_like'] ? 1 : 0) : 1,
        isset($input['reply']) ? ($input['reply'] ? 1 : 0) : 1,
        isset($input['moderation']) ? ($input['moderation'] ? 1 : 0) : 1,
        isset($input['list_add']) ? ($input['list_add'] ? 1 : 0) : 1,
    ]);

    jsonResponse(['success' => true]);
}

jsonError('Method not allowed', 405);
