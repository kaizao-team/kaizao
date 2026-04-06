-- 013_teams_budget_range.up.sql
-- 团队接单意向预算区间（元），仅存 teams 表
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE teams
  ADD COLUMN budget_min DECIMAL(10,2) DEFAULT NULL COMMENT '团队接单意向预算下限（元）',
  ADD COLUMN budget_max DECIMAL(10,2) DEFAULT NULL COMMENT '团队接单意向预算上限（元）';
