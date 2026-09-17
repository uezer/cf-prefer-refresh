import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/probe_result.dart';
import '../models/publish_result.dart';
import '../models/test_run.dart';
import '../services/clash_export.dart';
import '../services/edgetunnel_format.dart';
import '../services/io/write_file.dart';
import '../services/local_server/local_sub_server.dart';
import '../services/probe/cancel_token.dart';
import '../services/publish/publisher.dart';
import '../services/ranker.dart';
import '../services/settings_store.dart';
import '../services/speed_test.dart';
import '../services/vless_import.dart';

class AppController extends ChangeNotifier {
  AppController({
    SettingsStore? store,
    SpeedTester? tester,
    LocalSubServer? server,
  }) : store = store ?? SettingsStore(),
       tester = tester ?? SpeedTester(),
       server = server ?? LocalSubServer();

  final SettingsStore store;
  final SpeedTester tester;
  final LocalSubServer server;

  AppSettings settings = const AppSettings();
  TestRun? lastRun;
  TestProgress progress = const TestProgress(phase: '空闲');
  bool busy = false;
  bool loaded = false;
  String? banner;
  final List<String> logs = [];
  CancelToken? _cancel;

  bool get canPublish => settings.isPublisher;
  bool get probeSupported => tester.engine.supported;

  Future<void> load() async {
    await store.init();
    settings = await store.loadSettings();
    lastRun = await store.loadLastRun();
    loaded = true;
    _log('已加载本地设置与上次结果');
    await _syncLocalServer();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    final restartServer =
        next.enableLocalSubServer != settings.enableLocalSubServer ||
        next.localSubPort != settings.localSubPort ||
        next.localSubLanBind != settings.localSubLanBind;
    settings = next;
    await store.saveSettings(settings);
    if (restartServer) {
      await _syncLocalServer();
    }
    notifyListeners();
  }

  Future<void> refresh({required bool upload}) async {
    if (busy) return;
    if (upload && !settings.isPublisher) {
      banner = '当前是「仅订阅」。Clash 只需更新 Cloudflare 订阅；测速上传请改用发布者角色。';
      notifyListeners();
      return;
    }
    busy = true;
    banner = null;
    final cancel = CancelToken();
    _cancel = cancel;
    final started = DateTime.now();
    progress = const TestProgress(phase: '开始', detail: '从当前网络测速');
    _log(upload ? '刷新：本机测速 + 上传' : '仅测速：不上传');
    notifyListeners();
    try {
      final raw = await tester.run(
        settings: settings,
        cancel: cancel,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
      );
      if (cancel.isCancelled) {
        lastRun = TestRun(
          startedAt: started,
          finishedAt: DateTime.now(),
          ranked: rankResults(raw, topN: settings.topN),
          tested: raw.length,
          succeeded: raw.where((e) => e.success).length,
          cancelled: true,
        );
        banner = '已取消。已保存中途测到的结果，但未上传。';
        _log(banner!);
      } else {
        final ranked = rankResults(raw, topN: settings.topN);
        if (ranked.isEmpty) {
          throw StateError('没有测到可用的入口 IP。请检查网络、候选列表或放宽超时。');
        }
        var run = TestRun(
          startedAt: started,
          finishedAt: DateTime.now(),
          ranked: ranked,
          tested: raw.length,
          succeeded: raw.where((e) => e.success).length,
          uploadedBody: buildAddressesApi(
            ranked: ranked,
            remarksPrefix: settings.remarksPrefix,
          ),
        );
        if (upload) {
          progress = const TestProgress(phase: '上传', detail: '写入 edgetunnel 使用的优选列表');
          notifyListeners();
          final published = await _publish(ranked);
          run = run.copyWith(publish: published);
          banner =
              '已更新优选 IP。请在 Clash 打开同一条 Cloudflare 订阅并点「更新订阅」。\n${settings.edgetunnelSubUrl}';
          _log('上传成功 ${published.remoteUrl}');
        } else {
          banner = '测速完成，未上传。发布者可点「重新上传上次结果」。';
          _log('仅测速完成，Top ${ranked.length}');
        }
        lastRun = run;
      }
      if (lastRun != null) await store.saveLastRun(lastRun!);
      progress = TestProgress(
        phase: cancel.isCancelled ? '已取消' : '完成',
        done: lastRun?.tested ?? 0,
        total: lastRun?.tested ?? 0,
        currentBest: lastRun?.ranked.isEmpty == true ? null : lastRun!.ranked.first,
      );
    } catch (e) {
      banner = '$e';
      progress = TestProgress(phase: '出错', detail: '$e');
      _log('失败: $e');
      lastRun = TestRun(
        startedAt: started,
        finishedAt: DateTime.now(),
        error: '$e',
        ranked: lastRun?.ranked ?? const [],
      );
    } finally {
      busy = false;
      _cancel = null;
      notifyListeners();
    }
  }

  Future<void> retryPublish() async {
    final ranked = lastRun?.ranked ?? const [];
    if (ranked.isEmpty) {
      banner = '还没有可上传的测速结果';
      notifyListeners();
      return;
    }
    if (!settings.isPublisher) {
      banner = '仅订阅角色不会上传，避免覆盖发布者的列表。';
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final published = await _publish(ranked);
      lastRun = (lastRun ?? TestRun(startedAt: DateTime.now())).copyWith(
        publish: published,
        uploadedBody: buildAddressesApi(
          ranked: ranked,
          remarksPrefix: settings.remarksPrefix,
        ),
      );
      await store.saveLastRun(lastRun!);
      banner =
          '已重新上传。请在 Clash 更新订阅：\n${settings.edgetunnelSubUrl}';
      _log('重新上传成功');
    } catch (e) {
      banner = '$e';
      _log('重新上传失败: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancel() {
    _cancel?.cancel();
    _log('正在取消…');
    notifyListeners();
  }

  Future<PublishResult> _publish(List<ProbeResult> ranked) async {
    final bundle = buildPublishBundle(ranked: ranked, settings: settings);
    final publisher = publisherFor(settings);
    final result = await publisher.publish(settings: settings, bundle: bundle);
    if (result.gistId != null && result.gistId != settings.gistId) {
      await updateSettings(settings.copyWith(gistId: result.gistId));
    }
    return result;
  }

  Future<String> checkPublisher() async {
    return publisherFor(settings).check(settings);
  }

  String importTemplate(String raw) {
    final result = importNodeTemplate(raw);
    updateSettings(settings.copyWith(template: result.template));
    return result.warning ?? '已导入节点模板';
  }

  String clashYaml() {
    return buildClashSubscription(
      ranked: lastRun?.ranked ?? const [],
      template: settings.template,
      remarksPrefix: settings.remarksPrefix,
    );
  }

  String addApiText() {
    return buildAddressesApi(
      ranked: lastRun?.ranked ?? const [],
      remarksPrefix: settings.remarksPrefix,
    );
  }

  Future<String> writeClashProfile() async {
    final path = settings.localClashProfilePath.trim();
    if (path.isEmpty) {
      throw StateError('请先在设置里填写要写入的 Clash 配置文件路径');
    }
    return writeTextFileImpl(path, clashYaml());
  }

  Future<void> _syncLocalServer() async {
    if (!settings.enableLocalSubServer) {
      await server.stop();
      return;
    }
    try {
      await server.start(settings: settings, lastRun: () => lastRun);
      _log('本地调试订阅: ${server.bindHint}');
    } catch (e) {
      _log('本地订阅服务未启动: $e');
    }
  }

  void _log(String line) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    logs.insert(0, '$ts  $line');
    if (logs.length > 80) {
      logs.removeRange(80, logs.length);
    }
  }
}
