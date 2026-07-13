-- 006_create_settings_table.sql
-- Creates a key-value settings table for admin-configurable application settings.
-- Run this on your database after the existing schema.

CREATE TABLE IF NOT EXISTS app_settings (
    `key` VARCHAR(100) PRIMARY KEY,
    `value` TEXT NOT NULL,
    `type` VARCHAR(50) DEFAULT 'string',
    `label` VARCHAR(255) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `updated_by` INT DEFAULT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Default settings
INSERT IGNORE INTO app_settings (`key`, `value`, `type`, `label`, `description`) VALUES
('allow_registrations', 'true', 'boolean', 'Allow New Registrations', 'Enable or disable new user signups'),
('maintenance_mode', 'false', 'boolean', 'Maintenance Mode', 'Put the site in maintenance mode (blocks all non-admin access)'),
('default_user_role', 'user', 'select', 'Default User Role', 'Role assigned to newly registered users'),
('require_email_verification', 'true', 'boolean', 'Require Email Verification', 'Require users to verify their email before accessing the app');
