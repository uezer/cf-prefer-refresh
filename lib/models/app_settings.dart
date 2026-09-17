import 'enums.dart';
import 'node_template.dart';

class AppSettings {
  const AppSettings({
    this.role = AppRole.publisher,
    this.ipSourceUrls = const ['https://www.cloudflare.com/ips-v4'],
    this.extraIpText = '',
    this.maxCandidates = 256,
    this.concurrency = 32,
    this.timeoutMs = 1500,
    this.topN = 12,
    this.probePort = 443,
    this.probeTls = true,
    this.probeSni = 'cloudflare.com',
    this.enableDownloadSpeed = true,
    this.downloadBytes = 262144,
    this.downloadTopK = 24,
    this.publishTarget = PublishTarget.githubRepo,
    this.outputFormat = OutputFormat.addressesApi,
    this.githubOwner = '',
    this.githubRepo = '',
    this.githubBranch = 'main',
    this.githubPath = 'addressesapi.txt',
    this.githubCsvPath = 'addressescsv.csv',
    this.githubToken = '',
    this.gistId = '',
    this.gistFilename = 'addressesapi.txt',
    this.gistPublic = false,
    this.httpUploadUrl = '',
    this.httpUploadMethod = 'PUT',
    this.httpAuthHeader = '',
    this.edgetunnelSubUrl =
        'https://edgetunnel-e5x.pages.dev/sub?token=replace-me',
    this.remarksPrefix = 'Home',
    this.template = const NodeTemplate(),
    this.enableLocalSubServer = false,
    this.localSubPort = 18764,
    this.localSubLanBind = false,
    this.localClashProfilePath = '',
  });

  final AppRole role;
  final List<String> ipSourceUrls;
  final String extraIpText;
  final int maxCandidates;
  final int concurrency;
  final int timeoutMs;
  final int topN;
  final int probePort;
  final bool probeTls;
  final String probeSni;
  final bool enableDownloadSpeed;
  final int downloadBytes;
  final int downloadTopK;
  final PublishTarget publishTarget;
  final OutputFormat outputFormat;
  final String githubOwner;
  final String githubRepo;
  final String githubBranch;
  final String githubPath;
  final String githubCsvPath;
  final String githubToken;
  final String gistId;
  final String gistFilename;
  final bool gistPublic;
  final String httpUploadUrl;
  final String httpUploadMethod;
  final String httpAuthHeader;
  final String edgetunnelSubUrl;
  final String remarksPrefix;
  final NodeTemplate template;
  final bool enableLocalSubServer;
  final int localSubPort;
  final bool localSubLanBind;
  final String localClashProfilePath;

  bool get isPublisher => role == AppRole.publisher;

  String get ipSourceUrlsText => ipSourceUrls.join('\n');

  String get githubRawUrl {
    if (githubOwner.trim().isEmpty || githubRepo.trim().isEmpty) return '';
    final path = githubPath.replaceAll(RegExp(r'^/+'), '');
    return 'https://raw.githubusercontent.com/${githubOwner.trim()}/${githubRepo.trim()}/${githubBranch.trim()}/$path';
  }

  String get gistHintUrl => gistId.trim().isEmpty
      ? ''
      : 'https://gist.githubusercontent.com/${githubOwner.trim()}/${gistId.trim()}/raw/${gistFilename.trim()}';

  AppSettings copyWith({
    AppRole? role,
    List<String>? ipSourceUrls,
    String? extraIpText,
    int? maxCandidates,
    int? concurrency,
    int? timeoutMs,
    int? topN,
    int? probePort,
    bool? probeTls,
    String? probeSni,
    bool? enableDownloadSpeed,
    int? downloadBytes,
    int? downloadTopK,
    PublishTarget? publishTarget,
    OutputFormat? outputFormat,
    String? githubOwner,
    String? githubRepo,
    String? githubBranch,
    String? githubPath,
    String? githubCsvPath,
    String? githubToken,
    String? gistId,
    String? gistFilename,
    bool? gistPublic,
    String? httpUploadUrl,
    String? httpUploadMethod,
    String? httpAuthHeader,
    String? edgetunnelSubUrl,
    String? remarksPrefix,
    NodeTemplate? template,
    bool? enableLocalSubServer,
    int? localSubPort,
    bool? localSubLanBind,
    String? localClashProfilePath,
  }) {
    return AppSettings(
      role: role ?? this.role,
      ipSourceUrls: ipSourceUrls ?? this.ipSourceUrls,
      extraIpText: extraIpText ?? this.extraIpText,
      maxCandidates: maxCandidates ?? this.maxCandidates,
      concurrency: concurrency ?? this.concurrency,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      topN: topN ?? this.topN,
      probePort: probePort ?? this.probePort,
      probeTls: probeTls ?? this.probeTls,
      probeSni: probeSni ?? this.probeSni,
      enableDownloadSpeed: enableDownloadSpeed ?? this.enableDownloadSpeed,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      downloadTopK: downloadTopK ?? this.downloadTopK,
      publishTarget: publishTarget ?? this.publishTarget,
      outputFormat: outputFormat ?? this.outputFormat,
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepo: githubRepo ?? this.githubRepo,
      githubBranch: githubBranch ?? this.githubBranch,
      githubPath: githubPath ?? this.githubPath,
      githubCsvPath: githubCsvPath ?? this.githubCsvPath,
      githubToken: githubToken ?? this.githubToken,
      gistId: gistId ?? this.gistId,
      gistFilename: gistFilename ?? this.gistFilename,
      gistPublic: gistPublic ?? this.gistPublic,
      httpUploadUrl: httpUploadUrl ?? this.httpUploadUrl,
      httpUploadMethod: httpUploadMethod ?? this.httpUploadMethod,
      httpAuthHeader: httpAuthHeader ?? this.httpAuthHeader,
      edgetunnelSubUrl: edgetunnelSubUrl ?? this.edgetunnelSubUrl,
      remarksPrefix: remarksPrefix ?? this.remarksPrefix,
      template: template ?? this.template,
      enableLocalSubServer: enableLocalSubServer ?? this.enableLocalSubServer,
      localSubPort: localSubPort ?? this.localSubPort,
      localSubLanBind: localSubLanBind ?? this.localSubLanBind,
      localClashProfilePath: localClashProfilePath ?? this.localClashProfilePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.id,
        'ipSourceUrls': ipSourceUrls,
        'extraIpText': extraIpText,
        'maxCandidates': maxCandidates,
        'concurrency': concurrency,
        'timeoutMs': timeoutMs,
        'topN': topN,
        'probePort': probePort,
        'probeTls': probeTls,
        'probeSni': probeSni,
        'enableDownloadSpeed': enableDownloadSpeed,
        'downloadBytes': downloadBytes,
        'downloadTopK': downloadTopK,
        'publishTarget': publishTarget.id,
        'outputFormat': outputFormat.id,
        'githubOwner': githubOwner,
        'githubRepo': githubRepo,
        'githubBranch': githubBranch,
        'githubPath': githubPath,
        'githubCsvPath': githubCsvPath,
        'githubToken': githubToken,
        'gistId': gistId,
        'gistFilename': gistFilename,
        'gistPublic': gistPublic,
        'httpUploadUrl': httpUploadUrl,
        'httpUploadMethod': httpUploadMethod,
        'httpAuthHeader': httpAuthHeader,
        'edgetunnelSubUrl': edgetunnelSubUrl,
        'remarksPrefix': remarksPrefix,
        'template': template.toJson(),
        'enableLocalSubServer': enableLocalSubServer,
        'localSubPort': localSubPort,
        'localSubLanBind': localSubLanBind,
        'localClashProfilePath': localClashProfilePath,
      };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    final urls = json['ipSourceUrls'];
    return AppSettings(
      role: AppRoleX.fromId(json['role'] as String?),
      ipSourceUrls: urls is List
          ? urls.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList()
          : const ['https://www.cloudflare.com/ips-v4'],
      extraIpText: (json['extraIpText'] as String?) ?? '',
      maxCandidates: (json['maxCandidates'] as num?)?.toInt() ?? 256,
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 32,
      timeoutMs: (json['timeoutMs'] as num?)?.toInt() ?? 1500,
      topN: (json['topN'] as num?)?.toInt() ?? 12,
      probePort: (json['probePort'] as num?)?.toInt() ?? 443,
      probeTls: json['probeTls'] as bool? ?? true,
      probeSni: (json['probeSni'] as String?) ?? 'cloudflare.com',
      enableDownloadSpeed: json['enableDownloadSpeed'] as bool? ?? true,
      downloadBytes: (json['downloadBytes'] as num?)?.toInt() ?? 262144,
      downloadTopK: (json['downloadTopK'] as num?)?.toInt() ?? 24,
      publishTarget: PublishTargetX.fromId(json['publishTarget'] as String?),
      outputFormat: OutputFormatX.fromId(json['outputFormat'] as String?),
      githubOwner: (json['githubOwner'] as String?) ?? '',
      githubRepo: (json['githubRepo'] as String?) ?? '',
      githubBranch: (json['githubBranch'] as String?) ?? 'main',
      githubPath: (json['githubPath'] as String?) ?? 'addressesapi.txt',
      githubCsvPath: (json['githubCsvPath'] as String?) ?? 'addressescsv.csv',
      githubToken: (json['githubToken'] as String?) ?? '',
      gistId: (json['gistId'] as String?) ?? '',
      gistFilename: (json['gistFilename'] as String?) ?? 'addressesapi.txt',
      gistPublic: json['gistPublic'] as bool? ?? false,
      httpUploadUrl: (json['httpUploadUrl'] as String?) ?? '',
      httpUploadMethod: (json['httpUploadMethod'] as String?) ?? 'PUT',
      httpAuthHeader: (json['httpAuthHeader'] as String?) ?? '',
      edgetunnelSubUrl:
          (json['edgetunnelSubUrl'] as String?) ??
          'https://edgetunnel-e5x.pages.dev/sub?token=replace-me',
      remarksPrefix: (json['remarksPrefix'] as String?) ?? 'Home',
      template: NodeTemplate.fromJson(json['template'] as Map<String, dynamic>?),
      enableLocalSubServer: json['enableLocalSubServer'] as bool? ?? false,
      localSubPort: (json['localSubPort'] as num?)?.toInt() ?? 18764,
      localSubLanBind: json['localSubLanBind'] as bool? ?? false,
      localClashProfilePath: (json['localClashProfilePath'] as String?) ?? '',
    );
  }
}
