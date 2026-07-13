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

if (empty($input['settings']) || !is_array($input['settings'])) {
    jsonError('settings array is required');
}

$pdo = getDb();

$allowedKeys = [
    'allow_registrations',
    'maintenance_mode',
    'default_user_role',
    'require_email_verification',
];

$stmt = $pdo->prepare('INSERT INTO app_settings (`key`, `value`, `updated_by`, `updated_at`)
    VALUES (?, ?, ?, NOW())
    ON DUPLICATE KEY UPDATE `value` = VALUES(`value`), `updated_by` = VALUES(`updated_by`), `updated_at` = NOW()');

$updated = [];
foreach ($input['settings'] as $key => $value) {
    if (!in_array($key, $allowedKeys, true)) continue;
    $stringValue = is_bool($value) ? ($value ? 'true' : 'false') : (string) $value;
    $stmt->execute([$key, $stringValue, $adminId]);
    $updated[] = $key;
}

logAdminAction($adminId, 'update_settings', 'app_settings', null, 'Updated: ' . implode(', ', $updated));

jsonResponse(['success' => true, 'updated' => $updated]);
