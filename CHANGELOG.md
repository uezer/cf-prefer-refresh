# Changelog

## 1.0.0 — 2026-09-17

首个完整版（Flutter，Linux / Windows / Android 同一套代码）。

- **本机当场测速**：点「刷新」后从当前设备网络拉取候选 IP（含 Cloudflare 官方 CIDR 抽样），并发 TCP/TLS（HTTP/1.1 ALPN）+ `/cdn-cgi/trace` 延迟探测，读不到 trace 时回退 80 端口 HTTP；可选对最优一批再测 `speed.cloudflare.com` 下载速度；可取消；结果落盘。
- **上传优选列表，而不是给 Clash 一条本地订阅**：支持 GitHub 仓库文件、Gist、自定义 HTTP PUT/POST/PATCH。写出 edgetunnel 常用的 `IP:端口#备注`（ADDAPI）以及 ADDCSV。
- **Clash 继续用同一条 Cloudflare /sub**：首页复制 URL / 二维码；Clash 页含 Verge、FlClash、mihomo-party、Clash Meta for Android 的操作说明和可选深链。
- **发布者 / 仅订阅**：避免多台设备、不同网络覆盖同一份列表。
- **节点模板**：占位符配置，可从 `vless://` / `trojan://` 或 Clash YAML 导入；仅用于可选本地 YAML 导出。
- **可选本地 `/sub`**：默认关闭，仅调试。桌面可把最近结果写入用户指定的 Clash 文件路径（不会假装自动接管所有客户端）。
- 首页与顶栏用高对比「当前角色：发布者 / 仅订阅」徽章，避免角色只藏在设置里。
- **无遥测**：设置与 Token 只存在本机应用目录。
- **测试与 CI**：排序、列表解析、订阅/优选文本生成的单元测试；Linux + Windows 的 analyze/test/build；Android 提供 APK 构建说明与 CI 任务。
