<?php
require_once __DIR__ . '/../config/database.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$userId = getAuthUserId();
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

if ($action === 'list') {
    checkRateLimit("sessions_list:{$userId}", 30, 1);

    $pdo = getDb();
    $currentToken = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $currentToken = str_replace('Bearer ', '', $currentToken);

    $stmt = $pdo->prepare(
        'SELECT id, token, created_at, expires_at, last_used_at, ip_address, user_agent, device_info, remember_me
           FROM api_tokens
          WHERE user_id = ?
          ORDER BY FIELD(token, ?) DESC, last_used_at DESC, created_at DESC'
    );
    $stmt->execute([$userId, $currentToken]);
    $tokens = $stmt->fetchAll();

    $now = date('Y-m-d H:i:s');

    $sessions = array_map(function ($t) use ($currentToken, $now) {
        $deviceInfo = $t['device_info'] ? json_decode($t['device_info'], true) : null;
        return [
            'id' => (int)$t['id'],
            'created_at' => $t['created_at'],
            'expires_at' => $t['expires_at'],
            'last_used_at' => $t['last_used_at'],
            'ip_address' => $t['ip_address'] ?? '',
            'user_agent' => $t['user_agent'] ?? '',
            'device_info' => $deviceInfo,
            'is_current' => $t['token'] === $currentToken,
            'is_expired' => $t['expires_at'] !== null && $t['expires_at'] < $now,
            'remember_me' => (bool)$t['remember_me'],
        ];
    }, $tokens);

    jsonResponse(['sessions' => $sessions]);
}

if ($action === 'revoke') {
    checkRateLimit("sessions_revoke:{$userId}", 10, 1);

    $sessionId = (int)($input['session_id'] ?? 0);
    if ($sessionId <= 0) {
        jsonError('Invalid session ID');
    }

    $pdo = getDb();

    $currentToken = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $currentToken = str_replace('Bearer ', '', $currentToken);

    $stmt = $pdo->prepare('SELECT token, device_info, ip_address, user_agent FROM api_tokens WHERE id = ? AND user_id = ?');
    $stmt->execute([$sessionId, $userId]);
    $token = $stmt->fetch();

    if (!$token) {
        jsonError('Session not found');
    }

    if ($token['token'] === $currentToken) {
        jsonError('Cannot revoke current session');
    }

    $deviceInfo = $token['device_info'] ?: '';
    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE id = ? AND user_id = ?');
    $stmt->execute([$sessionId, $userId]);

    logLoginAttempt('', $userId, false, $token['ip_address'] ?? '', $token['user_agent'] ?? '', 'session_revoke');

    jsonResponse(['message' => 'Session revoked']);
}

if ($action === 'revoke_all') {
    checkRateLimit("sessions_revoke_all:{$userId}", 3, 1);

    $pdo = getDb();

    $currentToken = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $currentToken = str_replace('Bearer ', '', $currentToken);

    $stmt = $pdo->prepare('SELECT id, ip_address, user_agent FROM api_tokens WHERE user_id = ? AND token != ?');
    $stmt->execute([$userId, $currentToken]);
    $others = $stmt->fetchAll();

    $count = count($others);
    if ($count === 0) {
        jsonResponse(['message' => 'No other sessions to revoke']);
    }

    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE user_id = ? AND token != ?');
    $stmt->execute([$userId, $currentToken]);

    logLoginAttempt('', $userId, false, $_SERVER['REMOTE_ADDR'] ?? '', $_SERVER['HTTP_USER_AGENT'] ?? '', 'session_revoke_all');

    jsonResponse(['message' => "{$count} session(s) revoked"]);
}

jsonError('Invalid action');
