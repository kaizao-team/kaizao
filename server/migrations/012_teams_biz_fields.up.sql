-- 012_teams_biz_fields.up.sql
-- teams 表补充业务字段：接单状态、时薪报价（原仅存于 users 表，团队实体对齐后同步维护）
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE teams
  ADD COLUMN available_status SMALLINT NOT NULL DEFAULT 1 COMMENT '接单状态 1=接单中 2=忙碌 3=休息',
  ADD COLUMN hourly_rate DECIMAL(10,2) DEFAULT NULL COMMENT '团队时薪报价';
