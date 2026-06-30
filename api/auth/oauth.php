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
$provider = $input['provider'] ?? '';
$idToken = $input['id_token'] ?? '';
$deviceInfo = isset($input['device_info']) ? json_encode($input['device_info']) : null;
$ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';

if (empty($provider) || empty($idToken)) {
    jsonError('Provider and id_token are required');
}

if (!in_array($provider, ['google', 'apple'])) {
    jsonError('Unsupported provider');
}

function base64urlDecode(string $data): string {
    $remainder = strlen($data) % 4;
    if ($remainder) {
        $data .= str_repeat('=', 4 - $remainder);
    }
    return base64_decode(strtr($data, '-_', '+/')) ?: '';
}

function httpGet(string $url): ?array {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($httpCode !== 200 || $response === false) return null;
    return json_decode($response, true);
}

function derLength(int $length): string {
    if ($length < 128) {
        return chr($length);
    }
    $bytes = '';
    while ($length > 0) {
        $bytes = chr($length & 0xff) . $bytes;
        $length >>= 8;
    }
    return chr(0x80 | strlen($bytes)) . $bytes;
}

function derSequence(string $content): string {
    return "\x30" . derLength(strlen($content)) . $content;
}

function derInteger(string $bytes): string {
    if (ord($bytes[0]) & 0x80) {
        $bytes = "\x00" . $bytes;
    }
    return "\x02" . derLength(strlen($bytes)) . $bytes;
}

function derBitString(string $bytes): string {
    return "\x03" . derLength(strlen($bytes) + 1) . "\x00" . $bytes;
}

function jwkToPem(array $jwk): string {
    $n = base64_decode(strtr($jwk['n'], '-_', '+/')) ?: '';
    $e = base64_decode(strtr($jwk['e'], '-_', '+/')) ?: '';

    $modulus = derInteger($n);
    $exponent = derInteger($e);
    $rsaPublicKey = derSequence($modulus . $exponent);

    $bitString = derBitString($rsaPublicKey);

    $oid = "\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01";
    $null = "\x05\x00";
    $algoId = derSequence($oid . $null);

    $spki = derSequence($algoId . $bitString);

    return "-----BEGIN PUBLIC KEY-----\n" .
           chunk_split(base64_encode($spki), 64, "\n") .
           "-----END PUBLIC KEY-----";
}

function verifyAppleToken(string $idToken): ?array {
    $jwks = httpGet('https://appleid.apple.com/auth/keys');
    if (!$jwks) return null;

    $parts = explode('.', $idToken);
    if (count($parts) !== 3) return null;

    $header = json_decode(base64urlDecode($parts[0]), true);
    if (!$header || !isset($header['kid'])) return null;

    $jwk = null;
    foreach ($jwks as $key) {
        if (isset($key['kid']) && $key['kid'] === $header['kid']) {
            $jwk = $key;
            break;
        }
    }
    if (!$jwk) return null;

    $pem = jwkToPem($jwk);
    $pubKey = openssl_pkey_get_public($pem);
    if (!$pubKey) return null;

    $data = $parts[0] . '.' . $parts[1];
    $signature = base64urlDecode($parts[2]);
    if ($signature === '') return null;

    $valid = openssl_verify($data, $signature, $pubKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($pubKey);

    if ($valid !== 1) return null;

    return json_decode(base64urlDecode($parts[1]), true);
}

$pdo = getDb();

if ($provider === 'google') {
    $payload = httpGet("https://oauth2.googleapis.com/tokeninfo?id_token=" . urlencode($idToken));
    if (!$payload || !isset($payload['sub'], $payload['email'])) {
        jsonError('Invalid Google ID token', 401);
    }
    if (!isset($payload['email_verified']) || $payload['email_verified'] !== 'true') {
        jsonError('Google email not verified', 403);
    }

    $googleId = $payload['sub'];
    $email = $payload['email'];
    $name = $payload['name'] ?? $email;
    $avatarUrl = $payload['picture'] ?? null;
    $appleId = null;

} else {
    $payload = verifyAppleToken($idToken);
    if (!$payload || !isset($payload['sub'])) {
        jsonError('Invalid Apple ID token', 401);
    }

    $appleId = $payload['sub'];
    $email = $payload['email'] ?? '';
    $name = $input['name'] ?? $email;
    $googleId = null;
    $avatarUrl = null;

    if (empty($email)) {
        jsonError('Email not provided by Apple. Please ensure email sharing is enabled.', 400);
    }
}

$user = null;
$userId = null;

if ($provider === 'google' && !empty($googleId)) {
    $stmt = $pdo->prepare('SELECT id, name, email, email_verified_at, role, avatar_url FROM users WHERE google_id = ?');
    $stmt->execute([$googleId]);
    $user = $stmt->fetch();
}

if (!$user && $provider === 'apple' && !empty($appleId)) {
    $stmt = $pdo->prepare('SELECT id, name, email, email_verified_at, role, avatar_url FROM users WHERE apple_id = ?');
    $stmt->execute([$appleId]);
    $user = $stmt->fetch();
}

if (!$user) {
    $stmt = $pdo->prepare('SELECT id, name, email, email_verified_at, role, avatar_url, google_id, apple_id FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $existingUser = $stmt->fetch();

    if ($existingUser) {
        if ($provider === 'google' && empty($existingUser['google_id'])) {
            $stmt = $pdo->prepare('UPDATE users SET google_id = ?, avatar_url = COALESCE(?, avatar_url) WHERE id = ?');
            $stmt->execute([$googleId, $avatarUrl, $existingUser['id']]);
        } elseif ($provider === 'apple' && empty($existingUser['apple_id'])) {
            $stmt = $pdo->prepare('UPDATE users SET apple_id = ? WHERE id = ?');
            $stmt->execute([$appleId, $existingUser['id']]);
        }
        $user = $existingUser;
    } else {
        $stmt = $pdo->prepare('INSERT INTO users (name, email, password, google_id, apple_id, avatar_url, email_verified_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())');
        $hashedPassword = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
        $stmt->execute([
            $name,
            $email,
            $hashedPassword,
            $provider === 'google' ? $googleId : null,
            $provider === 'apple' ? $appleId : null,
            $avatarUrl,
        ]);
        $userId = (int) $pdo->lastInsertId();
        $user = [
            'id' => $userId,
            'name' => $name,
            'email' => $email,
            'email_verified_at' => date('Y-m-d H:i:s'),
            'role' => 'user',
            'avatar_url' => $avatarUrl,
        ];
    }
}

if (!$user) {
    jsonError('Authentication failed', 500);
}

$userId = $userId ?? (int) $user['id'];

$token = bin2hex(random_bytes(32));
$stmt = $pdo->prepare("INSERT INTO api_tokens (user_id, token, expires_at, ip_address, user_agent, device_info) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY), ?, ?, ?)");
$stmt->execute([$userId, $token, $ip, $userAgent, $deviceInfo]);

logLoginAttempt($email, $userId, true, $ip, $userAgent, $provider);

jsonResponse([
    'token' => $token,
    'user' => [
        'id' => $userId,
        'name' => $user['name'],
        'email' => $user['email'],
        'email_verified' => true,
        'role' => $user['role'],
        'avatar_url' => $user['avatar_url'] ?? null,
    ],
]);
