-- 账号密码注册：登录名（用户名）
ALTER TABLE users
    ADD COLUMN username VARCHAR(50) NULL COMMENT '登录用户名（密码注册）' AFTER uuid;

CREATE UNIQUE INDEX idx_users_username ON users (username);
