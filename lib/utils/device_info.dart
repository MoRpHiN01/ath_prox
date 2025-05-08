import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfo {
  static Future<String> getSummary() async {
    final info = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return '''
App: ${pkg.appName} v${pkg.version} (${pkg.buildNumber})
Device: ${android.manufacturer} ${android.model}
Android: ${android.version.release}
''';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return '''
App: ${pkg.appName} v${pkg.version} (${pkg.buildNumber})
Device: ${ios.name} ${ios.model}
iOS: ${ios.systemVersion}
''';
    }
    return "Unknown device";
  }
}