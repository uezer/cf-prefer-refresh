import 'package:http/http.dart' as http;

import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../models/publish_result.dart';
import 'publisher.dart';

class HttpPublisher implements Publisher {
  HttpPublisher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PublishResult> publish({
    required AppSettings settings,
    required PublishBundle bundle,
  }) async {
    final url = settings.httpUploadUrl.trim();
    if (url.isEmpty) {
      throw StateError('请填写上传 URL（例如 GitHub raw 的自定义网关，或 edgetunnel 管理接口）');
    }
    final method = settings.httpUploadMethod.trim().toUpperCase();
    final headers = <String, String>{
      'Content-Type': 'text/plain; charset=utf-8',
      'User-Agent': 'CFPreferRefresh/1.0',
    };
    final auth = settings.httpAuthHeader.trim();
    if (auth.isNotEmpty) {
      final idx = auth.indexOf(':');
      if (idx > 0) {
        headers[auth.substring(0, idx).trim()] = auth.substring(idx + 1).trim();
      } else {
        headers['Authorization'] = auth;
      }
    }
    final body = settings.outputFormat == OutputFormat.addressesCsv
        ? bundle.csvText
        : bundle.apiText;
    final uri = Uri.parse(url);
    late http.Response res;
    if (method == 'POST') {
      res = await _client.post(uri, headers: headers, body: body);
    } else if (method == 'PUT') {
      res = await _client.put(uri, headers: headers, body: body);
    } else if (method == 'PATCH') {
      res = await _client.patch(uri, headers: headers, body: body);
    } else {
      throw StateError('不支持的 HTTP 方法: $method');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('上传失败 HTTP ${res.statusCode}: ${res.body}');
    }
    return PublishResult(
      ok: true,
      at: DateTime.now(),
      message: '已上传到自定义 URL',
      remoteUrl: url,
    );
  }

  @override
  Future<String> check(AppSettings settings) async {
    final url = settings.httpUploadUrl.trim();
    if (url.isEmpty) throw StateError('请填写上传 URL');
    Uri.parse(url);
    return 'URL 格式正确。真正写入会在刷新时用 ${settings.httpUploadMethod} 发送列表正文。';
  }
}
