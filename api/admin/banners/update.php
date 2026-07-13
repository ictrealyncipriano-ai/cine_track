<?php
require_once __DIR__ . '/../../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$adminId = getAuthUserId();
requireRole($adminId, 'admin');

$input = json_decode(file_get_contents('php://input'), true);
$bannerId = (int) ($input['id'] ?? 0);
if ($bannerId <= 0) jsonError('id is required');

$pdo = getDb();
$stmt = $pdo->prepare('SELECT id FROM banners WHERE id = ?');
$stmt->execute([$bannerId]);
if (!$stmt->fetch()) jsonError('Banner not found', 404);

$fields = [];
$params = [];

foreach (['title', 'image_url', 'link_url'] as $field) {
    if (isset($input[$field])) {
        $fields[] = "{$field} = ?";
        $params[] = $input[$field];
    }
}
if (isset($input['sort_order'])) {
    $fields[] = 'sort_order = ?';
    $params[] = (int) $input['sort_order'];
}
if (isset($input['active'])) {
    $fields[] = 'active = ?';
    $params[] = $input['active'] ? 1 : 0;
}

if (!empty($fields)) {
    $params[] = $bannerId;
    $stmt = $pdo->prepare('UPDATE banners SET ' . implode(', ', $fields) . ' WHERE id = ?');
    $stmt->execute($params);
    logAdminAction($adminId, 'update_banner', 'banner', $bannerId, 'Updated banner');
}

jsonResponse(['success' => true]);
