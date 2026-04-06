-- 011_teams_ai_fields.up.sql
-- teams 表新增 AI Agent 评级同步所需的业务字段
-- AI Agent 评级完成后会将 VibePower、五维度分数等写入这些字段

ALTER TABLE teams
  ADD COLUMN vibe_power           INT NOT NULL DEFAULT 0 COMMENT 'VibePower 积分',
  ADD COLUMN vibe_level           VARCHAR(20) NOT NULL DEFAULT 'vc-T1' COMMENT 'VibePower 等级 vc-T1~T10',
  ADD COLUMN level_weight         DECIMAL(3,2) NOT NULL DEFAULT 1.00 COMMENT '等级权重（撮合加权用）',
  ADD COLUMN experience_years     INT NOT NULL DEFAULT 0 COMMENT '从业年限（简历解析）',
  ADD COLUMN resume_summary       TEXT DEFAULT NULL COMMENT 'AI 生成的简历摘要',
  ADD COLUMN ai_tools             JSON DEFAULT NULL COMMENT 'AI 工具经验列表',
  ADD COLUMN review_tags          JSON DEFAULT NULL COMMENT 'AI 评审标签',
  ADD COLUMN score_tech_depth     INT NOT NULL DEFAULT 0 COMMENT '维度分-技术深度（0-150）',
  ADD COLUMN score_project_exp    INT NOT NULL DEFAULT 0 COMMENT '维度分-项目经验（0-150）',
  ADD COLUMN score_ai_proficiency INT NOT NULL DEFAULT 0 COMMENT '维度分-AI 熟练度（0-150）',
  ADD COLUMN score_portfolio      INT NOT NULL DEFAULT 0 COMMENT '维度分-作品集（0-150）',
  ADD COLUMN score_background     INT NOT NULL DEFAULT 0 COMMENT '维度分-背景（0-150）',
  ADD INDEX idx_teams_vibe (vibe_level, vibe_power);
