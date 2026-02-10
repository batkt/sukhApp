import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:sukh_app/constants/constants.dart';

String? _toPlatformIconName(String optionName) {
  if (optionName == 'default') return null;
  if (Platform.isAndroid) {
    if (optionName == 'black') return 'icon_1';
    if (optionName == 'blue') return 'icon_2';
    if (optionName == 'green') return 'icon_3';
  }
  return optionName; // iOS uses black, blue, green directly
}

Future<void> restoreAppIconOnStartup() async {
  try {
    final savedIcon = AppLogoNotifier.currentIcon.value;
    debugPrint('[AppIcon] Startup: restoring saved icon: $savedIcon');
    final supportsAlt = await FlutterDynamicIconPlus.supportsAlternateIcons;
    debugPrint('[AppIcon] Startup: supportsAlternateIcons=$supportsAlt');
    if (supportsAlt) {
      final platformName = _toPlatformIconName(savedIcon);
      debugPrint('[AppIcon] Startup: applying platform icon name: $platformName');
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: platformName,
        isSilent: true,
      );
      debugPrint('[AppIcon] Startup: icon restore applied');
    }
  } catch (e, stack) {
    debugPrint('[AppIcon] Startup restore error: $e');
    debugPrint('[AppIcon] Stack: $stack');
  }
}
