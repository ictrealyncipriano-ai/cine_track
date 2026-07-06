<?php
require_once __DIR__ . '/../config/database.php';

header('Access-Control-Allow-Origin: ' . getAllowedOrigin());
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

$userId = getAuthUserId();

$pdo = getDb();
$stmt = $pdo->prepare('
    SELECT r.id, r.user_id, r.movie_id, r.rating, r.review_text, r.created_at, r.updated_at, u.name as user_name,
           m.title, m.poster_path, m.vote_average as movie_vote_average, m.release_date as movie_release_date
    FROM reviews r
    JOIN users u ON u.id = r.user_id
    LEFT JOIN (
        SELECT movie_id, MAX(title) as title, MAX(poster_path) as poster_path,
               MAX(vote_average) as vote_average, MAX(release_date) as release_date
        FROM (
            SELECT movie_id, title, poster_path, vote_average, release_date FROM watchlist
            UNION
            SELECT movie_id, title, poster_path, vote_average, release_date FROM watch_history
            UNION
            SELECT movie_id, title, poster_path, vote_average, release_date FROM favorites
        ) combined
        GROUP BY movie_id
    ) m ON m.movie_id = r.movie_id
    WHERE r.user_id = ?
    ORDER BY r.created_at DESC
');
$stmt->execute([$userId]);
$reviews = $stmt->fetchAll();

$result = [];
foreach ($reviews as $review) {
    $result[] = [
        'id' => (int) $review['id'],
        'user_id' => (int) $review['user_id'],
        'user_name' => $review['user_name'],
        'movie_id' => (int) $review['movie_id'],
        'rating' => (int) $review['rating'],
        'review_text' => $review['review_text'],
        'created_at' => $review['created_at'],
        'updated_at' => $review['updated_at'],
        'movie_title' => $review['title'] ?? 'Unknown',
        'movie_poster' => $review['poster_path'],
        'movie_vote_average' => $review['movie_vote_average'] ? (float) $review['movie_vote_average'] : null,
        'movie_release_date' => $review['movie_release_date'],
    ];
}

jsonResponse(['reviews' => $result, 'total' => count($result)]);
