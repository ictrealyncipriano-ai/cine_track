<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();
requireRole($userId, 'admin');

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(100, (int) ($_GET['per_page'] ?? 30)));
$email = $_GET['email'] ?? '';
$success = $_GET['success'] ?? '';
$dateFrom = $_GET['date_from'] ?? '';
$dateTo = $_GET['date_to'] ?? '';

$pdo = getDb();

$where = ['1=1'];
$params = [];

if (!empty($email)) {
    $where[] = 'la.email LIKE ?';
    $params[] = "%{$email}%";
}

if ($success === '1' || $success === '0') {
    $where[] = 'la.success = ?';
    $params[] = (int) $success;
}

if (!empty($dateFrom)) {
    $where[] = 'la.created_at >= ?';
    $params[] = $dateFrom;
}

if (!empty($dateTo)) {
    $where[] = 'la.created_at <= ?';
    $params[] = "{$dateTo} 23:59:59";
}

$whereClause = implode(' AND ', $where);

$stmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM login_audit la WHERE {$whereClause}");
$stmt->execute($params);
$total = (int) $stmt->fetch()['cnt'];

$offset = ($page - 1) * $perPage;
$stmt = $pdo->prepare("
    SELECT la.id, la.email, la.user_id, la.success, la.ip, la.user_agent, la.provider, la.created_at,
           u.name AS user_name
    FROM login_audit la
    LEFT JOIN users u ON u.id = la.user_id
    WHERE {$whereClause}
    ORDER BY la.created_at DESC
    LIMIT ? OFFSET ?
");
$executeParams = array_merge($params, [$perPage, $offset]);
$stmt->execute($executeParams);
$logs = $stmt->fetchAll();

// Sanitize IPs for display (mask last octet)
foreach ($logs as &$log) {
    $ip = $log['ip'];
    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
        $parts = explode('.', $ip);
        if (count($parts) === 4) {
            $parts[3] = 'xxx';
            $log['ip'] = implode('.', $parts);
        }
    } elseif (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
        $log['ip'] = substr($ip, 0, strrpos($ip, ':')) . ':xxxx';
    }
}
unset($log);

jsonResponse([
    'logs' => $logs,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
