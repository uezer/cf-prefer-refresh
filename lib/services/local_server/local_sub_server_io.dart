import 'dart:io';

import '../../models/app_settings.dart';
import '../../models/test_run.dart';
import '../clash_export.dart';
import '../edgetunnel_format.dart';

class LocalSubServer {
  HttpServer? _server;

  bool get running => _server != null;

  String get bindHint {
    final s = _server;
    if (s == null) return '';
    return 'http://${s.address.address}:${s.port}/sub';
  }

  Future<void> start({
    required AppSettings settings,
    required TestRun? Function() lastRun,
  }) async {
    await stop();
    final addr = settings.localSubLanBind
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;
    _server = await HttpServer.bind(addr, settings.localSubPort);
    _server!.listen((req) async {
      try {
        await _handle(req, settings, lastRun);
      } catch (e) {
        req.response.statusCode = 500;
        req.response.write('$e');
        await req.response.close();
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(
    HttpRequest req,
    AppSettings settings,
    TestRun? Function() lastRun,
  ) async {
    final path = req.uri.path;
    final run = lastRun();
    final ranked = run?.ranked ?? const [];
    req.response.headers.set('Cache-Control', 'no-store');
    if (path == '/health') {
      req.response
        ..headers.contentType = ContentType.json
        ..write('{"ok":true}');
    } else if (path == '/ips' || path == '/addressesapi.txt') {
      req.response.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      req.response.write(
        buildAddressesApi(ranked: ranked, remarksPrefix: settings.remarksPrefix),
      );
    } else if (path == '/status') {
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        '{"tested":${run?.tested ?? 0},"top":${ranked.length},"at":"${run?.finishedAt?.toIso8601String() ?? ''}"}',
      );
    } else if (path == '/sub') {
      req.response.headers.contentType = ContentType(
        'text',
        'yaml',
        charset: 'utf-8',
      );
      req.response.write(
        buildClashSubscription(
          ranked: ranked,
          template: settings.template,
          remarksPrefix: settings.remarksPrefix,
        ),
      );
    } else {
      req.response.statusCode = 404;
      req.response.write(
        'CF Prefer Refresh debug server. Try /sub /ips /status /health',
      );
    }
    await req.response.close();
  }
}
