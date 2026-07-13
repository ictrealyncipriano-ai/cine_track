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
$stmt = $pdo->prepare('SELECT title FROM banners WHERE id = ?');
$stmt->execute([$bannerId]);
$banner = $stmt->fetch();
if (!$banner) jsonError('Banner not found', 404);

$stmt = $pdo->prepare('DELETE FROM banners WHERE id = ?');
$stmt->execute([$bannerId]);

logAdminAction($adminId, 'delete_banner', 'banner', $bannerId, "Deleted banner: {$banner['title']}");

jsonResponse(['success' => true]);
