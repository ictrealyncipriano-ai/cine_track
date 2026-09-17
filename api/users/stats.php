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

$userId = getAuthUserId();

$pdo = getDb();

// Movies watched
$moviesStmt = $pdo->prepare('SELECT COUNT(DISTINCT movie_id) as count FROM watch_history WHERE user_id = ?');
$moviesStmt->execute([$userId]);
$moviesWatched = (int) $moviesStmt->fetch()['count'];

// Total runtime (sum of runtime from watch_history)
$runtimeStmt = $pdo->prepare('SELECT COALESCE(SUM(runtime), 0) as total FROM watch_history WHERE user_id = ?');
$runtimeStmt->execute([$userId]);
$totalRuntime = (int) $runtimeStmt->fetch()['total'];

// Hours watched
$hoursWatched = $totalRuntime > 0 ? round($totalRuntime / 60, 1) : 0;

// Genre breakdown (join with movies table)
$genreStmt = $pdo->prepare("
    SELECT m.genres, COUNT(*) as count
    FROM watch_history wh
    JOIN movies m ON m.tmdb_id = wh.movie_id
    WHERE wh.user_id = ? AND m.genres IS NOT NULL AND m.genres != ''
    GROUP BY m.genres
    ORDER BY count DESC
");
$genreStmt->execute([$userId]);
$genreRows = $genreStmt->fetchAll();

$genreBreakdown = [];
foreach ($genreRows as $row) {
    $genreNames = explode(',', $row['genres']);
    foreach ($genreNames as $genre) {
        $genre = trim($genre);
        if (empty($genre)) continue;
        if (!isset($genreBreakdown[$genre])) {
            $genreBreakdown[$genre] = 0;
        }
        $genreBreakdown[$genre] += (int) $row['count'];
    }
}

$genreList = [];
foreach ($genreBreakdown as $name => $count) {
    $genreList[] = ['genre' => $name, 'count' => $count];
}
usort($genreList, fn($a, $b) => $b['count'] <=> $a['count']);
$genreList = array_slice($genreList, 0, 10);

// Monthly activity
$monthlyStmt = $pdo->prepare("
    SELECT DATE_FORMAT(watched_at, '%Y-%m') as month, COUNT(*) as count
    FROM watch_history
    WHERE user_id = ?
    GROUP BY month
    ORDER BY month ASC
");
$monthlyStmt->execute([$userId]);
$monthlyActivity = $monthlyStmt->fetchAll();

$monthlyList = array_map(fn($row) => [
    'month' => $row['month'],
    'count' => (int) $row['count'],
], $monthlyActivity);

// Rating distribution (from reviews)
$ratingStmt = $pdo->prepare("
    SELECT rating, COUNT(*) as count
    FROM reviews
    WHERE user_id = ? AND status = 'approved'
    GROUP BY rating
    ORDER BY rating DESC
");
$ratingStmt->execute([$userId]);
$ratingDistribution = array_map(fn($row) => [
    'rating' => (int) $row['rating'],
    'count' => (int) $row['count'],
], $ratingStmt->fetchAll());

// Reviews written
$reviewsStmt = $pdo->prepare('SELECT COUNT(*) as count FROM reviews WHERE user_id = ?');
$reviewsStmt->execute([$userId]);
$reviewsWritten = (int) $reviewsStmt->fetch()['count'];

// Lists created
$listsStmt = $pdo->prepare('SELECT COUNT(*) as count FROM user_lists WHERE user_id = ?');
$listsStmt->execute([$userId]);
$listsCreated = (int) $listsStmt->fetch()['count'];

// Streak calculation
$streakStmt = $pdo->prepare("
    SELECT DISTINCT DATE(watched_at) as watch_date
    FROM watch_history
    WHERE user_id = ?
    ORDER BY watch_date DESC
");
$streakStmt->execute([$userId]);
$dates = $streakStmt->fetchAll(PDO::FETCH_COLUMN);

$currentStreak = 0;
$longestStreak = 0;
$tempStreak = 0;

if (!empty($dates)) {
    $today = new DateTime();
    $today->setTime(0, 0, 0);
    $prevDate = null;

    foreach ($dates as $dateStr) {
        $date = new DateTime($dateStr);
        $date->setTime(0, 0, 0);

        if ($prevDate === null) {
            $diff = $today->diff($date)->days;
            if ($diff <= 1) {
                $tempStreak = 1;
                $currentStreak = 1;
            } else {
                $tempStreak = 0;
                $currentStreak = 0;
            }
        } else {
            $diff = $prevDate->diff($date)->days;
            if ($diff === 1) {
                $tempStreak++;
            } else {
                if ($tempStreak > $longestStreak) $longestStreak = $tempStreak;
                $tempStreak = 1;
            }
            $currentStreak = $tempStreak;
        }
        $prevDate = $date;
    }

    if ($tempStreak > $longestStreak) $longestStreak = $tempStreak;
}

jsonResponse([
    'movies_watched' => $moviesWatched,
    'total_runtime_minutes' => $totalRuntime,
    'hours_watched' => $hoursWatched,
    'genre_breakdown' => $genreList,
    'monthly_activity' => $monthlyList,
    'rating_distribution' => $ratingDistribution,
    'reviews_written' => $reviewsWritten,
    'lists_created' => $listsCreated,
    'current_streak' => $currentStreak,
    'longest_streak' => $longestStreak,
]);
