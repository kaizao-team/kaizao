-- 账号密码注册：登录名（用户名）
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET CHARACTER SET utf8mb4;
ALTER TABLE users
    ADD COLUMN username VARCHAR(50) NULL COMMENT '登录用户名（密码注册）' AFTER uuid;

CREATE UNIQUE INDEX idx_users_username ON users (username);
