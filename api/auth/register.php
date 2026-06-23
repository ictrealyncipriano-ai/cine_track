<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/mail.php';

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
$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$confirmPassword = $input['confirm_password'] ?? '';

if (empty($name) || empty($email) || empty($password)) {
    jsonError('Name, email, and password are required');
}

if (strlen($name) > 255) {
    jsonError('Name must not exceed 255 characters');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

if (strlen($email) > 255) {
    jsonError('Email must not exceed 255 characters');
}

if (strlen($password) < 8) {
    jsonError('Password must be at least 8 characters');
}

if (strlen($password) > 72) {
    jsonError('Password must not exceed 72 characters');
}

if (!preg_match('/[A-Z]/', $password)) {
    jsonError('Password must contain at least one uppercase letter');
}

if (!preg_match('/[a-z]/', $password)) {
    jsonError('Password must contain at least one lowercase letter');
}

if (!preg_match('/[0-9]/', $password)) {
    jsonError('Password must contain at least one digit');
}

if ($password !== $confirmPassword) {
    jsonError('Passwords do not match');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkRateLimit("register:$ip", 5, 5);

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    jsonError('Email already registered', 409);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

$stmt = $pdo->prepare('INSERT INTO users (name, email, password, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())');
$stmt->execute([$name, $email, $hash]);
$userId = (int) $pdo->lastInsertId();

$verificationToken = bin2hex(random_bytes(32));
$verificationCode = (string) random_int(100000, 999999);
$expiration = time() + 600;

$stmt = $pdo->prepare('INSERT INTO cache (`key`, value, expiration) VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE value = VALUES(value), expiration = VALUES(expiration)');
$stmt->execute([
    "verify_email:{$userId}",
    json_encode(['token' => $verificationToken, 'code' => $verificationCode, 'email' => $email]),
    $expiration,
]);

try {
    $mail = getMailer();
    $mail->addAddress($email, $name);
    $mail->Subject = 'Verify your CineTrack email address';
    $mail->isHTML(true);
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;'>
            <h2 style='color: #FFC107;'>CineTrack</h2>
            <p>Hi {$name},</p>
            <p>Thanks for creating an account! Use the code below to verify your email address:</p>
            <p style='text-align: center; margin: 24px 0;'>
                <span style='font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #FFC107; background: #0D1117; padding: 16px 32px; border-radius: 12px; display: inline-block;'>{$verificationCode}</span>
            </p>
            <p style='text-align: center; margin: 24px 0;'>
                <a href='http://localhost/cine_track/api/auth/email_verify.php?token=" . urlencode($verificationToken) . "'
                   style='background-color: #FFC107; color: #000; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;'>
                    Verify Email Address
                </a>
            </p>
            <p style='color: #888; font-size: 13px;'>This code and link expire in 10 minutes. If you didn't create this account, you can safely ignore this email.</p>
        </div>
    ";
    $mail->AltBody = "Your verification code: {$verificationCode}\n\nOr click: http://localhost/cine_track/api/auth/email_verify.php?token=" . urlencode($verificationToken) . "\n\nThis code expires in 10 minutes.";
    $mail->send();
} catch (Exception $e) {
    $stmt = $pdo->prepare('DELETE FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
    $stmt->execute(["verify_email:{$userId}"]);
    jsonError('Failed to send verification email. Please try again.', 500);
}

jsonResponse([
    'message' => 'Account created. Check your email to verify.',
    'user_id' => $userId,
], 201);
