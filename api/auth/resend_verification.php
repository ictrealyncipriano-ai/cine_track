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
$email = strtolower(trim($input['email'] ?? ''));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('A valid email is required');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkRateLimit("resend_verify:$ip", 3, 5);

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id, name, email_verified_at FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(['message' => 'If that email is registered, a new verification link has been sent.']);
}

if ($user['email_verified_at'] !== null) {
    jsonResponse(['message' => 'This email is already verified. You can log in.']);
}

$verificationToken = bin2hex(random_bytes(32));
$verificationCode = (string) random_int(100000, 999999);
$expiration = time() + 600;

$stmt = $pdo->prepare('INSERT INTO cache (`key`, value, expiration) VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE value = VALUES(value), expiration = VALUES(expiration)');
$stmt->execute([
    "verify_email:{$user['id']}",
    json_encode(['token' => $verificationToken, 'code' => $verificationCode, 'email' => $email]),
    $expiration,
]);

try {
    $mail = getMailer();
    $mail->addAddress($email, $user['name']);
    $mail->Subject = 'Verify your CineTrack email address';
    $mail->isHTML(true);
    $appUrl = getAppUrl();
    $verifyLink = $appUrl . '/auth/email_verify.php?user_id=' . $user['id'] . '&token=' . urlencode($verificationToken);
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;'>
            <h2 style='color: #FFC107;'>CineTrack</h2>
            <p>Hi {$user['name']},</p>
            <p>Here is your new verification code:</p>
            <p style='text-align: center; margin: 24px 0;'>
                <span style='font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #FFC107; background: #0D1117; padding: 16px 32px; border-radius: 12px; display: inline-block;'>{$verificationCode}</span>
            </p>
            <p style='text-align: center; margin: 24px 0;'>
                <a href='{$verifyLink}'
                   style='background-color: #FFC107; color: #000; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;'>
                    Verify Email Address
                </a>
            </p>
            <p style='color: #888; font-size: 13px;'>This code and link expire in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
        </div>
    ";
    $mail->AltBody = "Your verification code: {$verificationCode}\n\nOr click: {$verifyLink}\n\nThis code expires in 10 minutes.";
    $mail->send();
} catch (Exception $e) {
    jsonError('Failed to send email. Please try again later.', 500);
}

jsonResponse(['message' => 'If that email is registered, a new verification link has been sent.']);
