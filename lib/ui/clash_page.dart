import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_controller.dart';
import 'widgets/copy_row.dart';
import 'widgets/section_card.dart';

class ClashPage extends StatelessWidget {
  const ClashPage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final url = controller.settings.edgetunnelSubUrl;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        SectionCard(
          title: 'Clash 怎么用',
          subtitle: '所有客户端只订阅这一条 Cloudflare edgetunnel URL。应用负责测速并更新优选 IP 列表；Clash 只负责拉取。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CopyRow(label: '固定订阅 URL', value: url),
              const SizedBox(height: 8),
              const Text(
                '刷新应用之后：到 Clash 里点「更新订阅」。节点的 server 字段应变成刚刚测出的入口 IP，而不是 pages.dev 域名本身。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '各客户端',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClientBlock(
                name: 'Clash Verge / Clash Verge Rev',
                steps:
                    '订阅 → 新建 → 远程。URL 粘贴上面的 CF 订阅。名称随意。保存后，每次本应用刷新完毕，回到 Verge 点该订阅的「更新」。',
              ),
              _ClientBlock(
                name: 'FlClash',
                steps:
                    '配置 → 添加订阅 → 粘贴 CF URL。Android 上也可试探 clash:// 或 flclash:// 导入（取决于客户端版本）。',
              ),
              _ClientBlock(
                name: 'mihomo-party',
                steps: 'Profiles → Import From URL → 粘贴 CF 订阅。更新资料即可拿到新入口 IP。',
              ),
              _ClientBlock(
                name: 'Clash Meta for Android',
                steps:
                    '新建 → URL 导入。部分版本支持 clash://install-config?url= 深链。导入后点更新配置。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '一键复制 / 尝试打开客户端',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: url.isEmpty
                    ? null
                    : () => Clipboard.setData(ClipboardData(text: url)),
                child: const Text('复制订阅 URL'),
              ),
              OutlinedButton(
                onPressed: url.isEmpty ? null : () => _tryOpen('clash://install-config?url=${Uri.encodeComponent(url)}'),
                child: const Text('尝试 clash://'),
              ),
              OutlinedButton(
                onPressed: url.isEmpty
                    ? null
                    : () => _tryOpen('flclash://install-config?url=${Uri.encodeComponent(url)}'),
                child: const Text('尝试 flclash://'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '桌面：可选写入本地 Clash 文件',
          subtitle: '只有你明确指定了配置文件路径才会写盘。这不会假装“自动接管”所有 Clash 客户端。主路径仍然是远程 CF 订阅。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(controller.settings.localClashProfilePath.isEmpty
                  ? '未设置路径（去设置页填写）'
                  : controller.settings.localClashProfilePath),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  try {
                    final path = await controller.writeClashProfile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已写入 $path')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                child: const Text('把最近测速结果写成 Clash YAML'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '调试导出（可选）',
          subtitle: '本地 /sub 不是给日常 Clash 用的。默认关闭。打开后仅便于核对节点模板。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.settings.enableLocalSubServer
                    ? (controller.server.bindHint.isEmpty
                        ? '已开启，但当前平台未绑定端口'
                        : '调试地址 ${controller.server.bindHint}')
                    : '本地调试订阅未开启',
              ),
              const SizedBox(height: 8),
              SelectableText(
                controller.addApiText().isEmpty ? '还没有 addressesapi 文本' : controller.addApiText(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClientBlock extends StatelessWidget {
  const _ClientBlock({required this.name, required this.steps});
  final String name;
  final String steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(steps, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

Future<void> _tryOpen(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
