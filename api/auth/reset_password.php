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
$email = trim($input['email'] ?? '');
$token = trim($input['token'] ?? '');
$password = $input['password'] ?? '';
$confirmPassword = $input['confirm_password'] ?? '';

if (empty($email) || empty($token) || empty($password)) {
    jsonError('Email, token, and password are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

if (strlen($password) < 8) {
    jsonError('Password must be at least 8 characters');
}

if (!preg_match('/[A-Z]/', $password)) {
    jsonError('Password must contain at least one uppercase letter');
}

if (!preg_match('/[a-z]/', $password)) {
    jsonError('Password must contain at least one lowercase letter');
}

if (strlen($password) > 72) {
    jsonError('Password must not exceed 72 characters');
}

if (!preg_match('/[0-9]/', $password)) {
    jsonError('Password must contain at least one digit');
}

if ($password !== $confirmPassword) {
    jsonError('Passwords do not match');
}

$pdo = getDb();

$stmt = $pdo->prepare('SELECT email, created_at FROM password_reset_tokens WHERE email = ? AND token = ?');
$stmt->execute([$email, $token]);
$row = $stmt->fetch();

if (!$row) {
    jsonError('Invalid or expired reset token', 400);
}

$createdAt = strtotime($row['created_at']);
if (time() - $createdAt > 3600) {
    $stmt = $pdo->prepare('DELETE FROM password_reset_tokens WHERE email = ?');
    $stmt->execute([$email]);
    jsonError('Reset token has expired. Please request a new one.', 400);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare('UPDATE users SET password = ?, updated_at = NOW() WHERE email = ?');
    $stmt->execute([$hash, $email]);

    $stmt = $pdo->prepare('DELETE FROM password_reset_tokens WHERE email = ?');
    $stmt->execute([$email]);

    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = (SELECT id FROM users WHERE email = ?)');
    $stmt->execute([$email]);

    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    jsonError('Something went wrong. Please try again.', 500);
}

jsonResponse(['message' => 'Password has been reset successfully. You can now log in with your new password.']);
