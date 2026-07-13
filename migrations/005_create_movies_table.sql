-- 005_create_movies_table.sql
-- Creates a central movies table for admin-managed movie metadata.
-- Run this on your database after the existing schema.

CREATE TABLE IF NOT EXISTS movies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tmdb_id INT NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    overview TEXT,
    poster_path VARCHAR(255),
    backdrop_path VARCHAR(255),
    release_date VARCHAR(20),
    vote_average DECIMAL(3,1) DEFAULT 0.0,
    vote_count INT DEFAULT 0,
    genres VARCHAR(500),
    runtime INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'published',
    featured TINYINT(1) DEFAULT 0,
    created_by INT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tmdb (tmdb_id),
    INDEX idx_featured (featured),
    INDEX idx_status (status)
);

-- Seed from existing interaction tables (deduplicates by tmdb_id)
INSERT IGNORE INTO movies (tmdb_id, title, poster_path, created_at)
SELECT DISTINCT movie_id, MAX(title), MAX(poster_path), MIN(created_at)
FROM (
    SELECT movie_id, title, poster_path, created_at FROM watchlist
    UNION ALL
    SELECT movie_id, title, poster_path, created_at FROM favorites
    UNION ALL
    SELECT movie_id, NULL AS title, NULL AS poster_path, MIN(created_at) FROM reviews GROUP BY movie_id
    UNION ALL
    SELECT movie_id, title, poster_path, created_at FROM watch_history
) AS all_movies
WHERE movie_id IS NOT NULL
GROUP BY movie_id;
