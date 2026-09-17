import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../models/probe_result.dart';
import '../../models/publish_result.dart';
import '../edgetunnel_format.dart';
import 'github_gist_publisher.dart';
import 'github_repo_publisher.dart';
import 'http_publisher.dart';

class PublishBundle {
  const PublishBundle({required this.apiText, required this.csvText});
  final String apiText;
  final String csvText;
}

PublishBundle buildPublishBundle({
  required List<ProbeResult> ranked,
  required AppSettings settings,
}) {
  return PublishBundle(
    apiText: buildAddressesApi(
      ranked: ranked,
      remarksPrefix: settings.remarksPrefix,
    ),
    csvText: buildAddressesCsv(ranked: ranked, tls: settings.probeTls),
  );
}

abstract class Publisher {
  Future<PublishResult> publish({
    required AppSettings settings,
    required PublishBundle bundle,
  });

  Future<String> check(AppSettings settings);
}

Publisher publisherFor(AppSettings settings) {
  switch (settings.publishTarget) {
    case PublishTarget.githubRepo:
      return GithubRepoPublisher();
    case PublishTarget.githubGist:
      return GithubGistPublisher();
    case PublishTarget.httpUpload:
      return HttpPublisher();
  }
}
