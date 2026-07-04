-- Migration 000: Create watch_history table
CREATE TABLE IF NOT EXISTS watch_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    movie_id INT NOT NULL,
    title VARCHAR(255) DEFAULT '',
    overview TEXT,
    poster_path VARCHAR(255),
    backdrop_path VARCHAR(255),
    release_date VARCHAR(20) DEFAULT '',
    vote_average DECIMAL(3,1) DEFAULT 0.0,
    watched_at DATETIME NOT NULL,
    watch_count INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_movie (user_id, movie_id),
    INDEX idx_user_id (user_id)
);
