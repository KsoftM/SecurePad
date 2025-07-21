// platform_helper_io.dart
// Only imported on non-web platforms
import 'dart:io';

bool isSupportedPlatform() {
  return Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;
}
