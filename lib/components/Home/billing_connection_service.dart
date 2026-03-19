import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingConnectionService {
  static Future<void> connectBillingByAddress({
    required BuildContext context,
    required VoidCallback onConnectingStart,
    required VoidCallback onConnectingEnd,
    required VoidCallback onConnectionSuccess,
    required VoidCallback onConnectionError,
    required String Function(String) onError,
  }) async {
    onConnectingStart();

    try {
      // Get saved address
      final bairId = await StorageService.getWalletBairId();
      final doorNo = await StorageService.getWalletDoorNo();

      if (bairId == null || doorNo == null) {
        onConnectingEnd();
        onConnectionError();
        showGlassSnackBar(
          context,
          message: 'Хаяг олдсонгүй. Эхлээд хаягаа сонгоно уу.',
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      // Fetch billing by address and automatically connect it
      // The /walletBillingHavakh endpoint automatically connects billing
      await ApiService.fetchWalletBilling(bairId: bairId, doorNo: doorNo);

      onConnectingEnd();
      onConnectionSuccess();
      showGlassSnackBar(
        context,
        message: 'Биллинг амжилттай холбогдлоо',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (e) {
      onConnectingEnd();
      onConnectionError();
      final errorMessage = e.toString().contains('олдсонгүй')
          ? 'Биллингийн мэдээлэл олдсонгүй'
          : 'Биллинг холбоход алдаа гарлаа: $e';
      showGlassSnackBar(
        context,
        message: onError(errorMessage),
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }
}
