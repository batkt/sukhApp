import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';

class HomeDataLoader {
  static Future<GereeResponse?> loadGereeData() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId != null) {
        final response = await ApiService.fetchGeree(userId);
        return GereeResponse.fromJson(response);
      }
    } catch (e) {
      // Silent fail
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loadNekhemjlekhCron() async {
    try {
      final barilgiinId = await StorageService.getBarilgiinId();
      if (barilgiinId == null) return null;

      final response = await ApiService.fetchNekhemjlekhCron(
        barilgiinId: barilgiinId,
      );
      final rawData = response['data'];

      if (rawData is Map<String, dynamic>) {
        return rawData['barilgiinId']?.toString() == barilgiinId
            ? rawData
            : null;
      } else if (rawData is List) {
        if (rawData.isEmpty) return null;
        final match = rawData
            .where(
              (item) =>
                  item is Map<String, dynamic> &&
                  item['barilgiinId']?.toString() == barilgiinId,
            )
            .toList();
        return match.isNotEmpty ? match.first as Map<String, dynamic> : null;
      }
    } catch (e) {
      // Silent fail - date calculation will fallback to contract date
    }
    return null;
  }
}
