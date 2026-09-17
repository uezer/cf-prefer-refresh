import 'package:flutter/material.dart';

import 'widgets/section_card.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: const [
        SectionCard(
          title: '为什么订阅必须继续走 Cloudflare',
          subtitle:
              'edgetunnel / Workers-Pages 根据「优选 IP 列表」现场拼节点。Clash 拉取的是 https://你的项目.pages.dev/sub?…。'
              '如果改成订阅本机 127.0.0.1，手机上的 Clash、另一台电脑上的 Clash 都拿不到这次家里网络测出来的入口 IP，'
              '而且测速被错误地理解成“订阅服务器去测”。正确顺序：本应用在当前设备网络测速 → 把名单推到 GitHub raw / 自定义 URL → '
              '把该 URL 填进 edgetunnel 管理里的 优选/ADDAPI → Clash 仍更新原来的 CF 订阅。',
          child: SizedBox.shrink(),
        ),
        SizedBox(height: 12),
        SectionCard(
          title: '把列表接到 edgetunnel',
          subtitle:
              '1) 发布者：GitHub 仓库放 addressesapi.txt（每行 IP:端口#备注），或 ADDCSV 的 csv。\n'
              '2) 在 edgetunnel / Pages 后台把 ADDAPI 指到 '
              'https://raw.githubusercontent.com/<user>/<repo>/<branch>/addressesapi.txt\n'
              '3) 较新的 2.x 管理面板也可以把该 raw URL 写进「优选订阅 / ADD.txt」。\n'
              '4) 不要把 Clash 订阅改成 raw 文件本身；Clash 只要 CF 的 /sub。\n'
              '5) GitHub raw 可能有短暂缓存，上传后等几十秒再在 Clash 更新。',
          child: SizedBox.shrink(),
        ),
        SizedBox(height: 12),
        SectionCard(
          title: '角色',
          subtitle:
              '发布者：点「刷新」会测速并覆盖远程列表。仅订阅：只保存 CF 订阅 URL，避免家里 Wi‑Fi 和手机流量抢着覆盖同一份名单。',
          child: SizedBox.shrink(),
        ),
        SizedBox(height: 12),
        SectionCard(
          title: '免责说明',
          subtitle:
              '本工具用于个人在当前网络上测试到 Cloudflare 任播入口的延迟/可用性，并更新你自己控制的优选列表。'
              '请自行遵守 Cloudflare 服务条款与当地法律。',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}
