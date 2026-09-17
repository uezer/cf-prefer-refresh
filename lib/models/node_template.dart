class NodeTemplate {
  const NodeTemplate({
    this.protocol = 'vless',
    this.hostSni = 'edgetunnel-e5x.pages.dev',
    this.uuidOrPassword = '00000000-0000-4000-8000-000000000000',
    this.path = '/?ed=2560',
    this.port = 443,
    this.tls = true,
    this.fingerprint = 'chrome',
    this.remarks = 'CF',
    this.network = 'ws',
    this.hostHeader = '',
  });

  final String protocol;
  final String hostSni;
  final String uuidOrPassword;
  final String path;
  final int port;
  final bool tls;
  final String fingerprint;
  final String remarks;
  final String network;
  final String hostHeader;

  String get effectiveHostHeader =>
      hostHeader.trim().isEmpty ? hostSni.trim() : hostHeader.trim();

  NodeTemplate copyWith({
    String? protocol,
    String? hostSni,
    String? uuidOrPassword,
    String? path,
    int? port,
    bool? tls,
    String? fingerprint,
    String? remarks,
    String? network,
    String? hostHeader,
  }) {
    return NodeTemplate(
      protocol: protocol ?? this.protocol,
      hostSni: hostSni ?? this.hostSni,
      uuidOrPassword: uuidOrPassword ?? this.uuidOrPassword,
      path: path ?? this.path,
      port: port ?? this.port,
      tls: tls ?? this.tls,
      fingerprint: fingerprint ?? this.fingerprint,
      remarks: remarks ?? this.remarks,
      network: network ?? this.network,
      hostHeader: hostHeader ?? this.hostHeader,
    );
  }

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'hostSni': hostSni,
        'uuidOrPassword': uuidOrPassword,
        'path': path,
        'port': port,
        'tls': tls,
        'fingerprint': fingerprint,
        'remarks': remarks,
        'network': network,
        'hostHeader': hostHeader,
      };

  factory NodeTemplate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NodeTemplate();
    return NodeTemplate(
      protocol: (json['protocol'] as String?) ?? 'vless',
      hostSni: (json['hostSni'] as String?) ?? 'edgetunnel-e5x.pages.dev',
      uuidOrPassword:
          (json['uuidOrPassword'] as String?) ??
          '00000000-0000-4000-8000-000000000000',
      path: (json['path'] as String?) ?? '/?ed=2560',
      port: (json['port'] as num?)?.toInt() ?? 443,
      tls: json['tls'] as bool? ?? true,
      fingerprint: (json['fingerprint'] as String?) ?? 'chrome',
      remarks: (json['remarks'] as String?) ?? 'CF',
      network: (json['network'] as String?) ?? 'ws',
      hostHeader: (json['hostHeader'] as String?) ?? '',
    );
  }
}
