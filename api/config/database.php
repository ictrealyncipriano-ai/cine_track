<?php

function getDb(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $host = '127.0.0.1';
        $db   = 'cinetracker';
        $user = 'root';
        $pass = '';

        $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    }
    return $pdo;
}


function jsonResponse(mixed $data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function jsonError(string $message, int $code = 400): void {
    jsonResponse(['error' => $message], $code);
}

function getAllowedOrigin(): string {
    $origins = [
        'http://localhost:3000',
        'http://localhost:5000',
        'http://10.0.2.2:3000',
        'http://10.0.2.2:5000',
    ];
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
    return in_array($origin, $origins, true) ? $origin : '*';
}

function _rateLimitKey(string $key): string {
    return __DIR__ . '/../cache/' . md5($key) . '.lock';
}

function checkRateLimit(string $key, int $maxAttempts, int $windowMinutes): void {
    $file = _rateLimitKey($key);
    $data = @file_get_contents($file);
    $attempts = $data ? json_decode($data, true) : [];
    $attempts = array_values(array_filter($attempts, fn($t) => $t > time() - $windowMinutes * 60));
    if (count($attempts) >= $maxAttempts) {
        jsonError('Too many attempts. Please try again later.', 429);
    }
}

function incrementRateLimit(string $key, int $windowMinutes): void {
    $file = _rateLimitKey($key);
    $dir = dirname($file);
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
    $data = @file_get_contents($file);
    $attempts = $data ? json_decode($data, true) : [];
    $attempts[] = time();
    file_put_contents($file, json_encode($attempts));
}

function clearRateLimit(string $key): void {
    $file = _rateLimitKey($key);
    if (file_exists($file)) {
        @unlink($file);
    }
}

function checkAccountLockout(string $email, int $maxAttempts, int $windowMinutes): void {
    checkRateLimit("lockout:$email", $maxAttempts, $windowMinutes);
}

function incrementAccountLockout(string $email, int $maxAttempts, int $windowMinutes): void {
    incrementRateLimit("lockout:$email", $windowMinutes);
}

function clearAccountLockout(string $email): void {
    clearRateLimit("lockout:$email");
}

function getAuthUserId(): int {
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    $token = str_replace('Bearer ', '', $auth);

    if (empty($token)) {
        jsonError('Unauthorized', 401);
    }

    $pdo = getDb();
    $stmt = $pdo->prepare('SELECT user_id FROM api_tokens WHERE token = ? AND (expires_at IS NULL OR expires_at > NOW())');
    $stmt->execute([$token]);
    $row = $stmt->fetch();

    if (!$row) {
        jsonError('Invalid or expired token', 401);
    }

    return (int) $row['user_id'];
}
