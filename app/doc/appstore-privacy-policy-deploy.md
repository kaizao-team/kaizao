# App Store 隐私政策部署说明

目标：把 [privacy-policy.html](/Users/liangyutao/Documents/个人文件/AI项目撮合平台/vibebuild/app/privacy-policy.html) 发布到你们现有服务器，并让阿里云域名可访问，供 App Store Connect 填写隐私政策网址。

## 推荐最终地址

优先直接用一个稳定、清晰的 URL：

```text
https://你的域名/privacy-policy.html
```

示例：

```text
https://www.vibebuild.com/privacy-policy.html
```

App Store Connect 可以直接填写这个地址，不要求必须是 `/privacy` 这种无后缀路径。

## 现有 Nginx 结构

仓库里已有生产 Nginx 配置，静态文件根目录是：

```nginx
location / {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri $uri/ /index.html;
}
```

这意味着只要把 `privacy-policy.html` 放进 Nginx 容器或服务器的 `/usr/share/nginx/html/` 目录，就能直接通过：

```text
/privacy-policy.html
```

访问到。

## 最短部署方式

### 方式 A：直接上传静态文件

适合现在最赶时间的场景。

1. 把 [privacy-policy.html](/Users/liangyutao/Documents/个人文件/AI项目撮合平台/vibebuild/app/privacy-policy.html) 上传到服务器静态目录：

```text
/usr/share/nginx/html/privacy-policy.html
```

2. 重载 Nginx：

```bash
nginx -s reload
```

3. 浏览器验证：

```text
https://你的域名/privacy-policy.html
```

如果页面能正常打开，就可以直接把这个 URL 填到 App Store Connect。

### 方式 B：随前端静态包一起发布

如果你们当前服务器就是在发 Flutter Web 静态文件，那么也可以把这个文件跟现有静态资源一起部署。

只要最终上线目录里有：

```text
index.html
privacy-policy.html
assets/
flutter.js
...
```

即可，不需要额外改 Nginx。

## 阿里云域名解析

如果域名还没指到当前服务器，去阿里云 DNS 控制台加解析：

### 顶级域名

```text
记录类型: A
主机记录: @
记录值: 你的服务器公网 IP
```

### www 子域名

```text
记录类型: A
主机记录: www
记录值: 你的服务器公网 IP
```

如果你们已经有 Nginx 在这台机器上跑，只要域名解析到同一台服务器，并且证书配置正常，这个静态页就能跟着一起访问。

## HTTPS 要求

建议 App Store 提交时使用 `https://`，不要填 `http://`。

如果你们域名证书已经就绪，只需要确认 Nginx 的 `server_name` 覆盖该域名，并启用了证书配置。

## 发布后检查清单

- 地址能直接打开，不需要登录
- 手机 Safari 能访问
- 返回状态码是 `200`
- 页面不是下载文件，而是正常渲染 HTML
- URL 使用正式域名和 `https://`

## 如果想改成更干净的路径

如果你们一定想用：

```text
https://你的域名/privacy-policy
```

可以在 Nginx 里加一段显式映射：

```nginx
location = /privacy-policy {
    root /usr/share/nginx/html;
    try_files /privacy-policy.html =404;
}
```

但这不是必须项。当前阶段为了尽快过审，直接用 `/privacy-policy.html` 更稳。
