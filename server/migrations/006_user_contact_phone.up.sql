-- 用户联系手机号（可与登录手机号不同，用于资料完善与撮合后联系）
ALTER TABLE users
    ADD COLUMN contact_phone VARCHAR(20) NULL AFTER city;
