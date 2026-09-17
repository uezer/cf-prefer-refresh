# 优选刷新 · CF Prefer Refresh

在**当前这台设备、此刻这条网络**上测试 Cloudflare 入口 IP（优选 IP），再把名单上传到 edgetunnel 会读取的地址。Clash / mihomo 始终订阅**同一条** Cloudflare 订阅，例如：

`https://edgetunnel-xxxx.pages.dev/sub?token=...`

本应用**不会**把 Clash 改成 `http://127.0.0.1/sub`。本地 `/sub` 只是可选调试开关。

一套 Flutter 代码同时打出 **Linux 桌面、Windows 桌面、Android**。浏览器预览只能看界面：原始 TCP/TLS 探测需要桌面或 Android 客户端。

## 为什么必须本机测、订阅还走 Cloudflare

家里 Wi‑Fi、公司网络、手机流量看到的 Cloudflare 任播入口不同。NAS 上算好再推到 GitHub 的名单，描述的是 **NAS 的路径**，不是你手机或电脑此刻的路径。

edgetunnel / CF Workers-Pages 的职责是：读取一份「优选入口 IP」列表，再用你的 host / UUID / path **在边缘生成节点**。Clash 更新订阅只是把这份已经生成好的配置拉下来，**不会触发测速**。

所以正确闭环是：

```
本机点「刷新」
  → 当场测入口 IP
  → 覆盖上传 addressesapi.txt（或 csv / 自定义 URL）
  → edgetunnel 的 ADDAPI / 优选订阅指向这份列表
  → Clash 仍更新原来的 CF /sub
  → 节点 server 变成刚测出的具体 IP
```

多台设备往同一份列表上传会互相覆盖。只用一台「发布者」在常用网络上刷新，其它设备设为「仅订阅」。

## 快速使用

1. 安装并打开应用（见下方各系统编译）。
2. **设置 → 角色**选「发布者」。
3. 填入你平时给 Clash 用的 **Cloudflare 订阅 URL**（只用于展示/复制，应用不会改它）。
4. 配置上传目标（推荐 GitHub 仓库 + Token）。
5. 按需改并发、超时、Top N、IP 来源。默认会拉 `https://www.cloudflare.com/ips-v4` 并抽样。
6. 回首页点 **刷新 / Refresh**：从这一刻开始测速并上传。
7. 到 Clash 里对**原来那条 CF 订阅**点「更新订阅」。

节点模板（UUID、SNI、path）只用于可选的本地 YAML 导出。日常节点仍由 edgetunnel 生成，不必把真实密钥写进仓库。仓库里的 `settings.example.json` 只有占位符。

## 把列表接到 edgetunnel

上传成功后，首页会给出优选列表 URL。把它交给 edgetunnel，而不是交给 Clash。

### ADDAPI（最常见）

在 Pages / Worker 环境变量或管理后台设置：

- `ADDAPI` = `https://raw.githubusercontent.com/<user>/<repo>/<branch>/addressesapi.txt`

文件内容由本应用写入，一行一条：

```
1.1.1.1:443#Home-12ms-SJC
1.0.0.1:443#Home-18ms
```

### ADDCSV

若你的转换脚本读 csv，把格式改成 `addressescsv.csv` 或「两种都写」，并把 `ADDCSV` 指到该 raw URL。表头与 cmliu 系 iptest 导出兼容：

`IP地址,端口,回源端口,TLS,数据中心,地区,城市,TCP延迟(ms),速度(MB/s)`

### edgetunnel 2.x 管理面板

较新的面板把优选 API / IP 写在「优选订阅」或 `ADD.txt` 里。可以：

- 把上面的 GitHub raw URL 贴进 ADD.txt；或
- 用「自定义 HTTP 上传」把 `IP:端口#备注` 正文 `POST`/`PUT` 到你的管理接口（需你自己提供 URL 与鉴权头）。

GitHub raw 有短暂缓存，上传后等一会儿再让 Clash 更新。

Token 权限：仓库用 `repo`（私有）或 `public_repo`；Gist 用 `gist`。Token 只存在本机应用目录，无遥测、无外发统计。

## 测速实现

1. 下载候选列表（URL + 本地粘贴 + 内置少量回退 IP）。
2. 解析 `IP`、`IP:端口#备注`、IPv4 CIDR（按段抽样，避免把整个 Cloudflare 地址空间扫完）。
3. 并发 TCP 连接；默认对 `speed.cloudflare.com` 做 TLS（允许任播证书）并请求 `/cdn-cgi/trace` 记延迟与 colo。
4. 可选：对延迟最好的一批再拉 `/__down?bytes=…` 估下载速度。
5. 按延迟、其次速度排序，保留 Top N，再上传。

库：Dart `dart:io` `Socket` / `SecureSocket`（并发探测），`package:http`（拉列表与 GitHub API）。没有把探测放到 Cloudflare 或你的 VPS 上。

## 编译与运行

需要 [Flutter stable](https://docs.flutter.dev/get-started/install)（开发时为 3.47 / Dart 3.13）。

```bash
git clone <this-repo>
cd cf_prefer_refresh
flutter pub get
flutter test
```

### Linux 桌面

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev g++ libstdc++-14-dev
flutter config --enable-linux-desktop
flutter run -d linux
flutter build linux --release
# 产物：build/linux/x64/release/bundle/
```

### Windows 桌面

在 Windows 上安装 Flutter 与 Visual Studio「使用 C++ 的桌面开发」：

```bat
flutter config --enable-windows-desktop
flutter run -d windows
flutter build windows --release
rem 产物：build\windows\x64\runner\Release\
```

### Android

安装 Android Studio / SDK / 一个 NDK（Flutter 会提示）。`AndroidManifest` 已声明 `INTERNET`。

```bash
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release
```

真机调试：`flutter run -d <deviceId>`。首次测速请允许联网。应用在前台时可选本地调试 `/sub`；日常请继续用 CF 订阅。

### 浏览器预览（仅 UI）

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 47810
```

Web 无法做原始套接字探测，也不能可靠调用 GitHub API（浏览器 CORS）。测速和上传请用桌面或 Android 包。

## 手动验收清单

1. 设置里填 GitHub（或自定义上传）与 CF 订阅 URL，角色为发布者。
2. 点刷新：进度显示 `延迟探测 n/m` 与当前最优 IP。
3. 中途可取消；完成或取消后结果仍在首页。
4. 打开上传后的 raw 文件，确认是刚测的 `IP:端口#备注`。
5. edgetunnel ADDAPI 指向该 raw URL。
6. Clash（Verge / FlClash / mihomo-party / CMA）添加**原来的** `https://…pages.dev/sub?…`，更新订阅。
7. 节点 `server` 为具体优选 IP，`servername` / SNI 仍是你的 pages/worker 域名。
8. 另开「仅订阅」角色：刷新不会上传。

## 仓库结构

```
lib/           应用、测速、上传、中文 UI
test/          排序 / 列表 / 优选文本 / Clash YAML / 导入
assets/        远端列表失败时的少量公共 anycast 回退
.github/       Linux + Windows + Android CI
settings.example.json
```

无账号系统、无云端后台、无统计分析。

## 免责说明

本项目用于个人在当前网络上测试到 Cloudflare 任播入口的延迟与可用性，并更新你自己控制的优选列表。请自行遵守 Cloudflare 服务条款与当地法律。

## 许可

MIT。见 [LICENSE](LICENSE)。
