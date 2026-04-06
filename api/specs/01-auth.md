## 1. 认证模块

### 1.1 发送短信验证码
- **POST** `/api/v1/auth/sms-code`
- **Body**: `{ "phone": "13800138000", "purpose": 2 }`
- **Response**: `{ "code": 0, "message": "验证码已发送" }`
- **说明**: `purpose` 取值 `1` 注册、`2` 登录、`3` 其他业务（如绑定手机，与产品约定一致）

### 1.2 手机号登录/注册
- **POST** `/api/v1/auth/login`
- **Body**: `{ "phone": "13800138000", "code": "123456", "device_type": "web", "device_id": "可选" }`（`code` 须 6 位；`device_type` 可选 `android` \| `ios` \| `web`）
- **Response**:
```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "access_token": "string",
    "refresh_token": "string",
    "user_id": "string",
    "role": 0,
    "is_new_user": true
  }
}
```
- **说明**: role=0 未选角色, role=1 需求方, role=2 专家; is_new_user=true 时前端进入引导流程

### 1.3 刷新 Token
- **POST** `/api/v1/auth/refresh`
- **Body**: `{ "refresh_token": "string" }`
- **Response**: `{ "data": { "access_token": "string", "refresh_token": "string", "expires_in": 3600 } }`

### 1.4 退出登录
- **POST** `/api/v1/auth/logout`
- **Headers**: 需认证
- **Response**: `{ "code": 0 }`

### 1.5 手机号注册（独立）
- **POST** `/api/v1/auth/register`
- **Body**: `{ "phone": "13800138000", "sms_code": "123456", "nickname": "昵称", "role": 2, "invite_code": "可选" }`
- **Response**（`data` 为 `AuthResp`）:
```json
{
  "code": 0,
  "data": {
    "user": {
      "uuid": "string",
      "nickname": "string",
      "avatar_url": null,
      "role": 1,
      "level": 1,
      "credit_score": 500,
      "is_verified": false
    },
    "access_token": "string",
    "refresh_token": "string",
    "expires_in": 3600
  }
}
```
- **说明**:
  - **邀请码不参与注册**；专家 `role=2/3` 注册成功后默认 `onboarding_status=1`（待入驻），但仍**正常返回** `access_token` / `refresh_token`，可登录后提交材料或兑换团队邀请码。
  - 需求方等非专家角色默认 `onboarding_status=2`（已通过）。
  - 专家完成入驻前**不会出现在**首页推荐专家、`GET /market/experts` 等列表（仅展示 `onboarding_status=2` 的专家）。

### 1.6 登录/注册策略（服务端配置）
- **配置文件** `registration`：仅 `disable_auto_register` 仍影响 **1.2 登录**（未注册且禁止静默注册时返回 `10017`）。`require_invite_roles` / `require_approval_roles` 已不再作用于注册接口。
- **环境变量**：`VB_REGISTRATION_DISABLE_AUTO_REGISTER`。
- **POST** `/api/v1/auth/login`：待审/已拒绝入驻**不拦截**登录；专家需通过材料审核或团队邀请码直通后才会上首页。
- **入驻状态** `onboarding_status`：`1` 待审核，`2` 已通过，`3` 已拒绝。`GET /api/v1/users/me` 含 `onboarding_status`、`onboarding_submitted_at`、`resume_url`、`onboarding_application_note`（若有）。
- **集成测试**：`api/test_api_v2.py` **1.5** 节为团队 `11111111-1111-1111-1111-111111111111`（迁移 003 种子）发码；`--full-onboarding` 跑「专家注册 → 兑换邀请码 → 新码轮换」。

### 1.7 获取密码加密公钥
- **GET** `/api/v1/auth/password-key`
- **Response `data`**：`key_id`、`algorithm`（`RSA-OAEP-SHA256`）、`public_key_pem`（PKCS#1 PEM）
- **说明**：客户端用公钥对 UTF-8 密码做 RSA-OAEP（SHA-256），密文 Base64 后作为 `password_cipher`。**禁止**在 JSON 根级传明文 `password`（业务码 `10023`）。细节与错误码见 `api/api-registry.md`。

### 1.8 图形验证码
- **GET** `/api/v1/auth/captcha`
- **Response `data`**：`captcha_id`、`image_base64`（PNG，无 `data:` 前缀）、`expires_in`（秒）

### 1.9 用户名密码注册
- **POST** `/api/v1/auth/register-password`
- **Body**：`username`（4–32，`a-zA-Z0-9_`）、`password_cipher`、`nickname`（可选）、`role`（0–3）、`phone`（可选，绑定手机，**无需**短信验证码）、`sms_code`（可选，服务端不校验）、`invite_code`（可选）
- **成功**：与 **1.5** 相同结构（`user`、`access_token`、`refresh_token`、`expires_in`）

### 1.10 用户名密码登录
- **POST** `/api/v1/auth/login-password`
- **Body**：`login_type`（`username`|`phone`）、`identity`、`password_cipher`、`captcha_id`、`captcha_code`、`device_type`（可选）
- **成功**（`SuccessMsg`，`data` 示例）：
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "user_id": "用户UUID",
  "role": 1,
  "is_new_user": false
}
```

### 1.11 微信登录
- **POST** `/api/v1/auth/wechat`
- **Body**：`code`（微信授权码，必填）、`device_type`（可选 `android`|`ios`|`web`）
- **说明**：当前实现多为占位（如返回 `message: wechat login endpoint ready`）；正式联调前请以当时服务端响应为准。

---
