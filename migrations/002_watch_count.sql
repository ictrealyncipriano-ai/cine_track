-- Step 1: Add watch_count column with default 1
ALTER TABLE watch_history ADD COLUMN watch_count INT DEFAULT 1;

-- Step 2: Migrate existing duplicates into count (keep latest row, sum counts)
UPDATE watch_history w1
JOIN (
    SELECT user_id, movie_id, MAX(watched_at) AS latest_watch, COUNT(*) AS total
    FROM watch_history
    GROUP BY user_id, movie_id
    HAVING COUNT(*) > 1
) w2 ON w1.user_id = w2.user_id AND w1.movie_id = w2.movie_id AND w1.watched_at = w2.latest_watch
SET w1.watch_count = w2.total;

-- Step 3: Delete duplicate rows (keep only the latest per user+movie)
DELETE w1 FROM watch_history w1
INNER JOIN watch_history w2
WHERE w1.user_id = w2.user_id
  AND w1.movie_id = w2.movie_id
  AND w1.watched_at < w2.watched_at;

-- Step 4: Add unique constraint to prevent future duplicates
ALTER TABLE watch_history ADD UNIQUE KEY unique_user_movie (user_id, movie_id);

-- Step 5: Drop old redundant index
ALTER TABLE watch_history DROP INDEX idx_user_id;
