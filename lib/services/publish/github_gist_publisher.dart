import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../models/publish_result.dart';
import 'publisher.dart';

class GithubGistPublisher implements Publisher {
  GithubGistPublisher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PublishResult> publish({
    required AppSettings settings,
    required PublishBundle bundle,
  }) async {
    if (settings.githubToken.trim().isEmpty) {
      throw StateError('Gist 上传需要 GitHub Token（gist 权限）');
    }
    final files = <String, dynamic>{
      settings.gistFilename.trim().isEmpty
          ? 'addressesapi.txt'
          : settings.gistFilename.trim(): {'content': bundle.apiText},
    };
    if (settings.outputFormat != OutputFormat.addressesApi) {
      files[settings.githubCsvPath.trim().isEmpty
          ? 'addressescsv.csv'
          : settings.githubCsvPath.trim()] = {'content': bundle.csvText};
    }

    final headers = {
      'Authorization': 'Bearer ${settings.githubToken.trim()}',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'CFPreferRefresh/1.0',
    };

    http.Response res;
    String id = settings.gistId.trim();
    if (id.isEmpty) {
      res = await _client.post(
        Uri.parse('https://api.github.com/gists'),
        headers: headers,
        body: jsonEncode({
          'description': 'CF Prefer Refresh preferred IPs',
          'public': settings.gistPublic,
          'files': files,
        }),
      );
    } else {
      res = await _client.patch(
        Uri.parse('https://api.github.com/gists/$id'),
        headers: headers,
        body: jsonEncode({'files': files}),
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Gist 上传失败 HTTP ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    id = (body['id'] as String?) ?? id;
    final raw = _rawFromGist(body, settings.gistFilename);
    return PublishResult(
      ok: true,
      at: DateTime.now(),
      message: '已写入 GitHub Gist',
      remoteUrl: raw,
      gistId: id,
    );
  }

  @override
  Future<String> check(AppSettings settings) async {
    if (settings.githubToken.trim().isEmpty) {
      throw StateError('请先填写 GitHub Token');
    }
    if (settings.gistId.trim().isEmpty) {
      return '尚未填写 Gist ID，首次刷新会新建 Gist。';
    }
    final res = await _client.get(
      Uri.parse('https://api.github.com/gists/${settings.gistId.trim()}'),
      headers: {
        'Authorization': 'Bearer ${settings.githubToken.trim()}',
        'User-Agent': 'CFPreferRefresh/1.0',
      },
    );
    if (res.statusCode == 200) return 'Gist 可访问，可以覆盖更新。';
    throw StateError('Gist 检查失败 HTTP ${res.statusCode}');
  }

  String _rawFromGist(Map<String, dynamic> body, String filename) {
    final files = body['files'];
    if (files is Map && files.isNotEmpty) {
      final preferred = files[filename] ?? files.values.first;
      if (preferred is Map && preferred['raw_url'] is String) {
        return preferred['raw_url'] as String;
      }
    }
    return (body['html_url'] as String?) ?? '';
  }
}
