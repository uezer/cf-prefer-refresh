import '../../models/app_settings.dart';
import '../../models/test_run.dart';

class LocalSubServer {
  bool get running => false;
  String get bindHint => '';

  Future<void> start({
    required AppSettings settings,
    required TestRun? Function() lastRun,
  }) async {
    throw UnsupportedError('本地 /sub 调试服务仅在 Linux / Windows / Android 可用');
  }

  Future<void> stop() async {}
}
