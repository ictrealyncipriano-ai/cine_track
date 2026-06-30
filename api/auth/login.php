<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$rememberMe = isset($input['remember_me']) ? (bool) $input['remember_me'] : true;

if (empty($email) || empty($password)) {
    jsonError('Email and password are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkRateLimit("login:$ip", 5, 5);

checkAccountLockout($email, 5, 5);

$pdo = getDb();
$stmt = $pdo->prepare('SELECT id, name, email, password, email_verified_at, role FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    incrementAccountLockout($email, 5, 5);
    incrementRateLimit("login:$ip", 5);
    jsonError('Invalid email or password', 401);
}

clearAccountLockout($email);
clearRateLimit("login:$ip");

if ($user['email_verified_at'] === null) {
    jsonResponse([
        'error' => 'Please verify your email before logging in.',
        'code' => 'EMAIL_NOT_VERIFIED',
    ], 403);
}

$token = bin2hex(random_bytes(32));

$expiry = $rememberMe ? 'DATE_ADD(NOW(), INTERVAL 30 DAY)' : 'DATE_ADD(NOW(), INTERVAL 1 DAY)';
$stmt = $pdo->prepare("INSERT INTO api_tokens (user_id, token, expires_at) VALUES (?, ?, $expiry)");
$stmt->execute([$user['id'], $token]);

jsonResponse([
    'token' => $token,
    'user' => [
        'id' => (int) $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'email_verified' => true,
        'role' => $user['role'],
    ],
]);
