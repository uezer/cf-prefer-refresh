import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/app_settings.dart';
import '../models/probe_result.dart';
import '../models/test_run.dart';
import 'ip_list.dart';
import 'probe/cancel_token.dart';
import 'probe/probe_engine.dart';
import 'ranker.dart';

typedef ProgressCb = void Function(TestProgress progress);

class SpeedTester {
  SpeedTester({
    ProbeEngine? engine,
    http.Client? httpClient,
    this.fallbackAsset = 'assets/fallback_ips.txt',
  }) : engine = engine ?? const ProbeEngine(),
       httpClient = httpClient ?? http.Client();

  final ProbeEngine engine;
  final http.Client httpClient;
  final String fallbackAsset;

  Future<List<IpCandidate>> loadCandidates(
    AppSettings settings, {
    ProgressCb? onProgress,
  }) async {
    onProgress?.call(
      const TestProgress(phase: '拉取候选 IP', detail: '正在下载 IP 列表…'),
    );
    final chunks = <String>[];
    for (final rawUrl in settings.ipSourceUrls) {
      final url = rawUrl.trim();
      if (url.isEmpty) continue;
      try {
        final res = await httpClient
            .get(Uri.parse(url), headers: {'User-Agent': 'CFPreferRefresh/1.0'})
            .timeout(Duration(milliseconds: settings.timeoutMs + 4000));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          chunks.add(res.body);
        }
      } catch (_) {
        // continue; fallback / extra text still apply
      }
    }
    if (settings.extraIpText.trim().isNotEmpty) {
      chunks.add(settings.extraIpText);
    }
    if (chunks.isEmpty) {
      chunks.add(await rootBundle.loadString(fallbackAsset));
    }
    final parsed = <ParsedIpLine>[];
    for (final chunk in chunks) {
      parsed.addAll(parseIpListText(chunk));
    }
    if (parsed.isEmpty) {
      parsed.addAll(parseIpListText(await rootBundle.loadString(fallbackAsset)));
    }
    final perCidr = parsed.any((e) => e.prefix != null)
        ? _samplesPerCidr(settings.maxCandidates, parsed)
        : 8;
    return expandToCandidates(
      parsed,
      defaultPort: settings.probePort,
      maxCandidates: settings.maxCandidates,
      samplesPerCidr: perCidr,
    );
  }

  Future<List<ProbeResult>> run({
    required AppSettings settings,
    required CancelToken cancel,
    ProgressCb? onProgress,
  }) async {
    if (!engine.supported) {
      throw UnsupportedError(engine.unsupportedReason);
    }
    final candidates = await loadCandidates(settings, onProgress: onProgress);
    if (candidates.isEmpty) {
      throw StateError('候选 IP 列表为空');
    }
    if (cancel.isCancelled) return const [];

    final timeout = Duration(milliseconds: settings.timeoutMs);
    final latency = await _pool<IpCandidate, ProbeResult>(
      items: candidates,
      concurrency: settings.concurrency,
      cancel: cancel,
      phase: '延迟探测',
      onProgress: onProgress,
      work: (c) => engine.probeLatency(
        candidate: c,
        timeout: timeout,
        tls: settings.probeTls,
        sni: settings.probeSni,
        cancel: cancel,
      ),
    );

    var results = latency;
    if (settings.enableDownloadSpeed && !cancel.isCancelled) {
      final shortlist = rankResults(latency, topN: settings.downloadTopK);
      final downloaded = await _pool<ProbeResult, ProbeResult>(
        items: shortlist,
        concurrency: settings.concurrency < 8 ? settings.concurrency : 8,
        cancel: cancel,
        phase: '下载测速',
        onProgress: onProgress,
        work: (r) => engine.probeDownload(
          base: r,
          timeout: Duration(milliseconds: settings.timeoutMs + 4000),
          tls: settings.probeTls,
          sni: 'speed.cloudflare.com',
          downloadBytes: settings.downloadBytes,
          cancel: cancel,
        ),
      );
      final byKey = {for (final r in downloaded) '${r.ip}:${r.port}': r};
      results = [
        for (final r in latency) byKey['${r.ip}:${r.port}'] ?? r,
      ];
    }

    onProgress?.call(
      TestProgress(
        phase: '排序',
        done: results.length,
        total: results.length,
        currentBest: bestOf(results),
      ),
    );
    return results;
  }

  Future<List<R>> _pool<T, R extends ProbeResult>({
    required List<T> items,
    required int concurrency,
    required CancelToken cancel,
    required String phase,
    required Future<R> Function(T item) work,
    ProgressCb? onProgress,
  }) async {
    final out = List<R?>.filled(items.length, null);
    var next = 0;
    var done = 0;
    ProbeResult? best;

    Future<void> worker() async {
      while (true) {
        if (cancel.isCancelled) return;
        final i = next;
        next += 1;
        if (i >= items.length) return;
        final result = await work(items[i]);
        out[i] = result;
        done += 1;
        if (result.success) {
          best = bestOf([if (best != null) best!, result]);
        }
        onProgress?.call(
          TestProgress(
            phase: phase,
            done: done,
            total: items.length,
            currentBest: best,
            detail: best == null ? '' : '当前最优 ${best!.ip} ${best!.displayLatency}',
          ),
        );
      }
    }

    final n = concurrency < 1
        ? 1
        : (concurrency > items.length ? items.length : concurrency);
    await Future.wait(List.generate(n, (_) => worker()));
    return out.whereType<R>().toList();
  }
}

int _samplesPerCidr(int maxCandidates, List<ParsedIpLine> parsed) {
  final cidrs = parsed.where((e) => e.prefix != null).length;
  if (cidrs == 0) return 8;
  final n = (maxCandidates / cidrs).floor();
  if (n < 1) return 1;
  if (n > 16) return 16;
  return n;
}
