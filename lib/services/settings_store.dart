import 'dart:convert';

import '../models/app_settings.dart';
import '../models/test_run.dart';
import 'io/app_files.dart';

class SettingsStore {
  SettingsStore({AppFiles? files}) : files = files ?? createAppFiles();

  final AppFiles files;

  Future<void> init() => files.init();

  Future<AppSettings> loadSettings() async {
    final raw = await files.read('settings.json');
    if (raw == null || raw.isEmpty) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    const encoder = JsonEncoder.withIndent('  ');
    await files.write('settings.json', encoder.convert(settings.toJson()));
  }

  Future<TestRun?> loadLastRun() async {
    final raw = await files.read('last_run.json');
    if (raw == null || raw.isEmpty) return null;
    return TestRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastRun(TestRun run) async {
    const encoder = JsonEncoder.withIndent('  ');
    await files.write('last_run.json', encoder.convert(run.toJson()));
  }
}
