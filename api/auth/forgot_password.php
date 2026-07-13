<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/mail.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$email = trim($input['email'] ?? '');

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('A valid email is required');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkAndIncrementRateLimit("forgot:$ip", 3, 5);

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, name FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(['message' => 'If that email is registered, you will receive a password reset link shortly.']);
}

$token = bin2hex(random_bytes(32));

$stmt = $pdo->prepare('DELETE FROM password_reset_tokens WHERE email = ?');
$stmt->execute([$email]);

$stmt = $pdo->prepare('INSERT INTO password_reset_tokens (email, token, created_at) VALUES (?, ?, NOW())');
$stmt->execute([$email, $token]);

try {
    $mail = getMailer();
    $mail->addAddress($email, $user['name']);
    $mail->Subject = 'Your CineTrack Password Reset Link';
    $mail->isHTML(true);
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;'>
            <h2 style='color: #FFC107;'>CineTrack</h2>
            <p>Hi {$user['name']},</p>
            <p>We received a request to reset your password. Click the button below to set a new one:</p>
            <p style='text-align: center; margin: 32px 0;'>
                <a href='" . getAppUrl() . "/#/reset-password?email=" . urlencode($email) . "&token=" . urlencode($token) . "'
                   style='background-color: #FFC107; color: #000; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;'>
                    Reset Password
                </a>
            </p>
            <p style='color: #888; font-size: 13px;'>This link expires in 60 minutes. If you didn't request this, you can safely ignore this email.</p>
        </div>
    ";
    $mail->AltBody = "Reset your password: " . getAppUrl() . "/#/reset-password?email=" . urlencode($email) . "&token=" . urlencode($token) . "\n\nThis link expires in 60 minutes.";
    $mail->send();
} catch (Exception $e) {
    jsonError('Failed to send email. Please try again later.', 500);
}

jsonResponse(['message' => 'If that email is registered, you will receive a password reset link shortly.']);
