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
    $pdo = getDb();
    $currentToken = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $currentToken = str_replace('Bearer ', '', $currentToken);

    $stmt = $pdo->prepare('SELECT id, token, created_at, expires_at FROM api_tokens WHERE user_id = ? ORDER BY created_at DESC');
    $stmt->execute([$userId]);
    $tokens = $stmt->fetchAll();

    $sessions = array_map(function ($t) use ($currentToken) {
        return [
            'id' => (int)$t['id'],
            'created_at' => $t['created_at'],
            'expires_at' => $t['expires_at'],
            'is_current' => $t['token'] === $currentToken,
        ];
    }, $tokens);

    jsonResponse(['sessions' => $sessions]);
}

if ($action === 'revoke') {
    $sessionId = (int)($input['session_id'] ?? 0);
    if ($sessionId <= 0) {
        jsonError('Invalid session ID');
    }

    $pdo = getDb();

    $currentToken = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $currentToken = str_replace('Bearer ', '', $currentToken);

    $stmt = $pdo->prepare('SELECT token FROM api_tokens WHERE id = ? AND user_id = ?');
    $stmt->execute([$sessionId, $userId]);
    $token = $stmt->fetch();

    if (!$token) {
        jsonError('Session not found');
    }

    if ($token['token'] === $currentToken) {
        jsonError('Cannot revoke current session');
    }

    $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE id = ? AND user_id = ?');
    $stmt->execute([$sessionId, $userId]);

    jsonResponse(['message' => 'Session revoked']);
}

jsonError('Invalid action');
