import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';
import '../models/node_template.dart';
import '../state/app_controller.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings draft;
  final _import = TextEditingController();
  int formEpoch = 0;

  @override
  void initState() {
    super.initState();
    draft = widget.controller.settings;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controller.busy) {
      draft = widget.controller.settings;
    }
  }

  @override
  void dispose() {
    _import.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.controller.updateSettings(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存到本地，不会上传到任何分析服务')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        SectionCard(
          title: '角色',
          subtitle: '发布者才会在「刷新」时覆盖远程优选列表。仅订阅用于其它设备，避免不同网络互相覆盖。',
          child: SegmentedButton<AppRole>(
            segments: const [
              ButtonSegment(value: AppRole.publisher, label: Text('发布者'), icon: Icon(Icons.upload_rounded)),
              ButtonSegment(value: AppRole.subscribeOnly, label: Text('仅订阅'), icon: Icon(Icons.download_rounded)),
            ],
            selected: {draft.role},
            onSelectionChanged: (s) => setState(() => draft = draft.copyWith(role: s.first)),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Cloudflare 订阅（Clash 用）',
          child: _field(
            label: 'edgetunnel /sub URL',
            value: draft.edgetunnelSubUrl,
            onChanged: (v) => draft = draft.copyWith(edgetunnelSubUrl: v),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '测速',
          subtitle: '候选列表可填多个 URL，一行一个。支持 Cloudflare 官方 CIDR（https://www.cloudflare.com/ips-v4）以及 IP:端口#备注。',
          child: Column(
            children: [
              _field(
                label: 'IP 来源 URL',
                value: draft.ipSourceUrlsText,
                maxLines: 4,
                onChanged: (v) => draft = draft.copyWith(
                  ipSourceUrls: v.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                ),
              ),
              _field(
                label: '额外 IP / CIDR（可选，本地粘贴）',
                value: draft.extraIpText,
                maxLines: 4,
                onChanged: (v) => draft = draft.copyWith(extraIpText: v),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _num('最多探测', draft.maxCandidates, (n) => draft = draft.copyWith(maxCandidates: n)),
                  _num('并发', draft.concurrency, (n) => draft = draft.copyWith(concurrency: n)),
                  _num('超时 ms', draft.timeoutMs, (n) => draft = draft.copyWith(timeoutMs: n)),
                  _num('保留 Top N', draft.topN, (n) => draft = draft.copyWith(topN: n)),
                  _num('探测端口', draft.probePort, (n) => draft = draft.copyWith(probePort: n)),
                  _num('下载测速条数', draft.downloadTopK, (n) => draft = draft.copyWith(downloadTopK: n)),
                  _num('下载字节', draft.downloadBytes, (n) => draft = draft.copyWith(downloadBytes: n)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('TLS 探测（443 建议开启）'),
                value: draft.probeTls,
                onChanged: (v) => setState(() => draft = draft.copyWith(probeTls: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('对延迟最优的一批再测下载速度'),
                value: draft.enableDownloadSpeed,
                onChanged: (v) => setState(() => draft = draft.copyWith(enableDownloadSpeed: v)),
              ),
              _field(
                label: '探测 SNI / Host（默认 cloudflare.com；下载测速会另连 speed.cloudflare.com）',
                value: draft.probeSni,
                onChanged: (v) => draft = draft.copyWith(probeSni: v),
              ),
              _field(
                label: '备注前缀（写入 IP#前缀-12ms）',
                value: draft.remarksPrefix,
                onChanged: (v) => draft = draft.copyWith(remarksPrefix: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '上传目标（edgetunnel 来读这份列表）',
          subtitle: 'GitHub 仓库最常见：把 raw URL 填进 ADDAPI。也可更新 Gist，或 PUT/POST 到自定义地址（含部分 2.x 管理接口）。',
          child: Column(
            children: [
              DropdownButtonFormField<PublishTarget>(
                initialValue: draft.publishTarget,
                decoration: const InputDecoration(labelText: '目标'),
                items: const [
                  DropdownMenuItem(value: PublishTarget.githubRepo, child: Text('GitHub 仓库文件')),
                  DropdownMenuItem(value: PublishTarget.githubGist, child: Text('GitHub Gist')),
                  DropdownMenuItem(value: PublishTarget.httpUpload, child: Text('自定义 HTTP 上传')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => draft = draft.copyWith(publishTarget: v));
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<OutputFormat>(
                initialValue: draft.outputFormat,
                decoration: const InputDecoration(labelText: '文件格式'),
                items: const [
                  DropdownMenuItem(value: OutputFormat.addressesApi, child: Text('addressesapi.txt（IP:端口#备注）')),
                  DropdownMenuItem(value: OutputFormat.addressesCsv, child: Text('addressescsv.csv（ADDCSV）')),
                  DropdownMenuItem(value: OutputFormat.both, child: Text('两种都写（仓库模式）')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => draft = draft.copyWith(outputFormat: v));
                },
              ),
              _field(
                label: 'GitHub Token（只存在本机）',
                value: draft.githubToken,
                obscure: true,
                onChanged: (v) => draft = draft.copyWith(githubToken: v),
              ),
              _field(label: 'Owner / 用户名', value: draft.githubOwner, onChanged: (v) => draft = draft.copyWith(githubOwner: v)),
              _field(label: '仓库名', value: draft.githubRepo, onChanged: (v) => draft = draft.copyWith(githubRepo: v)),
              _field(label: '分支', value: draft.githubBranch, onChanged: (v) => draft = draft.copyWith(githubBranch: v)),
              _field(label: 'txt 路径', value: draft.githubPath, onChanged: (v) => draft = draft.copyWith(githubPath: v)),
              _field(label: 'csv 路径', value: draft.githubCsvPath, onChanged: (v) => draft = draft.copyWith(githubCsvPath: v)),
              _field(label: 'Gist ID（可空，空则新建）', value: draft.gistId, onChanged: (v) => draft = draft.copyWith(gistId: v)),
              _field(label: 'Gist 文件名', value: draft.gistFilename, onChanged: (v) => draft = draft.copyWith(gistFilename: v)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('新建 Gist 时公开（默认私有）'),
                value: draft.gistPublic,
                onChanged: (v) => setState(() => draft = draft.copyWith(gistPublic: v)),
              ),
              _field(label: '自定义上传 URL', value: draft.httpUploadUrl, onChanged: (v) => draft = draft.copyWith(httpUploadUrl: v)),
              _field(label: 'HTTP 方法（PUT/POST/PATCH）', value: draft.httpUploadMethod, onChanged: (v) => draft = draft.copyWith(httpUploadMethod: v)),
              _field(
                label: '额外请求头（Authorization: Bearer … 或整段）',
                value: draft.httpAuthHeader,
                obscure: true,
                onChanged: (v) => draft = draft.copyWith(httpAuthHeader: v),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    await _save();
                    try {
                      final msg = await widget.controller.checkPublisher();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('检查上传目标'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '节点模板（仅调试导出 / 可选写本地文件）',
          subtitle: '主路径不需要这份模板：edgetunnel 自己会用 host/UUID 生成节点。模板只用于可选的 Clash YAML 导出。',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: draft.template.protocol,
                decoration: const InputDecoration(labelText: '协议'),
                items: const [
                  DropdownMenuItem(value: 'vless', child: Text('VLESS')),
                  DropdownMenuItem(value: 'trojan', child: Text('Trojan')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => draft = draft.copyWith(template: draft.template.copyWith(protocol: v)));
                  }
                },
              ),
              _field(label: 'Host / SNI', value: draft.template.hostSni, onChanged: (v) => _tmpl(draft.template.copyWith(hostSni: v))),
              _field(label: 'UUID / 密码', value: draft.template.uuidOrPassword, obscure: true, onChanged: (v) => _tmpl(draft.template.copyWith(uuidOrPassword: v))),
              _field(label: 'path', value: draft.template.path, onChanged: (v) => _tmpl(draft.template.copyWith(path: v))),
              _num('节点端口', draft.template.port, (n) => _tmpl(draft.template.copyWith(port: n))),
              _field(label: 'fingerprint', value: draft.template.fingerprint, onChanged: (v) => _tmpl(draft.template.copyWith(fingerprint: v))),
              _field(label: 'WS Host 头（可空=跟 SNI）', value: draft.template.hostHeader, onChanged: (v) => _tmpl(draft.template.copyWith(hostHeader: v))),
              const SizedBox(height: 8),
              TextField(
                controller: _import,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '从 vless://、trojan:// 或 Clash YAML 导入',
                  alignLabelWithHint: true,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    try {
                      final msg = widget.controller.importTemplate(_import.text);
                      setState(() {
                        formEpoch += 1;
                        draft = widget.controller.settings;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  child: const Text('导入模板'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '可选：本地调试订阅',
          subtitle: '默认关闭。打开后在本机提供 /sub，仅用于核对，不是给 Clash 日常使用的主路径。局域网绑定默认关。',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用本地 /sub'),
                value: draft.enableLocalSubServer,
                onChanged: (v) => setState(() => draft = draft.copyWith(enableLocalSubServer: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('绑定到局域网（0.0.0.0，注意安全）'),
                value: draft.localSubLanBind,
                onChanged: (v) => setState(() => draft = draft.copyWith(localSubLanBind: v)),
              ),
              _num('端口', draft.localSubPort, (n) => draft = draft.copyWith(localSubPort: n)),
              _field(
                label: '桌面 Clash 配置文件路径（可选）',
                value: draft.localClashProfilePath,
                onChanged: (v) => draft = draft.copyWith(localClashProfilePath: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('保存设置'),
        ),
      ],
    );
  }

  void _tmpl(NodeTemplate t) {
    draft = draft.copyWith(template: t);
  }

  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey('f-$formEpoch-$label'),
        initialValue: value,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          onChanged(v);
        },
      ),
    );
  }

  Widget _num(String label, int value, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        initialValue: '$value',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null) {
            setState(() => onChanged(n));
          }
        },
      ),
    );
  }
}
