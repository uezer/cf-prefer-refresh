import 'probe_result.dart';
import 'publish_result.dart';

class TestProgress {
  const TestProgress({
    required this.phase,
    this.done = 0,
    this.total = 0,
    this.detail = '',
    this.currentBest,
  });

  final String phase;
  final int done;
  final int total;
  final String detail;
  final ProbeResult? currentBest;

  String get label {
    if (total <= 0) return detail.isEmpty ? phase : '$phase · $detail';
    return '$phase  $done/$total${detail.isEmpty ? '' : '  $detail'}';
  }
}

class TestRun {
  const TestRun({
    required this.startedAt,
    this.finishedAt,
    this.ranked = const [],
    this.tested = 0,
    this.succeeded = 0,
    this.cancelled = false,
    this.publish,
    this.error,
    this.uploadedBody = '',
  });

  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<ProbeResult> ranked;
  final int tested;
  final int succeeded;
  final bool cancelled;
  final PublishResult? publish;
  final String? error;
  final String uploadedBody;

  TestRun copyWith({
    DateTime? finishedAt,
    List<ProbeResult>? ranked,
    int? tested,
    int? succeeded,
    bool? cancelled,
    PublishResult? publish,
    String? error,
    String? uploadedBody,
  }) {
    return TestRun(
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      ranked: ranked ?? this.ranked,
      tested: tested ?? this.tested,
      succeeded: succeeded ?? this.succeeded,
      cancelled: cancelled ?? this.cancelled,
      publish: publish ?? this.publish,
      error: error ?? this.error,
      uploadedBody: uploadedBody ?? this.uploadedBody,
    );
  }

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'ranked': ranked.map((e) => e.toJson()).toList(),
        'tested': tested,
        'succeeded': succeeded,
        'cancelled': cancelled,
        'publish': publish?.toJson(),
        'error': error,
        'uploadedBody': uploadedBody,
      };

  factory TestRun.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TestRun(startedAt: DateTime.fromMillisecondsSinceEpoch(0));
    }
    final rankedRaw = json['ranked'];
    return TestRun(
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
      ranked: rankedRaw is List
          ? rankedRaw
              .whereType<Map>()
              .map((e) => ProbeResult.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      tested: (json['tested'] as num?)?.toInt() ?? 0,
      succeeded: (json['succeeded'] as num?)?.toInt() ?? 0,
      cancelled: json['cancelled'] as bool? ?? false,
      publish: json['publish'] == null
          ? null
          : PublishResult.fromJson(
              Map<String, dynamic>.from(json['publish'] as Map),
            ),
      error: json['error'] as String?,
      uploadedBody: (json['uploadedBody'] as String?) ?? '',
    );
  }
}
