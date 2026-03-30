-- 将历史项目分类清洗为服务端当前枚举：data | dev | visual | solution
-- 映射：app/web/miniprogram -> dev；design -> visual；consult -> solution；data 保持

UPDATE projects
SET category = CASE LOWER(TRIM(category))
    WHEN 'data' THEN 'data'
    WHEN 'dev' THEN 'dev'
    WHEN 'visual' THEN 'visual'
    WHEN 'solution' THEN 'solution'
    WHEN 'app' THEN 'dev'
    WHEN 'web' THEN 'dev'
    WHEN 'miniprogram' THEN 'dev'
    WHEN 'design' THEN 'visual'
    WHEN 'consult' THEN 'solution'
    ELSE 'dev'
END
WHERE category IS NOT NULL
  AND TRIM(category) <> ''
  AND LOWER(TRIM(category)) NOT IN ('data', 'dev', 'visual', 'solution');
