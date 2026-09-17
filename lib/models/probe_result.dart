class ProbeResult {
  const ProbeResult({
    required this.ip,
    required this.port,
    required this.success,
    this.tcpMs,
    this.httpMs,
    this.speedMBps,
    this.colo,
    this.error,
  });

  final String ip;
  final int port;
  final bool success;
  final int? tcpMs;
  final int? httpMs;
  final double? speedMBps;
  final String? colo;
  final String? error;

  int get latencyMs => httpMs ?? tcpMs ?? 999999;

  String get displayLatency => success ? '${latencyMs}ms' : (error ?? '失败');

  String get displaySpeed =>
      speedMBps == null ? '—' : '${speedMBps!.toStringAsFixed(2)} MB/s';

  ProbeResult copyWith({
    bool? success,
    int? tcpMs,
    int? httpMs,
    double? speedMBps,
    String? colo,
    String? error,
  }) {
    return ProbeResult(
      ip: ip,
      port: port,
      success: success ?? this.success,
      tcpMs: tcpMs ?? this.tcpMs,
      httpMs: httpMs ?? this.httpMs,
      speedMBps: speedMBps ?? this.speedMBps,
      colo: colo ?? this.colo,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'success': success,
        'tcpMs': tcpMs,
        'httpMs': httpMs,
        'speedMBps': speedMBps,
        'colo': colo,
        'error': error,
      };

  factory ProbeResult.fromJson(Map<String, dynamic> json) {
    return ProbeResult(
      ip: json['ip'] as String,
      port: (json['port'] as num?)?.toInt() ?? 443,
      success: json['success'] as bool? ?? false,
      tcpMs: (json['tcpMs'] as num?)?.toInt(),
      httpMs: (json['httpMs'] as num?)?.toInt(),
      speedMBps: (json['speedMBps'] as num?)?.toDouble(),
      colo: json['colo'] as String?,
      error: json['error'] as String?,
    );
  }
}

class IpCandidate {
  const IpCandidate({required this.ip, this.port, this.remark});

  final String ip;
  final int? port;
  final String? remark;

  String get key => '$ip:${port ?? 0}';
}
