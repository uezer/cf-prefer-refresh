import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../models/probe_result.dart';
import 'cancel_token.dart';

class ProbeEngine {
  const ProbeEngine();

  bool get supported => true;

  String get unsupportedReason => '';

  Future<ProbeResult> probeLatency({
    required IpCandidate candidate,
    required Duration timeout,
    required bool tls,
    required String sni,
    CancelToken? cancel,
  }) async {
    final port = candidate.port ?? 443;
    if (cancel?.isCancelled == true) {
      return ProbeResult(ip: candidate.ip, port: port, success: false, error: '已取消');
    }
    final sw = Stopwatch()..start();
    Socket? raw;
    SecureSocket? secure;
    try {
      raw = await Socket.connect(candidate.ip, port, timeout: timeout);
      final tcpMs = sw.elapsedMilliseconds;
      raw.setOption(SocketOption.tcpNoDelay, true);
      IOSink sink = raw;
      Stream<List<int>> stream = raw;
      if (tls) {
        secure = await SecureSocket.secure(
          raw,
          host: sni,
          onBadCertificate: (_) => true,
          supportedProtocols: const ['http/1.1'],
        ).timeout(timeout);
        sink = secure;
        stream = secure;
      }
      final req =
          'GET /cdn-cgi/trace HTTP/1.1\r\n'
          'Host: $sni\r\n'
          'User-Agent: CFPreferRefresh/1.0\r\n'
          'Accept: */*\r\n'
          'Connection: close\r\n\r\n';
      sink.add(utf8.encode(req));
      await sink.flush();
      var body = await _readUntil(
        stream,
        timeout: timeout,
        maxBytes: 8192,
        stopWhen: (text) => text.contains('colo=') || text.contains('loc='),
      );
      var colo = _field(body, 'colo');
      var looksCf = body.contains('colo=') || body.contains('fl=');
      if (!looksCf) {
        final fallback = await _plainHttpTrace(
          ip: candidate.ip,
          host: sni,
          timeout: timeout,
        );
        if (fallback != null) {
          body = fallback;
          colo = _field(body, 'colo');
          looksCf = colo != null;
        }
      }
      final httpMs = sw.elapsedMilliseconds;
      return ProbeResult(
        ip: candidate.ip,
        port: port,
        success: looksCf || tcpMs >= 0,
        tcpMs: tcpMs,
        httpMs: looksCf ? httpMs : tcpMs,
        colo: colo,
        error: looksCf ? null : '已连通，但未读到 cdn-cgi/trace',
      );
    } on TimeoutException {
      return ProbeResult(ip: candidate.ip, port: port, success: false, error: '超时');
    } on SocketException catch (e) {
      return ProbeResult(
        ip: candidate.ip,
        port: port,
        success: false,
        error: e.message.isEmpty ? '连接失败' : e.message,
      );
    } catch (e) {
      return ProbeResult(ip: candidate.ip, port: port, success: false, error: '$e');
    } finally {
      try {
        await secure?.close();
      } catch (_) {}
      try {
        raw?.destroy();
      } catch (_) {}
    }
  }

  Future<ProbeResult> probeDownload({
    required ProbeResult base,
    required Duration timeout,
    required bool tls,
    required String sni,
    required int downloadBytes,
    CancelToken? cancel,
  }) async {
    if (cancel?.isCancelled == true) return base;
    final bytes = downloadBytes < 1024 ? 1024 : downloadBytes;
    Socket? raw;
    SecureSocket? secure;
    try {
      raw = await Socket.connect(base.ip, base.port, timeout: timeout);
      raw.setOption(SocketOption.tcpNoDelay, true);
      IOSink sink = raw;
      Stream<List<int>> stream = raw;
      if (tls) {
        secure = await SecureSocket.secure(
          raw,
          host: sni,
          onBadCertificate: (_) => true,
          supportedProtocols: const ['http/1.1'],
        ).timeout(timeout);
        sink = secure;
        stream = secure;
      }
      final req =
          'GET /__down?bytes=$bytes HTTP/1.1\r\n'
          'Host: $sni\r\n'
          'User-Agent: CFPreferRefresh/1.0\r\n'
          'Accept: */*\r\n'
          'Connection: close\r\n\r\n';
      sink.add(utf8.encode(req));
      await sink.flush();
      final sw = Stopwatch()..start();
      final data = await _readBytes(stream, timeout: timeout, maxBytes: bytes + 4096);
      final elapsed = sw.elapsedMicroseconds / 1e6;
      if (elapsed <= 0) return base;
      final headerEnd = _indexOfHeaderEnd(data);
      final bodyLen = headerEnd < 0 ? data.length : data.length - headerEnd;
      if (bodyLen < 1024) return base;
      final mbps = (bodyLen / (1024 * 1024)) / elapsed;
      return base.copyWith(speedMBps: mbps);
    } catch (_) {
      return base;
    } finally {
      try {
        await secure?.close();
      } catch (_) {}
      try {
        raw?.destroy();
      } catch (_) {}
    }
  }
}

Future<String?> _plainHttpTrace({
  required String ip,
  required String host,
  required Duration timeout,
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(ip, 80, timeout: timeout);
    socket.add(
      utf8.encode(
        'GET /cdn-cgi/trace HTTP/1.1\r\n'
        'Host: $host\r\n'
        'User-Agent: CFPreferRefresh/1.0\r\n'
        'Connection: close\r\n\r\n',
      ),
    );
    await socket.flush();
    final body = await _readUntil(
      socket,
      timeout: timeout,
      maxBytes: 4096,
      stopWhen: (text) => text.contains('colo='),
    );
    if (body.contains('colo=')) return body;
  } catch (_) {
    return null;
  } finally {
    socket?.destroy();
  }
  return null;
}

Future<String> _readUntil(
  Stream<List<int>> stream, {
  required Duration timeout,
  required int maxBytes,
  required bool Function(String text) stopWhen,
}) async {
  final chunks = <int>[];
  try {
    await for (final chunk in stream.timeout(timeout)) {
      chunks.addAll(chunk);
      final text = utf8.decode(chunks, allowMalformed: true);
      if (stopWhen(text) || chunks.length >= maxBytes) {
        return text;
      }
    }
  } on TimeoutException {
    // return whatever we have
  }
  return utf8.decode(chunks, allowMalformed: true);
}

Future<Uint8List> _readBytes(
  Stream<List<int>> stream, {
  required Duration timeout,
  required int maxBytes,
}) async {
  final buffer = BytesBuilder(copy: false);
  try {
    await for (final chunk in stream.timeout(timeout)) {
      buffer.add(chunk);
      if (buffer.length >= maxBytes) break;
    }
  } on TimeoutException {
    // keep partial
  }
  return buffer.toBytes();
}

int _indexOfHeaderEnd(Uint8List data) {
  for (var i = 0; i < data.length - 3; i++) {
    if (data[i] == 13 &&
        data[i + 1] == 10 &&
        data[i + 2] == 13 &&
        data[i + 3] == 10) {
      return i + 4;
    }
  }
  return -1;
}

String? _field(String body, String key) {
  final match = RegExp('^$key=(.*)\\s*\$', multiLine: true).firstMatch(body);
  final value = match?.group(1)?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
