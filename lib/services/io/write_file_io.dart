import 'dart:io';

Future<String> writeTextFileImpl(String path, String contents) async {
  final file = File(path);
  await file.writeAsString(contents, flush: true);
  return file.path;
}
