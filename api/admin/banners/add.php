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

$title = trim($input['title'] ?? '');
$imageUrl = trim($input['image_url'] ?? '');
$linkUrl = !empty($input['link_url']) ? trim($input['link_url']) : null;
$sortOrder = (int) ($input['sort_order'] ?? 0);
$active = isset($input['active']) ? ($input['active'] ? 1 : 0) : 1;

if (empty($title)) jsonError('title is required');
if (empty($imageUrl)) jsonError('image_url is required');

$pdo = getDb();
$stmt = $pdo->prepare('INSERT INTO banners (title, image_url, link_url, sort_order, active, created_by) VALUES (?, ?, ?, ?, ?, ?)');
$stmt->execute([$title, $imageUrl, $linkUrl, $sortOrder, $active, $adminId]);

$bannerId = (int) $pdo->lastInsertId();
logAdminAction($adminId, 'add_banner', 'banner', $bannerId, "Added banner: {$title}");

jsonResponse(['success' => true, 'id' => $bannerId]);
