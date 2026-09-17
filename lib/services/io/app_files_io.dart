import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_files_base.dart';

export 'app_files_base.dart' show AppFiles, MemoryAppFiles;

class IoAppFiles implements AppFiles {
  Directory? _dir;

  @override
  Future<void> init() async {
    _dir = await _supportDir();
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
  }

  Future<Directory> _supportDir() async {
    try {
      return await getApplicationSupportDirectory();
    } catch (_) {
      if (Platform.isWindows) {
        final root = Platform.environment['APPDATA'] ??
            Platform.environment['LOCALAPPDATA'] ??
            Directory.systemTemp.path;
        return Directory('$root/cf_prefer_refresh');
      }
      final xdg = Platform.environment['XDG_DATA_HOME'];
      final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
      return Directory('${xdg ?? '$home/.local/share'}/cf_prefer_refresh');
    }
  }

  Future<File> _file(String name) async {
    _dir ??= await _supportDir();
    return File('${_dir!.path}/$name');
  }

  @override
  Future<String?> read(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String name, String contents) async {
    final file = await _file(name);
    await file.writeAsString(contents, flush: true);
  }
}

AppFiles createAppFiles() => IoAppFiles();
