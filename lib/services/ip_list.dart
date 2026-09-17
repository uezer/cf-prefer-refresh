import '../models/probe_result.dart';

final _ipv4 = RegExp(
  r'^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$',
);
final _ipv6ish = RegExp(r'^[0-9a-fA-F:]+$');
final _cidr = RegExp(
  r'^((?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d))/(\d|[12]\d|3[0-2])$',
);

class ParsedIpLine {
  const ParsedIpLine({required this.ip, this.port, this.remark, this.prefix});

  final String ip;
  final int? port;
  final String? remark;
  final int? prefix;
}

/// Parse Cloudflare-style lists: CIDR, IP, IP:port, IP:port#remark.
List<ParsedIpLine> parseIpListText(String text) {
  final out = <ParsedIpLine>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parsed = parseIpLine(line);
    if (parsed != null) out.add(parsed);
  }
  return out;
}

ParsedIpLine? parseIpLine(String line) {
  var body = line.trim();
  String? remark;
  final hash = body.indexOf('#');
  if (hash >= 0) {
    remark = body.substring(hash + 1).trim();
    body = body.substring(0, hash).trim();
  }
  // CSV leftover: take first cell if it looks like IP
  if (body.contains(',') && !body.contains(':')) {
    body = body.split(',').first.trim();
  }

  final cidr = _cidr.firstMatch(body);
  if (cidr != null) {
    return ParsedIpLine(
      ip: cidr.group(1)!,
      prefix: int.parse(cidr.group(2)!),
      remark: remark,
    );
  }

  // [IPv6]:port
  if (body.startsWith('[')) {
    final end = body.indexOf(']');
    if (end > 1) {
      final ip = body.substring(1, end);
      int? port;
      if (body.length > end + 1 && body[end + 1] == ':') {
        port = int.tryParse(body.substring(end + 2));
      }
      return ParsedIpLine(ip: ip, port: port, remark: remark);
    }
  }

  final lastColon = body.lastIndexOf(':');
  if (lastColon > 0 && body.substring(0, lastColon).contains('.')) {
    final ip = body.substring(0, lastColon);
    final port = int.tryParse(body.substring(lastColon + 1));
    if (_ipv4.hasMatch(ip) && port != null) {
      return ParsedIpLine(ip: ip, port: port, remark: remark);
    }
  }

  if (_ipv4.hasMatch(body) || _looksLikeIpv6(body)) {
    return ParsedIpLine(ip: body, remark: remark);
  }
  return null;
}

bool _looksLikeIpv6(String body) {
  if (!_ipv6ish.hasMatch(body) || !body.contains(':')) return false;
  return body.split(':').length >= 3;
}

int ipv4ToInt(String ip) {
  final p = ip.split('.').map(int.parse).toList();
  return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
}

String intToIpv4(int value) {
  final v = value & 0xFFFFFFFF;
  return '${(v >> 24) & 0xFF}.${(v >> 16) & 0xFF}.${(v >> 8) & 0xFF}.${v & 0xFF}';
}

/// Evenly sample host addresses from a CIDR (skips network / broadcast when possible).
List<String> sampleCidr(String network, int prefix, {int maxSamples = 8}) {
  if (prefix < 0 || prefix > 32) return const [];
  if (prefix == 32) return [network];
  final hostBits = 32 - prefix;
  final size = 1 << hostBits;
  final base = ipv4ToInt(network) & (0xFFFFFFFF << hostBits);
  if (size <= 2) {
    return [intToIpv4(base + (size == 2 ? 0 : 0))];
  }
  final usable = size - 2;
  final take = maxSamples < 1 ? 1 : (maxSamples > usable ? usable : maxSamples);
  final out = <String>[];
  if (take == 1) {
    out.add(intToIpv4(base + 1));
    return out;
  }
  for (var i = 0; i < take; i++) {
    final offset = 1 + ((i * (usable - 1)) / (take - 1)).round();
    out.add(intToIpv4(base + offset));
  }
  return out.toSet().toList();
}

List<IpCandidate> expandToCandidates(
  Iterable<ParsedIpLine> lines, {
  int defaultPort = 443,
  int maxCandidates = 256,
  int samplesPerCidr = 8,
}) {
  final seen = <String>{};
  final out = <IpCandidate>[];
  for (final line in lines) {
    if (out.length >= maxCandidates) break;
    if (line.prefix != null) {
      final remaining = maxCandidates - out.length;
      final samples = sampleCidr(
        line.ip,
        line.prefix!,
        maxSamples: samplesPerCidr < remaining ? samplesPerCidr : remaining,
      );
      for (final ip in samples) {
        if (out.length >= maxCandidates) break;
        final key = '$ip:${line.port ?? defaultPort}';
        if (seen.add(key)) {
          out.add(IpCandidate(ip: ip, port: line.port ?? defaultPort, remark: line.remark));
        }
      }
    } else {
      final key = '${line.ip}:${line.port ?? defaultPort}';
      if (seen.add(key)) {
        out.add(
          IpCandidate(
            ip: line.ip,
            port: line.port ?? defaultPort,
            remark: line.remark,
          ),
        );
      }
    }
  }
  return out;
}
