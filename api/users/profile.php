<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$profileId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
if ($profileId <= 0) {
    jsonError('user_id is required');
}

$pdo = getDb();

$user = getUserById($profileId);
if (!$user || $user['deleted_at'] !== null) {
    jsonError('User not found', 404);
}

$countsStmt = $pdo->prepare('
    SELECT
        (SELECT COUNT(*) FROM follows WHERE following_id = ?) AS followers,
        (SELECT COUNT(*) FROM follows WHERE follower_id = ?) AS following,
        (SELECT COUNT(*) FROM watch_history WHERE user_id = ?) AS movies_watched,
        (SELECT COUNT(*) FROM reviews WHERE user_id = ?) AS reviews,
        (SELECT COUNT(*) FROM user_lists WHERE user_id = ?) AS lists
');
$countsStmt->execute([$profileId, $profileId, $profileId, $profileId, $profileId]);
$counts = $countsStmt->fetch();

$isFollowing = false;
$isBlocked = false;

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ')) {
    try {
        $currentUserId = getAuthUserId();
        $followStmt = $pdo->prepare('SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ?');
        $followStmt->execute([$currentUserId, $profileId]);
        $isFollowing = (bool) $followStmt->fetch();

        $blockStmt = $pdo->prepare('SELECT 1 FROM user_blocks WHERE blocker_id = ? AND blocked_id = ?');
        $blockStmt->execute([$currentUserId, $profileId]);
        $isBlocked = (bool) $blockStmt->fetch();
    } catch (\Throwable $e) {
        // Not authenticated — isFollowing/isBlocked stays false
    }
}

jsonResponse([
    'user' => [
        'id' => (int) $user['id'],
        'name' => $user['name'],
        'username' => $user['username'],
        'avatar_url' => $user['avatar_url'],
        'bio' => $user['bio'],
        'created_at' => $user['created_at'],
    ],
    'counts' => [
        'followers' => (int) ($counts['followers'] ?? 0),
        'following' => (int) ($counts['following'] ?? 0),
        'movies_watched' => (int) ($counts['movies_watched'] ?? 0),
        'reviews' => (int) ($counts['reviews'] ?? 0),
        'lists' => (int) ($counts['lists'] ?? 0),
    ],
    'is_following' => $isFollowing,
    'is_blocked' => $isBlocked,
]);
