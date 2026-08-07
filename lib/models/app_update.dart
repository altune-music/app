/// Represents a release fetched from GitHub Releases.
///
/// Used by [UpdateService] to compare the current app version against
/// the latest release and present update information to the user.
class AppUpdate {
  /// The version tag of the release (e.g. "v1.2.0").
  final String version;

  /// The human-readable release name.
  final String name;

  /// The release notes / changelog.
  final String body;

  /// The URL to view the release on GitHub.
  final String htmlUrl;

  /// The tag name with the leading 'v' stripped, if present.
  ///
  /// For example, tag "v1.2.0" yields [versionWithoutPrefix] "1.2.0".
  String get versionWithoutPrefix {
    if (version.startsWith('v') && version.length > 1) {
      return version.substring(1);
    }
    return version;
  }

  AppUpdate({
    required this.version,
    required this.name,
    required this.body,
    required this.htmlUrl,
  });
}
