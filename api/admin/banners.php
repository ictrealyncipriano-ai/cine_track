<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$userId = getAuthUserId();
requireRole($userId, 'admin');

$pdo = getDb();

$stmt = $pdo->query('SELECT id, title, image_url, link_url, sort_order, active, created_at, updated_at FROM banners ORDER BY sort_order ASC, id ASC');
$banners = $stmt->fetchAll();

jsonResponse(['banners' => $banners]);
