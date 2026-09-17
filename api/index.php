<?php
// Vercel PHP front-controller — routes all /api/* requests to the correct PHP file.

$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

$relativePath = preg_replace('#^/api/#', '', $path);
$relativePath = str_replace(['..', "\0"], '', $relativePath);
$relativePath = ltrim($relativePath, '/');

$targetFile = __DIR__ . '/' . $relativePath;
if (!str_ends_with($targetFile, '.php')) {
    $targetFile .= '.php';
}

$realBase = realpath(__DIR__);
$realTarget = realpath($targetFile);

if ($realTarget === false || !str_starts_with($realTarget, $realBase) || !file_exists($targetFile)) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Endpoint not found']);
    exit;
}

$_SERVER['SCRIPT_NAME'] = '/' . $relativePath;
$_SERVER['SCRIPT_FILENAME'] = $realTarget;

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit;
}

require $targetFile;
