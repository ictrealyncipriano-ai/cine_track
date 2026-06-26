<?php
require_once __DIR__ . '/config/database.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: text/plain');

try {
    $pdo = getDb();

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS watch_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            movie_id INT NOT NULL,
            title VARCHAR(255) DEFAULT '',
            overview TEXT,
            poster_path VARCHAR(255),
            backdrop_path VARCHAR(255),
            release_date VARCHAR(20) DEFAULT '',
            vote_average DECIMAL(3,1) DEFAULT 0.0,
            watched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_id (user_id),
            INDEX idx_user_watched (user_id, watched_at DESC)
        )
    ");
    echo "OK: watch_history table created/verified\n";

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS reviews (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            movie_id INT NOT NULL,
            rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 10),
            review_text TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_user_movie (user_id, movie_id),
            INDEX idx_movie_id (movie_id)
        )
    ");
    echo "OK: reviews table created/verified\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
