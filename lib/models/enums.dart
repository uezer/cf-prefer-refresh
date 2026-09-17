enum AppRole { publisher, subscribeOnly }

enum PublishTarget { githubRepo, githubGist, httpUpload }

enum OutputFormat { addressesApi, addressesCsv, both }

enum ProbePhase { idle, fetching, latency, download, ranking, publishing, done, error }

extension AppRoleX on AppRole {
  String get id => name;
  static AppRole fromId(String? raw) {
    return AppRole.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppRole.publisher,
    );
  }
}

extension PublishTargetX on PublishTarget {
  String get id => name;
  static PublishTarget fromId(String? raw) {
    return PublishTarget.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PublishTarget.githubRepo,
    );
  }
}

extension OutputFormatX on OutputFormat {
  String get id => name;
  static OutputFormat fromId(String? raw) {
    return OutputFormat.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => OutputFormat.addressesApi,
    );
  }
}
