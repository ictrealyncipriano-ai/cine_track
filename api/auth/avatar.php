<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

$userId = getAuthUserId();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $image = $input['image'] ?? '';
    $mime = $input['mime'] ?? 'image/jpeg';

    if (empty($image)) {
        jsonError('Image data is required');
    }

    $allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!in_array($mime, $allowedMimes)) {
        jsonError('Invalid image type. Allowed: jpeg, png, webp, gif');
    }

    $decoded = base64_decode($image);
    if ($decoded === false) {
        jsonError('Invalid image data');
    }

    $maxSize = 2 * 1024 * 1024;
    if (strlen($decoded) > $maxSize) {
        jsonError('Image must be smaller than 2MB');
    }

    $dataUri = 'data:' . $mime . ';base64,' . $image;

    $pdo = getDb();
    $stmt = $pdo->prepare('UPDATE users SET avatar_url = ?, updated_at = NOW() WHERE id = ?');
    $stmt->execute([$dataUri, $userId]);

    jsonResponse([
        'message' => 'Avatar updated successfully',
        'avatar_url' => $dataUri,
    ]);
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $pdo = getDb();
    $stmt = $pdo->prepare('SELECT id, name, username, email, phone, date_of_birth, country, marketing_opt_in, email_verified_at, role, avatar_url FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        jsonError('User not found', 404);
    }

    if ($user['avatar_url'] !== null && str_starts_with($user['avatar_url'], 'data:')) {
        header('Content-Type: text/plain');
        echo $user['avatar_url'];
        exit;
    }

    jsonResponse(['avatar_url' => $user['avatar_url']]);
}

jsonError('Method not allowed', 405);
