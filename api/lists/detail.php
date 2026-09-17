<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError('Method not allowed', 405);
}

$listId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($listId <= 0) {
    jsonError('id is required');
}

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = max(1, min(50, (int) ($_GET['per_page'] ?? 20)));
$offset = ($page - 1) * $perPage;

$pdo = getDb();

$stmt = $pdo->prepare('
    SELECT l.id, l.user_id, l.name, l.description, l.cover_path, l.is_public, l.is_ranked, l.created_at, l.updated_at,
           u.name as owner_name, u.username as owner_username, u.avatar_url as owner_avatar
    FROM user_lists l
    JOIN users u ON u.id = l.user_id
    WHERE l.id = ?
');
$stmt->execute([$listId]);
$list = $stmt->fetch();

if (!$list) {
    jsonError('List not found', 404);
}

if (!$list['is_public']) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    $isOwner = false;
    if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ')) {
        try {
            $currentUserId = getAuthUserId();
            $isOwner = $currentUserId === (int) $list['user_id'];
        } catch (\Throwable $e) {}
    }
    if (!$isOwner) {
        jsonError('Forbidden', 403);
    }
}

$countStmt = $pdo->prepare('SELECT COUNT(*) as total FROM list_movies WHERE list_id = ?');
$countStmt->execute([$listId]);
$total = (int) $countStmt->fetch()['total'];

$moviesStmt = $pdo->prepare("
    SELECT id, movie_id, title, poster_path, release_date, vote_average, note, position, added_at
    FROM list_movies
    WHERE list_id = ?
    ORDER BY position ASC, added_at DESC
    LIMIT $perPage OFFSET $offset
");
$moviesStmt->execute([$listId]);
$movies = $moviesStmt->fetchAll();

$mappedMovies = array_map(function ($row) {
    return [
        'id' => (int) $row['id'],
        'movie_id' => (int) $row['movie_id'],
        'title' => $row['title'],
        'poster_path' => $row['poster_path'],
        'release_date' => $row['release_date'],
        'vote_average' => (float) $row['vote_average'],
        'note' => $row['note'],
        'position' => (int) $row['position'],
        'added_at' => $row['added_at'],
    ];
}, $movies);

jsonResponse([
    'list' => [
        'id' => (int) $list['id'],
        'name' => $list['name'],
        'description' => $list['description'],
        'cover_path' => $list['cover_path'],
        'is_public' => (bool) $list['is_public'],
        'is_ranked' => (bool) $list['is_ranked'],
        'created_at' => $list['created_at'],
        'updated_at' => $list['updated_at'],
        'owner' => [
            'id' => (int) $list['user_id'],
            'name' => $list['owner_name'],
            'username' => $list['owner_username'],
            'avatar_url' => $list['owner_avatar'],
        ],
    ],
    'movies' => $mappedMovies,
    'total' => $total,
    'page' => $page,
    'per_page' => $perPage,
]);
