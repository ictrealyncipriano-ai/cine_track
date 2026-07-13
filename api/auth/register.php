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
$username = trim($input['username'] ?? '');
$email = strtolower(trim($input['email'] ?? ''));
$phone = trim($input['phone'] ?? '');
$dateOfBirth = trim($input['date_of_birth'] ?? '');
$country = trim($input['country'] ?? '');
$marketingOptIn = !empty($input['marketing_opt_in']);
$password = $input['password'] ?? '';
$confirmPassword = $input['confirm_password'] ?? '';

if (empty($name) || empty($username) || empty($email) || empty($password)) {
    jsonError('Name, username, email, and password are required');
}

if (strlen($name) > 255) {
    jsonError('Name must not exceed 255 characters');
}

$username = strtolower($username);
if (strlen($username) < 3 || strlen($username) > 50) {
    jsonError('Username must be between 3 and 50 characters');
}

if (!preg_match('/^[a-z0-9_-]+$/', $username)) {
    jsonError('Username may only contain letters, numbers, underscores, and dashes');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email format');
}

if (strlen($email) > 255) {
    jsonError('Email must not exceed 255 characters');
}

if (!empty($phone) && !preg_match('/^\+?[\d\s\-()]{7,20}$/', $phone)) {
    jsonError('Invalid phone number format');
}

if (!empty($dateOfBirth)) {
    $dob = DateTime::createFromFormat('Y-m-d', $dateOfBirth);
    if (!$dob || $dob->format('Y-m-d') !== $dateOfBirth) {
        jsonError('Invalid date of birth format (use YYYY-MM-DD)');
    }
    $minAge = new DateTime('-13 years');
    if ($dob > $minAge) {
        jsonError('You must be at least 13 years old to register');
    }
}

if (!empty($country) && strlen($country) > 100) {
    jsonError('Country must not exceed 100 characters');
}

$passwordError = validatePassword($password);
if ($passwordError) {
    jsonError($passwordError);
}

if ($password !== $confirmPassword) {
    jsonError('Passwords do not match');
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
checkAndIncrementRateLimit("register:$ip", 5, 5);

$pdo = getDb();

$stmt = $pdo->prepare('SELECT id FROM users WHERE username = ?');
$stmt->execute([$username]);
if ($stmt->fetch()) {
    jsonError('Username already taken', 409);
}

$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    jsonError('Email already registered', 409);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

$stmt = $pdo->prepare('INSERT INTO users (name, username, email, phone, date_of_birth, country, marketing_opt_in, password, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())');
$stmt->execute([$name, $username, $email, $phone ?: null, $dateOfBirth ?: null, $country ?: null, $marketingOptIn ? 1 : 0, $hash]);
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
    $appUrl = getAppUrl();
    $verifyLink = $appUrl . '/auth/email_verify.php?user_id=' . $userId . '&token=' . urlencode($verificationToken);
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;'>
            <h2 style='color: #FFC107;'>CineTrack</h2>
            <p>Hi {$name},</p>
            <p>Thanks for creating an account! Use the code below to verify your email address:</p>
            <p style='text-align: center; margin: 24px 0;'>
                <span style='font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #FFC107; background: #0D1117; padding: 16px 32px; border-radius: 12px; display: inline-block;'>{$verificationCode}</span>
            </p>
            <p style='text-align: center; margin: 24px 0;'>
                <a href='{$verifyLink}'
                   style='background-color: #FFC107; color: #000; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;'>
                    Verify Email Address
                </a>
            </p>
            <p style='color: #888; font-size: 13px;'>This code and link expire in 10 minutes. If you didn't create this account, you can safely ignore this email.</p>
        </div>
    ";
    $mail->AltBody = "Your verification code: {$verificationCode}\n\nOr click: {$verifyLink}\n\nThis code expires in 10 minutes.";
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
