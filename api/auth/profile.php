<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/mail.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

if ($action === 'update_profile') {
    $name = trim($input['name'] ?? '');
    $email = strtolower(trim($input['email'] ?? ''));

    if (empty($name) || empty($email)) {
        jsonError('Name and email are required');
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

    $pdo = getDb();

    $stmt = $pdo->prepare('SELECT email, email_verified_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $current = $stmt->fetch();

    if (!$current) {
        jsonError('User not found', 404);
    }

    $emailChanged = strtolower($email) !== strtolower($current['email']);

    if ($emailChanged) {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? AND id != ?');
        $stmt->execute([$email, $userId]);
        if ($stmt->fetch()) {
            jsonError('Email already in use', 409);
        }
    }

    $stmt = $pdo->prepare('UPDATE users SET name = ?, email = ?, updated_at = NOW()' . ($emailChanged ? ', email_verified_at = NULL' : '') . ' WHERE id = ?');
    $stmt->execute([$name, $email, $userId]);

    if ($emailChanged) {
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
            $mail->Subject = 'Verify your new email address';
            $mail->isHTML(true);
            $appUrl = getAppUrl();
            $verifyLink = $appUrl . '/auth/email_verify.php?user_id=' . $userId . '&token=' . urlencode($verificationToken);
            $mail->Body = "
                <div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;'>
                    <h2 style='color: #FFC107;'>CineTrack</h2>
                    <p>Hi {$name},</p>
                    <p>Your email was changed. Please verify your new email address:</p>
                    <p style='text-align: center; margin: 24px 0;'>
                        <span style='font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #FFC107; background: #0D1117; padding: 16px 32px; border-radius: 12px; display: inline-block;'>{$verificationCode}</span>
                    </p>
                    <p style='text-align: center; margin: 24px 0;'>
                        <a href='{$verifyLink}'
                           style='background-color: #FFC107; color: #000; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;'>
                            Verify Email Address
                        </a>
                    </p>
                    <p style='color: #888; font-size: 13px;'>This code and link expire in 10 minutes.</p>
                </div>
            ";
            $mail->AltBody = "Your verification code: {$verificationCode}\n\nOr click: {$verifyLink}\n\nThis code expires in 10 minutes.";
            $mail->send();
        } catch (Exception $e) {
        }
    }

    $stmt = $pdo->prepare('SELECT id, name, username, email, phone, date_of_birth, country, marketing_opt_in, email_verified_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    jsonResponse([
        'user' => [
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'username' => $user['username'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'date_of_birth' => $user['date_of_birth'],
            'country' => $user['country'],
            'marketing_opt_in' => (bool) $user['marketing_opt_in'],
            'email_verified' => $user['email_verified_at'] !== null,
        ],
    ]);
}

if ($action === 'change_password') {
    $currentPassword = $input['current_password'] ?? '';
    $newPassword = $input['new_password'] ?? '';
    $confirmPassword = $input['confirm_password'] ?? '';

    if (empty($currentPassword) || empty($newPassword)) {
        jsonError('Current password and new password are required');
    }

    $passwordError = validatePassword($newPassword);
    if ($passwordError) {
        jsonError($passwordError);
    }

    if ($newPassword !== $confirmPassword) {
        jsonError('Passwords do not match');
    }

    $pdo = getDb();

    $stmt = $pdo->prepare('SELECT password FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($currentPassword, $user['password'])) {
        jsonError('Current password is incorrect', 401);
    }

    $hash = password_hash($newPassword, PASSWORD_BCRYPT);

    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    $currentToken = str_replace('Bearer ', '', $auth);

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?');
        $stmt->execute([$hash, $userId]);

        $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = ? AND token != ?');
        $stmt->execute([$userId, $currentToken]);

        $pdo->commit();
    } catch (Exception $e) {
        $pdo->rollBack();
        jsonError('Something went wrong. Please try again.', 500);
    }

    jsonResponse(['message' => 'Password changed successfully. Other sessions have been logged out.']);
}

jsonError('Invalid action', 400);
