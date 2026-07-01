<?php
require_once __DIR__ . '/../config/database.php';

$token = trim($_GET['token'] ?? '');
$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;

$errorTitle = 'Verification Failed';
$errorMessage = '';
$success = false;
$alreadyVerified = false;

if (empty($token) || $userId <= 0) {
    $errorMessage = 'Invalid verification link.';
} else {
    $pdo = getDb();

    $stmt = $pdo->prepare('SELECT value, expiration FROM cache WHERE `key` = ? AND expiration > UNIX_TIMESTAMP()');
    $stmt->execute(["verify_email:{$userId}"]);
    $row = $stmt->fetch();

    if ($row) {
        $data = json_decode($row['value'], true);

        if (isset($data['token']) && hash_equals($data['token'], $token)) {
            $stmt = $pdo->prepare('UPDATE users SET email_verified_at = NOW(), updated_at = NOW() WHERE id = ? AND email_verified_at IS NULL');
            $stmt->execute([$userId]);

            if ($stmt->rowCount() > 0) {
                $success = true;
            } else {
                $alreadyVerified = true;
            }

            $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
            $stmt->execute(["verify_email:{$userId}"]);
        } else {
            $errorMessage = 'Invalid verification link.';
        }
    } else {
        $stmt = $pdo->prepare('SELECT email_verified_at FROM users WHERE id = ?');
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if ($user && $user['email_verified_at'] !== null) {
            $alreadyVerified = true;
        } else {
            $errorMessage = 'This verification link has expired. Please request a new one.';
        }
    }
}

$appUrl = getAppUrl();

?><html>
<head>
    <title>Email Verified</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; background: #0D1117; color: #fff; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; }
        .card { background: #161B22; border-radius: 16px; padding: 40px; max-width: 400px; text-align: center; }
        .icon { font-size: 64px; margin-bottom: 16px; }
        h2 { margin: 0 0 12px; }
        p { color: #aaa; margin: 0 0 24px; line-height: 1.5; }
        .success { color: #4caf50; }
        .error { color: #ff4444; }
        .btn { display: inline-block; padding: 12px 24px; background: #FFC107; color: #000; text-decoration: none; border-radius: 8px; font-weight: 600; }
    </style>
</head>
<body>
    <div class="card">
        <?php if ($success): ?>
            <div class="icon">&#x2705;</div>
            <h2 class="success">Email Verified!</h2>
            <p>Your email has been successfully verified. You can now close this page and log in to CineTrack.</p>
            <a href="<?= htmlspecialchars($appUrl) ?>" class="btn">Go to CineTrack</a>
        <?php elseif ($alreadyVerified): ?>
            <div class="icon">&#x2705;</div>
            <h2 class="success">Already Verified</h2>
            <p>This email address is already verified. You can log in to CineTrack.</p>
            <a href="<?= htmlspecialchars($appUrl) ?>" class="btn">Go to CineTrack</a>
        <?php else: ?>
            <h2 class="error"><?= htmlspecialchars($errorTitle) ?></h2>
            <p><?= htmlspecialchars($errorMessage) ?></p>
        <?php endif; ?>
    </div>
</body>
</html>
