import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../models/publish_result.dart';
import 'publisher.dart';

class GithubRepoPublisher implements Publisher {
  GithubRepoPublisher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PublishResult> publish({
    required AppSettings settings,
    required PublishBundle bundle,
  }) async {
    _assertReady(settings);
    final message =
        'prefer-ip: update from CF Prefer Refresh (${DateTime.now().toUtc().toIso8601String()})';
    String? lastUrl;
    if (settings.outputFormat != OutputFormat.addressesCsv) {
      lastUrl = await _putFile(
        settings: settings,
        path: settings.githubPath,
        content: bundle.apiText,
        message: message,
      );
    }
    if (settings.outputFormat != OutputFormat.addressesApi) {
      lastUrl = await _putFile(
        settings: settings,
        path: settings.githubCsvPath,
        content: bundle.csvText,
        message: message,
      );
    }
    return PublishResult(
      ok: true,
      at: DateTime.now(),
      message: '已写入 GitHub 仓库',
      remoteUrl: lastUrl ?? settings.githubRawUrl,
    );
  }

  @override
  Future<String> check(AppSettings settings) async {
    _assertReady(settings);
    final url = _contentsUrl(settings, settings.githubPath);
    final res = await _client.get(url, headers: _headers(settings.githubToken));
    if (res.statusCode == 200) return '已找到文件，可以覆盖更新。';
    if (res.statusCode == 404) return '文件尚不存在，首次刷新会创建。';
    throw StateError('GitHub 检查失败 HTTP ${res.statusCode}: ${res.body}');
  }

  Future<String> _putFile({
    required AppSettings settings,
    required String path,
    required String content,
    required String message,
  }) async {
    final url = _contentsUrl(settings, path);
    String? sha;
    final existing = await _client.get(url, headers: _headers(settings.githubToken));
    if (existing.statusCode == 200) {
      sha = (jsonDecode(existing.body) as Map<String, dynamic>)['sha'] as String?;
    } else if (existing.statusCode != 404) {
      throw StateError('读取 GitHub 文件失败 HTTP ${existing.statusCode}: ${existing.body}');
    }

    Future<http.Response> put(String? currentSha) {
      return _client.put(
        url,
        headers: _headers(settings.githubToken),
        body: jsonEncode({
          'message': message,
          'content': base64Encode(utf8.encode(content)),
          'branch': settings.githubBranch.trim(),
          'sha': ?currentSha,
        }),
      );
    }

    var res = await put(sha);
    if (res.statusCode == 409 || res.statusCode == 422) {
      final again = await _client.get(url, headers: _headers(settings.githubToken));
      if (again.statusCode == 200) {
        sha = (jsonDecode(again.body) as Map<String, dynamic>)['sha'] as String?;
        res = await put(sha);
      }
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('上传 GitHub 失败 HTTP ${res.statusCode}: ${res.body}');
    }
    return rawUrl(settings, path);
  }

  static String rawUrl(AppSettings settings, String path) {
    final clean = path.replaceAll(RegExp(r'^/+'), '');
    return 'https://raw.githubusercontent.com/${settings.githubOwner.trim()}/${settings.githubRepo.trim()}/${settings.githubBranch.trim()}/$clean';
  }

  Uri _contentsUrl(AppSettings settings, String path) {
    final encoded = path
        .split('/')
        .where((e) => e.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return Uri.parse(
      'https://api.github.com/repos/${settings.githubOwner.trim()}/${settings.githubRepo.trim()}/contents/$encoded',
    );
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'CFPreferRefresh/1.0',
      };

  void _assertReady(AppSettings settings) {
    if (settings.githubToken.trim().isEmpty) {
      throw StateError('请先填写 GitHub Token（需要 repo 或 public_repo 权限）');
    }
    if (settings.githubOwner.trim().isEmpty || settings.githubRepo.trim().isEmpty) {
      throw StateError('请先填写 GitHub 用户名 / 仓库名');
    }
  }
}
