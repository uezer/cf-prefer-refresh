# edgetunnel 对接（摘要）

完整说明见仓库根目录 [README.md](../README.md)。

Clash 只订阅：

```
https://<your-edgetunnel>.pages.dev/sub?token=...
```

本应用上传的是优选入口列表，例如：

```
https://raw.githubusercontent.com/<user>/<repo>/main/addressesapi.txt
```

把该 raw URL 填进 edgetunnel 的 `ADDAPI` 或 2.x「优选订阅」。不要把 raw 文件当成 Clash 订阅。
