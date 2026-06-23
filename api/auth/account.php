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

$input = json_decode(file_get_contents('php://input'), true);
$password = $input['password'] ?? '';

if (empty($password)) {
    jsonError('Password is required to delete your account');
}

$pdo = getDb();

$stmt = $pdo->prepare('SELECT password FROM users WHERE id = ?');
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    jsonError('Password is incorrect', 401);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare('DELETE FROM favorites WHERE user_id = ?');
    $stmt->execute([$userId]);

    $stmt = $pdo->prepare('DELETE FROM watchlist WHERE user_id = ?');
    $stmt->execute([$userId]);

    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = ?');
    $stmt->execute([$userId]);

    $stmt = $pdo->prepare('DELETE FROM users WHERE id = ?');
    $stmt->execute([$userId]);

    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    jsonError('Something went wrong. Please try again.', 500);
}

jsonResponse(['message' => 'Account deleted successfully.']);
