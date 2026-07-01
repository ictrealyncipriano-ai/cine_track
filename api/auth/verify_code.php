<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$email = strtolower(trim($input['email'] ?? ''));
$code = trim($input['code'] ?? '');

if (empty($email) || empty($code)) {
    jsonError('Email and verification code are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

if (!preg_match('/^\d{6}$/', $code)) {
    jsonError('Invalid verification code format');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkRateLimit("verify_code:$ip", 5, 5);

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, email_verified_at FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Invalid request', 400);
}

if ($user['email_verified_at'] !== null) {
    jsonResponse(['message' => 'Email is already verified. You can log in.']);
}

$stmt = $pdo->prepare('SELECT value, expiration FROM cache WHERE `key` = ?');
$stmt->execute(["verify_email:{$user['id']}"]);
$row = $stmt->fetch();

if (!$row) {
    jsonError('No verification code found. Please request a new one.', 400);
}

$expiration = (int) $row['expiration'];
if (time() >= $expiration) {
    $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
    $stmt->execute(["verify_email:{$user['id']}"]);
    jsonError('Verification code has expired. Please request a new one.', 400);
}

$data = json_decode($row['value'], true);

if (!isset($data['code']) || !hash_equals($data['code'], $code)) {
    jsonError('Invalid verification code', 400);
}

$stmt = $pdo->prepare('UPDATE users SET email_verified_at = NOW(), updated_at = NOW() WHERE id = ?');
$stmt->execute([$user['id']]);

$stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
$stmt->execute(["verify_email:{$user['id']}"]);

jsonResponse(['message' => 'Email verified successfully. You can now log in.']);
