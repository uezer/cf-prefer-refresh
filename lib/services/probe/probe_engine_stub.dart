import '../../models/probe_result.dart';
import 'cancel_token.dart';

class ProbeEngine {
  const ProbeEngine();

  bool get supported => false;

  String get unsupportedReason =>
      '当前环境无法做原始 TCP/TLS 探测（例如浏览器预览）。请使用 Linux / Windows / Android 客户端在本机网络测速。';

  Future<ProbeResult> probeLatency({
    required IpCandidate candidate,
    required Duration timeout,
    required bool tls,
    required String sni,
    CancelToken? cancel,
  }) async {
    return ProbeResult(
      ip: candidate.ip,
      port: candidate.port ?? 443,
      success: false,
      error: unsupportedReason,
    );
  }

  Future<ProbeResult> probeDownload({
    required ProbeResult base,
    required Duration timeout,
    required bool tls,
    required String sni,
    required int downloadBytes,
    CancelToken? cancel,
  }) async {
    return base.copyWith(error: unsupportedReason, success: false);
  }
}
