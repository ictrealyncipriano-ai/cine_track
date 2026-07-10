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
$email = strtolower(trim($input['email'] ?? ''));
$password = $input['password'] ?? '';
$rememberMe = isset($input['remember_me']) ? (bool) $input['remember_me'] : true;

if (empty($email) || empty($password)) {
    jsonError('Email and password are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
checkRateLimit("login:$ip", 5, 5);

checkAccountLockout($email, 3, 5);

$pdo = getDb();
$stmt = $pdo->prepare('SELECT id, name, username, email, phone, date_of_birth, country, marketing_opt_in, password, email_verified_at, role, avatar_url FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    logLoginAttempt($email, null, false, $ip, $userAgent);
    incrementAccountLockout($email, 3, 5);
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

logLoginAttempt($email, (int) $user['id'], true, $ip, $userAgent);

$token = bin2hex(random_bytes(32));
$deviceInfo = isset($input['device_info']) ? json_encode($input['device_info']) : null;

$expiry = $rememberMe ? 'DATE_ADD(NOW(), INTERVAL 7 DAY)' : 'DATE_ADD(NOW(), INTERVAL 1 DAY)';
$rememberMeInt = $rememberMe ? 1 : 0;
$stmt = $pdo->prepare("INSERT INTO api_tokens (user_id, token, expires_at, ip_address, user_agent, device_info, remember_me) VALUES (?, ?, $expiry, ?, ?, ?, ?)");
$stmt->execute([$user['id'], $token, $ip, $userAgent, $deviceInfo, $rememberMeInt]);

jsonResponse([
    'token' => $token,
    'user' => [
        'id' => (int) $user['id'],
        'name' => $user['name'],
        'username' => $user['username'],
        'email' => $user['email'],
        'phone' => $user['phone'],
        'date_of_birth' => $user['date_of_birth'],
        'country' => $user['country'],
        'marketing_opt_in' => (bool) $user['marketing_opt_in'],
        'email_verified' => true,
        'role' => $user['role'],
        'avatar_url' => $user['avatar_url'],
    ],
]);
