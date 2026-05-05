import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/main.dart' show navigatorKey;

class VersionService {
  static const String _baseUrl = 'https://amarhome.mn/api';
  static const String _versionCheckUrl = '$_baseUrl/version-check';

  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      print('📱 [VERSION] Current app version: $currentVersion ($buildNumber)');

      // Check with backend for required version
      final response = await http.get(
        Uri.parse('$_versionCheckUrl?platform=android&current=$currentVersion'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleVersionResponse(
          context,
          data,
          currentVersion,
          buildNumber,
        );
      }
    } catch (e) {
      print('⚠️ [VERSION] Error checking version: $e');
      // Don't show error to user - version check should be silent
    }
  }

  static Future<void> _handleVersionResponse(
    BuildContext context,
    Map<String, dynamic> data,
    String currentVersion,
    String buildNumber,
  ) async {
    final requiredVersion =
        data['requiredVersion'] as String? ?? currentVersion;
    final recommendedVersion = data['recommendedVersion'] as String?;
    final forceUpdate = data['forceUpdate'] as bool? ?? false;
    final updateMessage =
        data['updateMessage'] as String? ??
        'Шинэ хувилбар гарсан тул шинэчлэх шаардлагатай.';
    final playStoreUrl =
        data['playStoreUrl'] as String? ??
        'https://play.google.com/store/apps/details?id=com.sukhapp';

    print('📱 [VERSION] Required version: $requiredVersion');
    print('📱 [VERSION] Force update: $forceUpdate');

    // Compare versions (simple string comparison - you might want more sophisticated version comparison)
    if (_shouldUpdate(currentVersion, requiredVersion) || forceUpdate) {
      if (forceUpdate) {
        // Force update - user cannot continue
        _showForceUpdateDialog(context, updateMessage, playStoreUrl);
      } else if (recommendedVersion != null &&
          _shouldUpdate(currentVersion, recommendedVersion)) {
        // Recommended update - user can choose
        _showRecommendedUpdateDialog(context, updateMessage, playStoreUrl);
      }
    }
  }

  static bool _shouldUpdate(String currentVersion, String requiredVersion) {
    // Simple version comparison (1.0.0 format)
    final current = currentVersion.split('.').map(int.parse).toList();
    final required = requiredVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (current[i] < required[i]) return true;
      if (current[i] > required[i]) return false;
    }
    return false;
  }

  static void _showForceUpdateDialog(
    BuildContext context,
    String message,
    String playStoreUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text('Шинэчлэл шаардлагатай'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 12),
            Text(
              'Аппликейшны шинэ хувилбар гарсан тул шууд шинэчлэх шаардлагатай. Хуучин хувилбар ашиглах боломжгүй.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _launchPlayStore(playStoreUrl),
            icon: Icon(Icons.download),
            label: Text('Шинэчлэх'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static void _showRecommendedUpdateDialog(
    BuildContext context,
    String message,
    String playStoreUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update_alt, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text('Шинэ хувилбар гарсан'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 12),
            Text(
              'Шинэ хувилбарт шинэ боломжууд нэмэгдсэн байна. Шинэчлэх үү?',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Дараа'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchPlayStore(playStoreUrl);
            },
            icon: Icon(Icons.download),
            label: Text('Шинэчлэх'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchPlayStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('❌ [VERSION] Could not launch Play Store: $url');
      // Show error to user
      final context = navigatorKey.currentContext;
      if (context != null) {
        showGlassSnackBar(
          context,
          message: 'Play Store нээх боломжгүй байна',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }
}
