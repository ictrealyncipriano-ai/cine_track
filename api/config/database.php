<?php

require_once __DIR__ . '/env.php';

function getDb(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        loadEnv();

        $host = getenv('DB_HOST') ?: '127.0.0.1';
        $port = getenv('DB_PORT') ?: '3306';
        $db   = getenv('DB_DATABASE') ?: 'cinetracker';
        $user = getenv('DB_USERNAME') ?: 'root';
        $pass = getenv('DB_PASSWORD') ?: '';

        $caPath = __DIR__ . '/certs/isrg-root-x1.pem';

        if (PHP_VERSION_ID >= 80500) {
            $pdo = new PDO("mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4", $user, $pass, [
                Pdo\Mysql::ATTR_SSL_CA => $caPath,
                Pdo\Mysql::ATTR_SSL_VERIFY_SERVER_CERT => false,
            ]);
        } else {
            $pdo = new PDO("mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4", $user, $pass, [
                PDO::MYSQL_ATTR_SSL_CA => $caPath,
                PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false,
            ]);
        }
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
    return getenv('CORS_ORIGIN') ?: '*';
}

function requireRole(int $userId, string ...$roles): void {
    $pdo = getDb();
    $stmt = $pdo->prepare('SELECT role FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    if (!$user || !in_array($user['role'], $roles)) {
        jsonError('Forbidden', 403);
    }
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

function checkRateLimit(string $key, int $maxAttempts = 5, int $decayMinutes = 15): void {
    $pdo = getDb();
    $cacheKey = "rate_limit:$key";
    $stmt = $pdo->prepare('SELECT value, expiration FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
    $row = $stmt->fetch();

    if ($row) {
        $expiration = (int) $row['expiration'];
        if (time() >= $expiration) {
            $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
            $stmt->execute([$cacheKey]);
            return;
        }

        $data = json_decode($row['value'], true);
        $attempts = $data['attempts'] ?? 0;

        if ($attempts >= $maxAttempts) {
            $retryAfter = $expiration - time();
            jsonError("Too many attempts. Please try again in {$retryAfter} seconds.", 429);
        }
    }
}

function incrementRateLimit(string $key, int $decayMinutes = 15): void {
    $pdo = getDb();
    $cacheKey = "rate_limit:$key";
    $expiration = time() + ($decayMinutes * 60);

    $stmt = $pdo->prepare('SELECT value FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
    $row = $stmt->fetch();

    if ($row) {
        $data = json_decode($row['value'], true);
        $data['attempts'] = ($data['attempts'] ?? 0) + 1;
        $stmt = $pdo->prepare('UPDATE cache SET value = ?, expiration = ? WHERE `key` = ?');
        $stmt->execute([json_encode($data), $expiration, $cacheKey]);
    } else {
        $data = ['attempts' => 1];
        $stmt = $pdo->prepare('INSERT INTO cache (`key`, value, expiration) VALUES (?, ?, ?)');
        $stmt->execute([$cacheKey, json_encode($data), $expiration]);
    }
}

function clearRateLimit(string $key): void {
    $pdo = getDb();
    $cacheKey = "rate_limit:$key";
    $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
}

function checkAccountLockout(string $email, int $maxAttempts = 5, int $lockoutMinutes = 15): void {
    $pdo = getDb();
    $cacheKey = "lockout:" . md5($email);
    $stmt = $pdo->prepare('SELECT value, expiration FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
    $row = $stmt->fetch();

    if ($row) {
        $expiration = (int) $row['expiration'];
        if (time() >= $expiration) {
            $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
            $stmt->execute([$cacheKey]);
            return;
        }

        $retryAfter = $expiration - time();
        jsonError("Account temporarily locked. Try again in {$retryAfter} seconds.", 429);
    }
}

function incrementAccountLockout(string $email, int $maxAttempts = 5, int $lockoutMinutes = 15): void {
    $pdo = getDb();
    $cacheKey = "lockout:" . md5($email);
    $expiration = time() + ($lockoutMinutes * 60);

    $stmt = $pdo->prepare('SELECT value FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
    $row = $stmt->fetch();

    $attempts = 1;
    if ($row) {
        $data = json_decode($row['value'], true);
        $attempts = ($data['attempts'] ?? 0) + 1;

        if ($attempts >= $maxAttempts) {
            $expiration = time() + ($lockoutMinutes * 60);
            $stmt = $pdo->prepare('UPDATE cache SET value = ?, expiration = ? WHERE `key` = ?');
            $stmt->execute([json_encode(['attempts' => $attempts, 'locked' => true]), $expiration, $cacheKey]);
            jsonError("Account temporarily locked due to too many failed attempts. Try again in {$lockoutMinutes} minutes.", 429);
        }
    }

    $stmt = $pdo->prepare('REPLACE INTO cache (`key`, value, expiration) VALUES (?, ?, ?)');
    $stmt->execute([$cacheKey, json_encode(['attempts' => $attempts]), $expiration]);
}

function clearAccountLockout(string $email): void {
    $pdo = getDb();
    $cacheKey = "lockout:" . md5($email);
    $stmt = $pdo->prepare('DELETE FROM cache WHERE `key` = ?');
    $stmt->execute([$cacheKey]);
}

function logLoginAttempt(string $email, ?int $userId, bool $success, string $ip, string $userAgent, string $provider = 'email'): void {
    $pdo = getDb();
    $stmt = $pdo->prepare('INSERT INTO login_audit (email, user_id, success, ip, user_agent, provider) VALUES (?, ?, ?, ?, ?, ?)');
    $stmt->execute([$email, $userId, $success ? 1 : 0, $ip, $userAgent, $provider]);
}

function validatePassword(string $password): ?string {
    if (strlen($password) < 8) return 'Password must be at least 8 characters';
    if (strlen($password) > 72) return 'Password must not exceed 72 characters';
    if (!preg_match('/[A-Z]/', $password)) return 'Password must contain at least one uppercase letter';
    if (!preg_match('/[a-z]/', $password)) return 'Password must contain at least one lowercase letter';
    if (!preg_match('/[0-9]/', $password)) return 'Password must contain at least one digit';
    return null;
}

function getAppUrl(): string {
    $envUrl = getenv('APP_URL');
    if (!empty($envUrl)) {
        return rtrim($envUrl, '/');
    }
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $scriptDir = dirname($_SERVER['SCRIPT_NAME'] ?? '');
    $baseDir = dirname($scriptDir);
    return $protocol . '://' . $host . $baseDir;
}
