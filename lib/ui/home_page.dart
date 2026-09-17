import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n.dart';
import '../models/enums.dart';
import '../state/app_controller.dart';
import '../theme.dart';
import 'widgets/copy_row.dart';
import 'widgets/role_badge.dart';
import 'widgets/section_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final run = c.lastRun;
    final best = run?.ranked.isNotEmpty == true ? run!.ranked.first : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _Hero(controller: c),
        const SizedBox(height: 12),
        _Callout(
          icon: Icons.warning_amber_rounded,
          color: AppColors.rustDeep,
          text: S.overwriteWarn,
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.wifi_tethering_rounded,
          color: AppColors.pine,
          text: S.networkHint,
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
          text: S.clashKeepsUrl,
        ),
        if (!c.probeSupported) ...[
          const SizedBox(height: 8),
          _Callout(
            icon: Icons.desktop_windows_outlined,
            color: AppColors.danger,
            text: c.tester.engine.unsupportedReason,
          ),
        ],
        const SizedBox(height: 12),
        SectionCard(
          title: '操作',
          subtitle: c.settings.isPublisher
              ? 'Refresh = 从现在起在当前网络测速，并覆盖上传优选列表。'
              : '仅订阅：不要上传。去 Clash 更新同一条 Cloudflare 订阅即可。',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: c.busy || !c.probeSupported
                    ? null
                    : () => c.refresh(upload: c.settings.isPublisher),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(c.settings.isPublisher ? '刷新 / Refresh' : '仅测速（不上传）'),
              ),
              if (c.settings.isPublisher)
                OutlinedButton(
                  onPressed: c.busy || !c.probeSupported ? null : () => c.refresh(upload: false),
                  child: const Text(S.testOnly),
                ),
              if (c.settings.isPublisher)
                OutlinedButton(
                  onPressed: c.busy ? null : c.retryPublish,
                  child: const Text(S.retryUpload),
                ),
              if (c.busy)
                TextButton.icon(
                  onPressed: c.cancel,
                  icon: const Icon(Icons.close),
                  label: const Text(S.cancel),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '进度',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.busy) const LinearProgressIndicator(),
              if (c.busy) const SizedBox(height: 10),
              Text(c.progress.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (c.progress.currentBest != null) ...[
                const SizedBox(height: 6),
                Text(
                  '当前最优 ${c.progress.currentBest!.ip}:${c.progress.currentBest!.port}  ${c.progress.currentBest!.displayLatency}  ${c.progress.currentBest!.displaySpeed}',
                ),
              ],
              if (c.banner != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pine.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(c.banner!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '最近一次测速',
          subtitle: run == null
              ? '还没有结果。配置节点模板与上传目标后点刷新。'
              : '开始于 ${_fmt(run.startedAt)} · 测试 ${run.tested} · 可用 ${run.succeeded}${run.cancelled ? ' · 已取消' : ''}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (best != null)
                Text(
                  'Top 1  ${best.ip}:${best.port}  ${best.displayLatency}  ${best.displaySpeed}${best.colo == null ? '' : '  ${best.colo}'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (run?.publish != null) ...[
                const SizedBox(height: 8),
                Text(run!.publish!.ok ? '上次上传：成功' : '上次上传：失败'),
                if (run.publish!.remoteUrl.isNotEmpty)
                  CopyRow(label: '优选列表 URL（给 edgetunnel ADDAPI）', value: run.publish!.remoteUrl),
              ],
              const SizedBox(height: 10),
              if (run == null || run.ranked.isEmpty)
                const Text('暂无排名 IP')
              else
                _IpTable(rows: run.ranked),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Clash 继续用这一条',
          subtitle: '不要改成 127.0.0.1。同一条 Cloudflare / edgetunnel 订阅，刷新后只需在 Clash 里更新。',
          child: Column(
            children: [
              CopyRow(label: 'Cloudflare 订阅 URL', value: c.settings.edgetunnelSubUrl),
              const SizedBox(height: 12),
              if (c.settings.edgetunnelSubUrl.startsWith('http'))
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: QrImageView(
                      data: c.settings.edgetunnelSubUrl,
                      size: 168,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '运行日志',
          child: SizedBox(
            height: 160,
            child: c.logs.isEmpty
                ? const Text('暂无日志')
                : ListView.builder(
                    itemCount: c.logs.length,
                    itemBuilder: (context, i) => Text(
                      c.logs[i],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final publisher = controller.settings.role == AppRole.publisher;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B211A), Color(0xFFC45C26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            S.appNameEn,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 12),
          RoleBadge(role: controller.settings.role, onDark: true),
          const SizedBox(height: 12),
          Text(
            publisher
                ? '在这台设备的当前网络上测 Cloudflare 入口 IP，再把名单推给 edgetunnel。Clash 始终订阅同一条 CF URL。'
                : '这台设备是仅订阅：不会上传、也不会覆盖发布者的优选列表。Clash 继续用同一条 CF 订阅即可。',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _IpTable extends StatelessWidget {
  const _IpTable({required this.rows});
  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('入口 IP')),
          DataColumn(label: Text('端口')),
          DataColumn(label: Text('延迟')),
          DataColumn(label: Text('速度')),
          DataColumn(label: Text('colo')),
        ],
        rows: [
          for (var i = 0; i < rows.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(SelectableText(rows[i].ip as String)),
                DataCell(Text('${rows[i].port}')),
                DataCell(Text(rows[i].displayLatency as String)),
                DataCell(Text(rows[i].displaySpeed as String)),
                DataCell(Text((rows[i].colo as String?) ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

String _fmt(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}
