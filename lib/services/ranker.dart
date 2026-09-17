import '../models/probe_result.dart';

/// Rank successful probes: lower latency first, then higher download speed.
List<ProbeResult> rankResults(
  Iterable<ProbeResult> results, {
  int topN = 12,
  int minSpeedMBps = 0,
}) {
  final ok = results.where((r) => r.success).toList();
  ok.sort((a, b) {
    final latency = a.latencyMs.compareTo(b.latencyMs);
    if (latency != 0) return latency;
    final sa = a.speedMBps ?? -1;
    final sb = b.speedMBps ?? -1;
    return sb.compareTo(sa);
  });
  final filtered = minSpeedMBps <= 0
      ? ok
      : ok.where((r) => (r.speedMBps ?? 0) >= minSpeedMBps).toList();
  if (topN <= 0) return filtered;
  return filtered.take(topN).toList();
}

ProbeResult? bestOf(Iterable<ProbeResult> results) {
  final ranked = rankResults(results, topN: 1);
  return ranked.isEmpty ? null : ranked.first;
}
