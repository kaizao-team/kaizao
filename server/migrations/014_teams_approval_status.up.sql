ALTER TABLE teams ADD COLUMN approval_status SMALLINT NOT NULL DEFAULT 1;

-- 存量团队默认审核通过
UPDATE teams SET approval_status = 2 WHERE approval_status = 1;
