# GitHub Actions Secrets 配置指南

本文档指导你为 Flutter 项目的 iOS / Android 自动构建配置所需的 GitHub Secrets。

**预计耗时**：Android 约 5 分钟，iOS 约 15 分钟

---

## 一、Android Secrets 配置（共 4 个）

### 第 1 步：生成 keystore 的 base64 编码

打开终端，运行：

```bash
cd /Users/zhangheng/Documents/WorkSpace/kaizao/app/android
base64 -i my-release-key.jks | pbcopy
```

> 运行后 base64 字符串已自动复制到剪贴板（不会有输出）。

### 第 2 步：在 GitHub 仓库添加 Secrets

1. 打开浏览器，进入仓库页面：
   `https://github.com/kaizao-team/kaizao/settings/secrets/actions`

2. 点击右上角绿色按钮 **「New repository secret」**

3. **逐个添加以下 4 个 Secret**（每添加一个，点 Add secret，然后再点 New repository secret 添加下一个）：

---

#### Secret 1：ANDROID_KEYSTORE_BASE64

| 字段 | 填什么 |
|------|--------|
| **Name** | `ANDROID_KEYSTORE_BASE64` |
| **Secret** | 粘贴第 1 步复制的 base64 字符串（Cmd+V） |

点击 **Add secret**

---

#### Secret 2：ANDROID_KEYSTORE_PASSWORD

| 字段 | 填什么 |
|------|--------|
| **Name** | `ANDROID_KEYSTORE_PASSWORD` |
| **Secret** | `kaizao` |

点击 **Add secret**

---

#### Secret 3：ANDROID_KEY_PASSWORD

| 字段 | 填什么 |
|------|--------|
| **Name** | `ANDROID_KEY_PASSWORD` |
| **Secret** | `kaizao` |

点击 **Add secret**

---

#### Secret 4：ANDROID_KEY_ALIAS

| 字段 | 填什么 |
|------|--------|
| **Name** | `ANDROID_KEY_ALIAS` |
| **Secret** | `my-key-alias` |

点击 **Add secret**

---

#### 验证 Android Secrets

添加完 4 个后，页面上应该能看到：

```
ANDROID_KEY_ALIAS          Updated just now
ANDROID_KEY_PASSWORD       Updated just now
ANDROID_KEYSTORE_BASE64    Updated just now
ANDROID_KEYSTORE_PASSWORD  Updated just now
```

**Android 部分完成！**

---

## 二、iOS Secrets 配置（共 5 个）

iOS 签名比 Android 复杂一些，需要从 Apple 开发者后台导出证书和描述文件。

### 第 1 步：找到你的 Team ID

1. 打开 https://developer.apple.com/account
2. 登录后，页面左侧菜单点击 **「Membership details」**
3. 找到 **「Team ID」**，复制（格式类似 `ULXGNR9Y2S`）

> 你项目中的 Team ID 是 `ULXGNR9Y2S`，确认是否和你 Apple Developer 后台一致。

### 第 2 步：导出分发证书（.p12 文件）

**方法 A：从 Mac 钥匙串导出（推荐）**

1. 打开 **钥匙串访问**（Spotlight 搜索 "Keychain Access"）
2. 左侧选择 **「登录」** → 上方选择 **「我的证书」** 标签
3. 找到你的 Apple Distribution 证书（名称类似 `Apple Distribution: xxx (ULXGNR9Y2S)`）
4. 右键点击证书 → **「导出...」**
5. 格式选择 **「.p12」**
6. 保存到桌面，文件名随意（例如 `kaizao-dist.p12`）
7. 设置一个密码（**记住这个密码**，后面要用）

**方法 B：如果你没有分发证书**

1. 打开 Xcode → 菜单栏 **Xcode → Settings → Accounts**
2. 选择你的 Apple ID → 点击你的 Team
3. 点击 **「Manage Certificates」**
4. 点击左下角 **「+」** → 选择 **「Apple Distribution」**
5. 创建后回到钥匙串按方法 A 导出

### 第 3 步：生成证书的 base64 编码

```bash
# 把下面的路径替换成你实际的 .p12 文件路径
base64 -i ~/Desktop/kaizao-dist.p12 | pbcopy
```

> 运行后 base64 字符串已自动复制到剪贴板。

### 第 4 步：创建 Provisioning Profile

1. 打开 https://developer.apple.com/account/resources/profiles/list
2. 点击 **「+」** 创建新的 Profile
3. 选择类型：
   - 测试分发选 **「Ad Hoc」**
   - 上架选 **「App Store Connect」**
4. 选择 App ID：找到 `cc.kaizao`
5. 选择证书：选择你刚才的 Distribution 证书
6. 选择设备（Ad Hoc 才需要）：勾选测试设备
7. 给 Profile 取名，例如 `kaizao-adhoc`（**记住这个名字**）
8. 点击 **「Generate」** → **「Download」**
9. 下载的文件类似 `kaizao_adhoc.mobileprovision`

### 第 5 步：生成 Profile 的 base64 编码

```bash
# 把路径替换成你实际下载的 .mobileprovision 文件路径
base64 -i ~/Downloads/kaizao_adhoc.mobileprovision | pbcopy
```

### 第 6 步：在 GitHub 添加 iOS Secrets

回到 `https://github.com/kaizao-team/kaizao/settings/secrets/actions`

逐个添加以下 5 个 Secret：

---

#### Secret 1：IOS_P12_BASE64

| 字段 | 填什么 |
|------|--------|
| **Name** | `IOS_P12_BASE64` |
| **Secret** | 粘贴第 3 步复制的 .p12 base64 字符串 |

---

#### Secret 2：IOS_P12_PASSWORD

| 字段 | 填什么 |
|------|--------|
| **Name** | `IOS_P12_PASSWORD` |
| **Secret** | 你导出 .p12 时设置的密码 |

---

#### Secret 3：IOS_PROVISION_PROFILE_BASE64

| 字段 | 填什么 |
|------|--------|
| **Name** | `IOS_PROVISION_PROFILE_BASE64` |
| **Secret** | 粘贴第 5 步复制的 .mobileprovision base64 字符串 |

---

#### Secret 4：IOS_TEAM_ID

| 字段 | 填什么 |
|------|--------|
| **Name** | `IOS_TEAM_ID` |
| **Secret** | `ULXGNR9Y2S`（或你实际的 Team ID） |

---

#### Secret 5：IOS_PROVISION_PROFILE_NAME

| 字段 | 填什么 |
|------|--------|
| **Name** | `IOS_PROVISION_PROFILE_NAME` |
| **Secret** | 你在第 4 步给 Profile 取的名字，例如 `kaizao-adhoc` |

---

#### 验证 iOS Secrets

添加完 5 个后，页面上应该能看到：

```
IOS_P12_BASE64                Updated just now
IOS_P12_PASSWORD              Updated just now
IOS_PROVISION_PROFILE_BASE64  Updated just now
IOS_PROVISION_PROFILE_NAME    Updated just now
IOS_TEAM_ID                   Updated just now
```

**iOS 部分完成！**

---

## 三、验证构建是否正常

### 手动触发测试

1. 打开 https://github.com/kaizao-team/kaizao/actions
2. 左侧选择 **「Build Android」** 或 **「Build iOS」**
3. 点击右侧 **「Run workflow」** 按钮
4. 选择分支（先选 `ci/flutter-build-ios-android` 测试，正式后用 `main`）
5. 选择构建模式（先用 debug 测试）
6. 点击绿色 **「Run workflow」**

### 查看构建结果

- 构建成功：绿色 ✅
- 构建失败：红色 ❌，点击进去查看日志
- 构建产物：在构建详情页底部的 **「Artifacts」** 区域下载 APK/IPA

---

## 四、常见问题

### Q: Android 构建报 "keystore not found"
检查 `ANDROID_KEYSTORE_BASE64` 是否正确生成。重新运行：
```bash
base64 -i app/android/my-release-key.jks | pbcopy
```
粘贴到 Secret 中（覆盖旧值）。

### Q: iOS 构建报 "no signing certificate"
检查 P12 证书是否过期。打开钥匙串访问查看证书有效期。

### Q: iOS 构建报 "provisioning profile does not match"
确保 Provisioning Profile 的 Bundle ID 是 `cc.kaizao`，且关联了正确的分发证书。

### Q: 构建报 "Flutter version not found"
workflow 文件中写死了 `FLUTTER_VERSION: "3.41.5"`。如果需要升级，修改 `.github/workflows/build-android.yml` 和 `.github/workflows/build-ios.yml` 顶部的 `FLUTTER_VERSION` 值。

### Q: PR 构建失败但不是签名问题
PR 构建不使用签名（Android 走 debug 签名，iOS 走 --no-codesign）。如果 PR 构建失败，说明是代码本身编译问题，需要先修代码。

---

## 五、安全提醒

- **Secrets 只存在 GitHub 仓库设置中**，不会出现在日志里
- **绝对不要**把 `.p12`、`.jks`、`key.properties` 提交到 Git 仓库
- 如果密码泄露，立即在 GitHub Settings 中更新 Secrets，并在 Apple Developer / Google Play 重新生成证书
