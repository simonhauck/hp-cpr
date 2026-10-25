import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed build's metadata.
@immutable
class AppInfo {
  const AppInfo({required this.version, required this.buildNumber});

  /// The marketing version of the installed build, for example `0.1.0`.
  final String version;

  /// The build number of the installed build, for example `1`.
  final String buildNumber;

  /// Formats the version with the build number when one is available.
  String versionLabel(String Function(String version, String build) format) {
    return buildNumber.isEmpty ? version : format(version, buildNumber);
  }

  /// Loads the installed build's metadata, or null when it is unavailable.
  static Future<AppInfo?> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(version: info.version, buildNumber: info.buildNumber);
    } catch (_) {
      return null;
    }
  }
}
