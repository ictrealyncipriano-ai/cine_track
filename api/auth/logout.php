<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

$headers = getallheaders();
$auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
$token = str_replace('Bearer ', '', $auth);

$pdo = getDb();
$stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = ? AND token = ?');
$stmt->execute([$userId, $token]);

jsonResponse(['message' => 'Logged out successfully']);
