ALTER TABLE api_tokens
  ADD COLUMN last_used_at DATETIME DEFAULT NULL AFTER expires_at,
  ADD COLUMN remember_me TINYINT(1) DEFAULT 0 AFTER device_info;
