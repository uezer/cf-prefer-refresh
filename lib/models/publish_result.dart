class PublishResult {
  const PublishResult({
    required this.ok,
    required this.at,
    this.message = '',
    this.remoteUrl = '',
    this.gistId,
  });

  final bool ok;
  final DateTime at;
  final String message;
  final String remoteUrl;
  final String? gistId;

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'at': at.toIso8601String(),
        'message': message,
        'remoteUrl': remoteUrl,
        'gistId': gistId,
      };

  factory PublishResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PublishResult(ok: false, at: DateTime.fromMillisecondsSinceEpoch(0));
    }
    return PublishResult(
      ok: json['ok'] as bool? ?? false,
      at: DateTime.tryParse(json['at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      message: (json['message'] as String?) ?? '',
      remoteUrl: (json['remoteUrl'] as String?) ?? '',
      gistId: json['gistId'] as String?,
    );
  }
}
