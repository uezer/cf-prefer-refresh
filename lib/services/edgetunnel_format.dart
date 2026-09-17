import '../models/probe_result.dart';

/// edgetunnel / WorkerVless2sub ADDAPI line: `IP:port#remark`
String addressesApiLine(ProbeResult r, {String remarksPrefix = 'Home'}) {
  final remark = buildRemark(r, remarksPrefix: remarksPrefix);
  return '${r.ip}:${r.port}#$remark';
}

String buildAddressesApi({
  required List<ProbeResult> ranked,
  String remarksPrefix = 'Home',
}) {
  return ranked
      .where((r) => r.success)
      .map((r) => addressesApiLine(r, remarksPrefix: remarksPrefix))
      .join('\n');
}

/// iptest / ADDCSV header used by cmliu-style converters.
const addressesCsvHeader = 'IP地址,端口,回源端口,TLS,数据中心,地区,城市,TCP延迟(ms),速度(MB/s)';

String buildAddressesCsv({
  required List<ProbeResult> ranked,
  bool tls = true,
}) {
  final rows = ranked.where((r) => r.success).map((r) {
    final colo = r.colo ?? '';
    final speed = (r.speedMBps ?? 0).toStringAsFixed(2);
    return '${r.ip},${r.port},${r.port},$tls,$colo,,,${r.latencyMs},$speed';
  });
  return ([addressesCsvHeader, ...rows]).join('\n');
}

String buildRemark(ProbeResult r, {String remarksPrefix = 'Home'}) {
  final prefix = remarksPrefix.trim();
  final latency = '${r.latencyMs}ms';
  final colo = (r.colo == null || r.colo!.isEmpty) ? '' : '-${r.colo}';
  if (prefix.isEmpty) return '$latency$colo';
  return '$prefix-$latency$colo';
}

String preferredListPreview(String body, {int maxLines = 8}) {
  final lines = body.split(RegExp(r'\r?\n')).where((e) => e.trim().isNotEmpty);
  final take = lines.take(maxLines).join('\n');
  final extra = lines.length - maxLines;
  if (extra <= 0) return take;
  return '$take\n… 另有 $extra 行';
}
