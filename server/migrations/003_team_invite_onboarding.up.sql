-- 团队邀请码：team 维度、核销后轮换；用户入驻材料字段
ALTER TABLE invite_codes
    ADD COLUMN team_id BIGINT NULL COMMENT '所属团队，核销后新码仍属同一团队' AFTER uuid,
    ADD COLUMN code_plain VARCHAR(32) NULL COMMENT '当前有效码明文，供管理端查看' AFTER code_hash;

CREATE INDEX idx_invite_codes_team_id ON invite_codes (team_id);

ALTER TABLE users
    ADD COLUMN resume_url VARCHAR(512) NULL COMMENT '入驻申请：简历/作品链接' AFTER onboarding_reviewer_id,
    ADD COLUMN onboarding_application_note TEXT NULL COMMENT '入驻申请说明' AFTER resume_url,
    ADD COLUMN onboarding_submitted_at DATETIME NULL COMMENT '提交材料进入审核队列的时间' AFTER onboarding_application_note;

-- 无团队时插入占位团队（leader_id=1 无 FK，便于空库启动）
INSERT INTO teams (uuid, name, leader_id, team_type, status, skills_coverage, member_count, avg_rating, total_projects, total_earnings)
SELECT '11111111-1111-1111-1111-111111111111', '默认团队', 1, 1, 1, '[]', 1, 0, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM teams LIMIT 1);

UPDATE invite_codes ic
SET team_id = (SELECT id FROM teams WHERE uuid = '11111111-1111-1111-1111-111111111111' LIMIT 1)
WHERE ic.team_id IS NULL
  AND EXISTS (SELECT 1 FROM teams WHERE uuid = '11111111-1111-1111-1111-111111111111');
