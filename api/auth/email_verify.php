<?php
require_once __DIR__ . '/../config/database.php';

$token = trim($_GET['token'] ?? '');

if (empty($token)) {
    http_response_code(400);
    echo '<html><head><title>Verification Failed</title>';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
    echo '<style>body{font-family:Arial,sans-serif;background:#0D1117;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px}.card{background:#161B22;border-radius:16px;padding:40px;max-width:400px;text-align:center}h2{margin:0 0 12px}p{color:#aaa;margin:0 0 24px;line-height:1.5}.error{color:#ff4444}.btn{display:inline-block;padding:12px 24px;background:#FFC107;color:#000;text-decoration:none;border-radius:8px;font-weight:600}</style>';
    echo '</head><body><div class="card"><h2 class="error">Invalid Link</h2><p>No verification token provided.</p></div></body></html>';
    exit;
}

$pdo = getDb();

$stmt = $pdo->prepare('SELECT `key`, value FROM cache WHERE `key` LIKE ? AND expiration > UNIX_TIMESTAMP()');
$stmt->execute(['verify_email:%']);
$rows = $stmt->fetchAll();

$matchedKey = null;
$matchedUserId = null;
$matchedEmail = null;

foreach ($rows as $row) {
    $data = json_decode($row['value'], true);
    if (isset($data['token']) && hash_equals($data['token'], $token)) {
        $matchedKey = $row['key'];
        $parts = explode(':', $matchedKey);
        $matchedUserId = (int) end($parts);
        $matchedEmail = $data['email'];
        break;
    }
}

if (!$matchedKey) {
    http_response_code(400);
    echo '<html><head><title>Verification Failed</title>';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
    echo '<style>body{font-family:Arial,sans-serif;background:#0D1117;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px}.card{background:#161B22;border-radius:16px;padding:40px;max-width:400px;text-align:center}h2{margin:0 0 12px}p{color:#aaa;margin:0 0 24px;line-height:1.5}.error{color:#ff4444}</style>';
    echo '</head><body><div class="card"><h2 class="error">Invalid or Expired Link</h2><p>This verification link is invalid or has expired. Please request a new verification email.</p></div></body></html>';
    exit;
}

$stmt = $pdo->prepare('UPDATE users SET email_verified_at = NOW(), updated_at = NOW() WHERE id = ? AND email_verified_at IS NULL');
$stmt->execute([$matchedUserId]);

if ($stmt->rowCount() === 0) {
    $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
    $stmt->execute([$matchedKey]);
    echo '<html><head><title>Already Verified</title>';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
    echo '<style>body{font-family:Arial,sans-serif;background:#0D1117;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px}.card{background:#161B22;border-radius:16px;padding:40px;max-width:400px;text-align:center}h2{margin:0 0 12px}p{color:#aaa;margin:0 0 24px;line-height:1.5}.success{color:#4caf50}</style>';
    echo '</head><body><div class="card"><h2 class="success">Already Verified</h2><p>This email address is already verified. You can log in to CineTrack.</p></div></body></html>';
    exit;
}

$stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
$stmt->execute([$matchedKey]);

?>
<html>
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
        .btn { display: inline-block; padding: 12px 24px; background: #FFC107; color: #000; text-decoration: none; border-radius: 8px; font-weight: 600; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">&#x2705;</div>
        <h2 class="success">Email Verified!</h2>
        <p>Your email has been successfully verified. You can now close this page and log in to CineTrack.</p>
        <a href="http://localhost/cine_track" class="btn">Go to CineTrack</a>
    </div>
</body>
</html>
