import 'package:yaml/yaml.dart';

import '../models/node_template.dart';

class ImportResult {
  const ImportResult({required this.template, this.warning});
  final NodeTemplate template;
  final String? warning;
}

/// Import a `vless://` / `trojan://` share link or a Clash YAML snippet.
ImportResult importNodeTemplate(String raw) {
  final text = raw.trim();
  if (text.startsWith('vless://') || text.startsWith('trojan://')) {
    return ImportResult(template: _fromShareLink(text));
  }
  if (text.contains('proxies:') || text.contains('type:')) {
    return _fromClashYaml(text);
  }
  throw FormatException('无法识别：请粘贴 vless://、trojan:// 或 Clash YAML 片段');
}

NodeTemplate _fromShareLink(String link) {
  final uri = Uri.parse(link);
  final protocol = uri.scheme.toLowerCase();
  final q = uri.queryParameters;
  final sni = q['sni'] ?? q['host'] ?? uri.host;
  final path = _decode(q['path'] ?? '/');
  final hostHeader = q['host'] ?? sni;
  final fp = q['fp'] ?? q['fingerprint'] ?? 'chrome';
  final security = (q['security'] ?? '').toLowerCase();
  final tls = security != 'none' && security != '0';
  final remarks = uri.fragment.isEmpty ? 'CF' : Uri.decodeComponent(uri.fragment);
  return NodeTemplate(
    protocol: protocol == 'trojan' ? 'trojan' : 'vless',
    hostSni: sni,
    uuidOrPassword: Uri.decodeComponent(uri.userInfo),
    path: path.isEmpty ? '/' : path,
    port: uri.hasPort ? uri.port : 443,
    tls: tls || uri.port == 443,
    fingerprint: fp,
    remarks: remarks,
    network: q['type'] ?? 'ws',
    hostHeader: hostHeader,
  );
}

ImportResult _fromClashYaml(String text) {
  final doc = loadYaml(text);
  Map? proxy;
  if (doc is YamlMap && doc['proxies'] is YamlList && (doc['proxies'] as YamlList).isNotEmpty) {
    proxy = _asMap((doc['proxies'] as YamlList).first);
  } else if (doc is YamlMap && doc['type'] != null) {
    proxy = _asMap(doc);
  } else if (doc is YamlList && doc.isNotEmpty) {
    proxy = _asMap(doc.first);
  }
  if (proxy == null) {
    throw FormatException('YAML 里没有找到 proxies 节点');
  }
  final type = '${proxy['type'] ?? 'vless'}'.toLowerCase();
  if (type != 'vless' && type != 'trojan') {
    throw FormatException('仅支持 vless / trojan 模板，当前是 $type');
  }
  final ws = _asMap(proxy['ws-opts']) ?? const {};
  final headers = _asMap(ws['headers']) ?? const {};
  final uuid = '${proxy['uuid'] ?? proxy['password'] ?? ''}';
  return ImportResult(
    template: NodeTemplate(
      protocol: type,
      hostSni: '${proxy['servername'] ?? proxy['sni'] ?? proxy['server'] ?? ''}',
      uuidOrPassword: uuid,
      path: '${ws['path'] ?? '/'}',
      port: int.tryParse('${proxy['port'] ?? 443}') ?? 443,
      tls: proxy['tls'] != false,
      fingerprint: '${proxy['client-fingerprint'] ?? 'chrome'}',
      remarks: '${proxy['name'] ?? 'CF'}',
      network: '${proxy['network'] ?? 'ws'}',
      hostHeader: '${headers['Host'] ?? headers['host'] ?? ''}',
    ),
    warning: '已从 YAML 导入模板。生成节点时会用测速得到的入口 IP 替换 server。',
  );
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry('$k', v));
  }
  return null;
}

String _decode(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}
