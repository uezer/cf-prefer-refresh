abstract class AppFiles {
  Future<void> init();
  Future<String?> read(String name);
  Future<void> write(String name, String contents);
}

class MemoryAppFiles implements AppFiles {
  final Map<String, String> mem = {};

  @override
  Future<void> init() async {}

  @override
  Future<String?> read(String name) async => mem[name];

  @override
  Future<void> write(String name, String contents) async {
    mem[name] = contents;
  }
}
