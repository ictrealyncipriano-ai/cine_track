<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$headers = getallheaders();
$auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
$token = str_replace('Bearer ', '', $auth);

if (empty($token)) {
    jsonResponse(['valid' => false], 401);
}

$pdo = getDb();
$stmt = $pdo->prepare('
    SELECT u.id, u.name, u.email, u.email_verified_at, u.role
    FROM api_tokens t 
    JOIN users u ON u.id = t.user_id 
    WHERE t.token = ? AND (t.expires_at IS NULL OR t.expires_at > NOW())
');
$stmt->execute([$token]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(['valid' => false], 401);
}

jsonResponse([
    'valid' => true,
    'user' => [
        'id' => (int) $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'email_verified' => $user['email_verified_at'] !== null,
        'role' => $user['role'],
    ],
]);
