-- 004_add_admin_features.sql
-- Adds moderation columns to reviews, ban/soft-delete to users,
-- review_reports table for user-submitted reports,
-- and admin_logs table for audit trail.

-- 1. Reviews: moderation columns
ALTER TABLE reviews
  ADD COLUMN status ENUM('pending','approved','rejected','reported') NOT NULL DEFAULT 'pending',
  ADD COLUMN moderated_by INT NULL,
  ADD COLUMN moderated_at DATETIME NULL,
  ADD COLUMN moderation_note TEXT NULL,
  ADD INDEX idx_reviews_status (status);

-- 2. Users: ban + soft-delete
ALTER TABLE users
  ADD COLUMN banned_at DATETIME NULL,
  ADD COLUMN deleted_at DATETIME NULL,
  ADD INDEX idx_users_deleted (deleted_at);

-- 3. Review reports table (user-submitted reports)
CREATE TABLE IF NOT EXISTS review_reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_id INT NOT NULL,
  reported_by INT NOT NULL,
  reason VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_report_review (review_id)
);

-- 4. Admin audit log table
CREATE TABLE IF NOT EXISTS admin_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50) NOT NULL,
  target_id INT NULL,
  details TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_admin_logs_admin (admin_id),
  INDEX idx_admin_logs_created (created_at)
);
