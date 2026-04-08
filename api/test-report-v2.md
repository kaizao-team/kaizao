# Kaizao API v2 测试报告

- **测试时间**: 2026-04-08 22:45:28
- **服务地址**: http://127.0.0.1:39527
- **总计**: 222 | **通过**: 222 | **失败**: 0

## 测试结果

| # | 测试用例 | 结果 | HTTP | Code |
|---|---------|------|------|------|
| 1 | 1.1 POST /auth/sms-code | PASS | 200 | 0 |
| 2 | 1.2 POST /auth/login (wrong code) | PASS | 400 | 10003 |
| 3 | 1.3 POST /auth/login (correct) | PASS | 200 | 0 |
| 4 | 1.4 POST /auth/refresh | PASS | 200 | 0 |
| 5 | 1.4b1 GET /auth/password-key | PASS | 200 | 0 |
| 6 | 1.4b1a password-key meta | PASS | 200 | 0 |
| 7 | 1.4b2 GET /auth/captcha | PASS | 200 | 0 |
| 8 | 1.4b2a captcha fields | PASS | 200 | 0 |
| 9 | 1.4b3 POST /auth/register-password (forbidden root password field -> 10023) | PASS | 400 | 10023 |
| 10 | 1.4b4 POST /auth/register-password (invalid username -> 10020) | PASS | 400 | 10020 |
| 11 | 1.4b5 POST /auth/register-password | PASS | 200 | 0 |
| 12 | 1.4b5a POST /auth/register-password (phone only, no sms_code) | PASS | 200 | 0 |
| 13 | 1.4b5b POST /auth/register-password (sms_code without phone -> 99001) | PASS | 400 | 99001 |
| 14 | 1.4b8 POST /auth/register-password (duplicate username -> 10021) | PASS | 400 | 10021 |
| 15 | 1.4b6 POST /auth/login-password | PASS | 200 | 0 |
| 16 | 1.4b6a login-password token | PASS | 200 | 0 |
| 17 | 1.4b7 POST /auth/login-password (wrong captcha -> 10026) | PASS | 400 | 10026 |
| 18 | 1.5a POST /admin/invite-codes (batch create) | PASS | 200 | 0 |
| 19 | 1.5a1 batch invite-codes count | PASS | 200 | 0 |
| 20 | 1.5b GET /admin/invite-codes | PASS | 200 | 0 |
| 21 | 2.1 GET /users/me | PASS | 200 | 0 |
| 22 | 2.2 PUT /users/me | PASS | 200 | 0 |
| 23 | 2.2d PUT /users/me (contact_phone) | PASS | 200 | 0 |
| 24 | 2.2e GET /me contact_phone | PASS | 200 | 0 |
| 25 | 2.2b PUT /users/me/skills | PASS | 200 | 0 |
| 26 | 2.2c GET /me skills roundtrip | PASS | 200 | 0 |
| 27 | 2.2f PUT /users/me (hourly_rate+available_status) | PASS | 200 | 0 |
| 28 | 2.2f hourly_rate/available_status roundtrip | PASS | 200 | 0 |
| 29 | 2.2f2 PUT /users/me (restore available_status) | PASS | 200 | 0 |
| 30 | 2.2h create team (skipped) | PASS | 200 | 0 |
| 31 | 2.3 GET /users/:id (profile) | PASS | 200 | 0 |
| 32 | 2.4 PUT /users/:id (update) | PASS | 200 | 0 |
| 33 | 2.5 GET /users/:id/skills | PASS | 200 | 0 |
| 34 | 2.6 GET /users/:id/portfolios | PASS | 200 | 0 |
| 35 | 2.6b POST /users/me/portfolios | PASS | 200 | 0 |
| 36 | 2.6b2 GET /me/portfolios 401 | PASS | 401 | 10008 |
| 37 | 2.6c GET /users/me/portfolios | PASS | 200 | 0 |
| 38 | 2.6c1 GET /me/portfolios fields | PASS | 200 | 0 |
| 39 | 2.6d GET /users/:id/portfolios (same user) | PASS | 200 | 0 |
| 40 | 2.6d1 GET /users/:id/portfolios sync | PASS | 200 | 0 |
| 41 | 2.6e0 PUT /users/me/portfolios/:uuid (category empty -> 99001) | PASS | 400 | 99001 |
| 42 | 2.6e0c PUT /users/me/portfolios/:uuid (category whitespace -> 99001) | PASS | 400 | 99001 |
| 43 | 2.6e0b PUT /users/me/portfolios/:uuid (category invalid -> 99001) | PASS | 400 | 99001 |
| 44 | 2.6e PUT /users/me/portfolios/:uuid | PASS | 200 | 0 |
| 45 | 2.6e1 PUT portfolio roundtrip | PASS | 200 | 0 |
| 46 | 2.6f DELETE /users/me/portfolios/:uuid | PASS | 200 | 0 |
| 47 | 2.6f1 DELETE soft list | PASS | 200 | 0 |
| 48 | 2.7b POST /users/me/portfolios (cover_url from upload) | PASS | 200 | 0 |
| 49 | 2.7b1 portfolio cover_url roundtrip | PASS | 200 | 0 |
| 50 | 2.7c DELETE /users/me/portfolios (cover portfolio) | PASS | 200 | 0 |
| 51 | 2.7 POST /upload image | PASS | 200 | 0 |
| 52 | 3.1 POST /projects (create) | PASS | 200 | 0 |
| 53 | 3.2n GET /projects without auth -> 401 | PASS | 401 | 10008 |
| 54 | 3.2 GET /projects (list, mine) | PASS | 200 | 0 |
| 55 | 3.2a GET /projects?role=1 (demander) | PASS | 200 | 0 |
| 56 | 3.2b GET /projects?role=2 (expert) | PASS | 200 | 0 |
| 57 | 3.3 GET /projects/:id (detail) | PASS | 200 | 0 |
| 58 | 3.3b prd_summary field | PASS | 200 | 0 |
| 59 | 3.3c milestones field | PASS | 200 | 0 |
| 60 | 3.4 PUT /projects/:id (update) | PASS | 200 | 0 |
| 61 | 3.5 GET /projects/:id/recommendations (AI) | PASS | 200 | 0 |
| 62 | 3.5b GET /projects/:id/recommendations (team-shaped rows) | PASS | 200 | 0 |
| 63 | 4.1 GET /home/demander | PASS | 200 | 0 |
| 64 | 4.2 GET /home/expert | PASS | 200 | 0 |
| 65 | 5.1 GET /market/projects | PASS | 200 | 0 |
| 66 | 5.2 GET /market/projects (filter) | PASS | 200 | 0 |
| 67 | 5.3 GET /market/experts | PASS | 200 | 0 |
| 68 | 5.4a1 POST /favorites (invalid target_type -> 99001) | PASS | 400 | 99001 |
| 69 | 5.4a2 POST /favorites (project not found -> 20001) | PASS | 404 | 20001 |
| 70 | 5.4a3 POST /favorites (self as expert, ineligible -> 30010) | PASS | 400 | 30010 |
| 71 | 5.4a4 POST /favorites (expert uuid not found -> 30010) | PASS | 400 | 30010 |
| 72 | 5.4b POST /favorites (project) | PASS | 200 | 0 |
| 73 | 5.4b1 favorite_count +1 | PASS | 200 | 0 |
| 74 | 5.4c POST /favorites (project, idempotent) | PASS | 200 | 0 |
| 75 | 5.4c1 favorite idempotent count | PASS | 200 | 0 |
| 76 | 5.4d GET /users/me/favorites?target_type=project | PASS | 200 | 0 |
| 77 | 5.4d1 GET /me/favorites project | PASS | 200 | 0 |
| 78 | 5.4e DELETE /favorites (project) | PASS | 200 | 0 |
| 79 | 5.4e1 favorite_count restored | PASS | 200 | 0 |
| 80 | 5.4f DELETE /favorites (project, idempotent) | PASS | 200 | 0 |
| 81 | 5.4f DELETE idempotent | PASS | 200 | 0 |
| 82 | 5.4g DELETE /favorites (invalid target_type -> 99001) | PASS | 400 | 99001 |
| 83 | 5.4j concurrent favorite + atomic count | PASS | 200 | 0 |
| 84 | 6.1 POST /projects/ai-chat | PASS | 200 | 0 |
| 85 | 6.2 POST /projects/generate-prd | PASS | 200 | 0 |
| 86 | 6.3 POST /projects/draft | PASS | 200 | 0 |
| 87 | 6.3n1 POST /projects/draft (negative budget_min -> 99001) | PASS | 400 | 99001 |
| 88 | 6.3n2 POST /projects/draft (negative budget_max -> 99001) | PASS | 400 | 99001 |
| 89 | 6.3n3 POST /projects/draft (invalid match_mode -> 99001) | PASS | 400 | 99001 |
| 90 | 6.3n4 POST /projects/draft (budget_max < budget_min -> 99001) | PASS | 400 | 99001 |
| 91 | 6.3b POST /projects/draft (design legacy + short title/desc) | PASS | 200 | 0 |
| 92 | 6.3c GET /projects/:id (draft before publish) | PASS | 200 | 0 |
| 93 | 6.3c assert draft normalized | PASS | 200 | 0 |
| 94 | 6.3d POST /projects/:id/publish | PASS | 200 | 0 |
| 95 | 6.3e GET /projects/:id (after publish) | PASS | 200 | 0 |
| 96 | 6.3e assert publish title/desc/category | PASS | 200 | 0 |
| 97 | 6.4 GET /projects/:id/prd | PASS | 200 | 0 |
| 98 | 6.5 PUT /projects/:id/prd/cards/:cardId | PASS | 200 | 0 |
| 99 | 7.0a sms-code (user2) | PASS | 200 | 0 |
| 100 | 7.0b login (user2) | PASS | 200 | 0 |
| 101 | 7.1 POST /projects/:id/bids (create bid) | PASS | 200 | 0 |
| 102 | 7.1a1 my_bid_status pending | PASS | 200 | 0 |
| 103 | 7.1a2 my_bid_status absent for owner | PASS | 200 | 0 |
| 104 | 7.1b demander new_bid notification (type=23) | PASS | 200 | 0 |
| 105 | 7.1c POST /bids (non-member team -> 30007) | PASS | 400 | 30007 |
| 106 | 7.2 GET /projects/:id/bids (list bids) | PASS | 200 | 0 |
| 107 | 7.2b0 POST /projects (withdraw flow project) | PASS | 200 | 0 |
| 108 | 7.2b1 POST /projects/:id/bids (withdraw test) | PASS | 200 | 0 |
| 109 | 7.2b2 withdraw pending bid | PASS | 200 | 0 |
| 110 | 7.2b3 bid_count after withdraw | PASS | 200 | 0 |
| 111 | 7.2b4 withdraw idempotent closed | PASS | 400 | 30003 |
| 112 | 7.2b5 my_bid_status withdrawn | PASS | 200 | 0 |
| 113 | 7.3 GET /projects/:id/ai-suggestion | PASS | 200 | 0 |
| 114 | 7.4 POST /bids/:id/accept | PASS | 200 | 0 |
| 115 | 7.4a1 my_bid_status accepted | PASS | 200 | 0 |
| 116 | 7.4b demander match_success notification | PASS | 200 | 0 |
| 117 | 7.4c expert match_success notification | PASS | 200 | 0 |
| 118 | 7.4d conversations system message | PASS | 200 | 0 |
| 119 | 7.4d1 conversations list meta | PASS | 200 | 0 |
| 120 | 7.4e expert sees match conversation | PASS | 200 | 0 |
| 121 | 7.4f conversation messages system | PASS | 200 | 0 |
| 122 | 7.4g accept bid idempotent | PASS | 200 | 0 |
| 123 | 7.4w withdraw accepted bid forbidden | PASS | 400 | 30003 |
| 124 | 7.4h order detail after accept | PASS | 200 | 0 |
| 125 | 7.4i pay reminder notification | PASS | 200 | 0 |
| 126 | 7.4j POST /orders (duplicate pending -> 40013) | PASS | 400 | 40013 |
| 127 | 8.1 GET /projects/:id/tasks | PASS | 200 | 0 |
| 128 | 8.2 POST /projects/:id/milestones (create) | PASS | 200 | 0 |
| 129 | 8.2b POST /projects/:id/milestones (payment_ratio sum>100% -> 21007) | PASS | 400 | 21007 |
| 130 | 8.2c POST /projects/:id/milestones (project not found -> 20001) | PASS | 404 | 20001 |
| 131 | 8.2d POST /projects/:id/tasks (create manual) | PASS | 200 | 0 |
| 132 | 8.2d2 create task milestone_id is UUID | PASS | 200 | 0 |
| 133 | 8.2e GET tasks list contains created | PASS | 200 | 0 |
| 134 | 8.2f0 POST /auth/sms-code (user3 outsider) | PASS | 200 | 0 |
| 135 | 8.2f1 POST /auth/login (user3) | PASS | 200 | 0 |
| 136 | 8.2f assignee outsider -> 21011 | PASS | 400 | 21011 |
| 137 | 8.3 GET milestones list contains created | PASS | 200 | 0 |
| 138 | 8.3dp POST /milestones/:id/deliver (pending -> 21014) | PASS | 400 | 21014 |
| 139 | 8.3d0 POST /milestones/:id/deliver (empty note+url -> 99001) | PASS | 400 | 99001 |
| 140 | 8.3d1 POST /milestones/:id/deliver (demander -> 21013) | PASS | 403 | 21013 |
| 141 | 8.3d2 POST /milestones/:id/deliver (provider success) | PASS | 200 | 0 |
| 142 | 8.3d2 deliver response status=delivered | PASS | 200 | 0 |
| 143 | 8.3e POST /milestones/:id/accept (expert -> 20009 仅需求方) | PASS | 403 | 20009 |
| 144 | 8.3f POST /milestones/:id/revision (expert -> 20009 仅需求方) | PASS | 403 | 20009 |
| 145 | 8.3d3 demander notification type=22 deliver | PASS | 200 | 0 |
| 146 | 8.3d4 milestone list status delivered | PASS | 200 | 0 |
| 147 | 8.3d5 POST /milestones/:id/deliver (duplicate -> 21009) | PASS | 400 | 21009 |
| 148 | 8.4 GET /projects/:id/daily-reports | PASS | 200 | 0 |
| 149 | 8.5a GET project files list (demander) | PASS | 200 | 0 |
| 150 | 8.5b POST project file reference | PASS | 200 | 0 |
| 151 | 8.5c GET project files list has ref | PASS | 200 | 0 |
| 152 | 8.5d GET project file detail | PASS | 200 | 0 |
| 153 | 8.5e GET project files filter file_kind | PASS | 200 | 0 |
| 154 | 8.5f POST project file provider | PASS | 200 | 0 |
| 155 | 8.5g POST project file milestone | PASS | 200 | 0 |
| 156 | 8.5g1 GET project files filter milestone | PASS | 200 | 0 |
| 157 | 8.5h POST project file bad kind | PASS | 400 | 21016 |
| 158 | 8.5i GET /projects/:id/files/:uuid (not found -> 21015) | PASS | 404 | 21015 |
| 159 | 8.5j GET /projects/:id/files (outsider -> 21008) | PASS | 403 | 21008 |
| 160 | 9.1 GET /conversations (list) | PASS | 200 | 0 |
| 161 | 9.1b conversations meta | PASS | 200 | 0 |
| 162 | 9.1c GET /conversations?offset=0&limit=5 | PASS | 200 | 0 |
| 163 | 9.2 expert send message | PASS | 200 | 0 |
| 164 | 9.3a demander unread after expert msg | PASS | 200 | 0 |
| 165 | 9.3b demander mark read | PASS | 200 | 0 |
| 166 | 9.3c demander unread after read | PASS | 200 | 0 |
| 167 | 9.4a GET /conversations/:uuid/messages outsider -> 403/60002 | PASS | 403 | 60002 |
| 168 | 9.4b POST /conversations/:uuid/messages outsider -> 403/60002 | PASS | 403 | 60002 |
| 169 | 9.5 GET /conversations/:uuid/messages (unknown uuid -> 404/60001) | PASS | 404 | 60001 |
| 170 | 9.6a conversation delete | PASS | 200 | 0 |
| 171 | 9.6b messages after delete demander | PASS | 404 | 60001 |
| 172 | 9.6c messages after delete expert | PASS | 404 | 60001 |
| 173 | 10.1 GET /coupons | PASS | 200 | 0 |
| 174 | 11.1 GET /wallet/balance | PASS | 200 | 0 |
| 175 | 11.2 GET /wallet/transactions | PASS | 200 | 0 |
| 176 | 11b.1 GET /notifications/unread-count | PASS | 200 | 0 |
| 177 | 11b.2 GET /notifications paged+seeds | PASS | 200 | 0 |
| 178 | 11b.3 GET /notifications?type=1 | PASS | 200 | 0 |
| 179 | 11b.4 PUT /notifications/:uuid/read (A) | PASS | 200 | 0 |
| 180 | 11b.5 unread_count after mark one read | PASS | 200 | 0 |
| 181 | 11b.6 PUT /notifications/read-all | PASS | 200 | 0 |
| 182 | 11b.7 unread_count after read-all | PASS | 200 | 0 |
| 183 | 11b.8 PUT /notifications/:uuid/read (idempotent) | PASS | 200 | 0 |
| 184 | 11b.8 mark read idempotent | PASS | 200 | 0 |
| 185 | 12a.1 POST /teams (invalid budget -> 20005) | PASS | 400 | 20005 |
| 186 | 12a.2 POST /teams (no invite_code) | PASS | 200 | 0 |
| 187 | 12a.3 POST /teams (duplicate -> 11021) | PASS | 400 | 11021 |
| 188 | 12a.4a POST /auth/sms-code (new user for invite team) | PASS | 200 | 0 |
| 189 | 12a.4b POST /auth/login (new user) | PASS | 200 | 0 |
| 190 | 12a.4c POST /teams (with invite_code -> approved) | PASS | 200 | 0 |
| 191 | 12a.4d sms-code for 2nd user | PASS | 200 | 0 |
| 192 | 12a.4e login 2nd user | PASS | 200 | 0 |
| 193 | 12a.4f POST /teams (reuse consumed invite_code -> 10013/10014) | PASS | 400 | 10014 |
| 194 | 12a.5a PUT /admin/teams/:uuid/approval (approve) | PASS | 200 | 0 |
| 195 | 12.1 GET /teams (list) | PASS | 200 | 0 |
| 196 | 12.2 POST /team-posts (create) | PASS | 200 | 0 |
| 197 | 12b.1 GET /teams/:uuid (detail) | PASS | 200 | 0 |
| 198 | 12b.1a team detail base fields | PASS | 200 | 0 |
| 199 | 12b.1b team detail biz fields | PASS | 200 | 0 |
| 200 | 12b.1c team detail leader fields | PASS | 200 | 0 |
| 201 | 12b.1d skills is array | PASS | 200 | 0 |
| 202 | 12b.1e members structure | PASS | 200 | 0 |
| 203 | 12b.1f optional fields present | PASS | 200 | 0 |
| 204 | 13.1 GET /projects/:id/reviews (list) | PASS | 200 | 0 |
| 205 | 14.1 POST /auth/logout | PASS | 200 | 0 |
| 206 | 14.2 GET /users/me (no token) | PASS | 401 | 10008 |
| 207 | 14.3 PUT /projects/:id/close (matched project) | PASS | 400 | 20002 |
| 208 | 15.1 POST /admin/invite-codes (batch=3) | PASS | 200 | 0 |
| 209 | 15.1a batch invite count=3 | PASS | 200 | 0 |
| 210 | 15.2a sms-code | PASS | 200 | 0 |
| 211 | 15.2b POST /auth/login (new expert) | PASS | 200 | 0 |
| 212 | 15.2c POST /teams (with invite_code -> approved) | PASS | 200 | 0 |
| 213 | 15.3a sms-code | PASS | 200 | 0 |
| 214 | 15.3b login | PASS | 200 | 0 |
| 215 | 15.3c POST /teams (reuse consumed code -> 10014) | PASS | 400 | 10014 |
| 216 | 15.4a POST /teams (no invite_code -> pending) | PASS | 200 | 0 |
| 217 | 15.4b PUT /admin/teams/:uuid/approval (approve) | PASS | 200 | 0 |
| 218 | 15.4c sms-code | PASS | 200 | 0 |
| 219 | 15.4d login | PASS | 200 | 0 |
| 220 | 15.4e POST /teams (no invite_code, for reject test) | PASS | 200 | 0 |
| 221 | 15.4f PUT /admin/teams/:uuid/approval (reject) | PASS | 200 | 0 |
| 222 | 15.5 GET /admin/invite-codes (verify consumed) | PASS | 200 | 0 |

---
*Generated at 2026-04-08T22:45:28.693939*
