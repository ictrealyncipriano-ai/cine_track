-- Migration 001: Deduplicate watch_history and add unique constraint
-- Run this BEFORE deploying the code changes to avoid errors

-- Step 1: Remove duplicate entries, keeping only the latest watch per (user_id, movie_id)
DELETE w1 FROM watch_history w1
INNER JOIN watch_history w2
WHERE w1.user_id = w2.user_id
  AND w1.movie_id = w2.movie_id
  AND w1.watched_at < w2.watched_at;

-- Step 2: Add unique constraint (safe to run after dedup)
ALTER TABLE watch_history ADD UNIQUE KEY unique_user_movie (user_id, movie_id);

-- Step 3: Drop the old index on user_id alone (now covered by the unique key)
ALTER TABLE watch_history DROP INDEX idx_user_id;
