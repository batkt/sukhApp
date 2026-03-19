import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/screens/Home/billing_detail_page.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingActions {
  static Future<bool> showBillingDetailModal(
    BuildContext context,
    Map<String, dynamic> billing,
    String Function(String) expandAddressAbbreviations,
    String Function(double) formatNumberWithComma,
  ) async {
    if (billing['isLocalData'] == true) {
      context.push('/nekhemjlekh');
      return true;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillingDetailPage(
          billing: billing,
          expandAddressAbbreviations: expandAddressAbbreviations,
          formatNumberWithComma: formatNumberWithComma,
        ),
      ),
    );

    return result == true;
  }

  static void navigateToBillingList(
    BuildContext context, {
    required List<Map<String, dynamic>> billingList,
    required Map<String, dynamic>? userBillingData,
    required bool isLoading,
    required double totalBalance,
    required double totalAldangi,
    required Function(Map<String, dynamic>, BuildContext) onBillingTap,
    required String Function(String) expandAddressAbbreviations,
    required Function(Map<String, dynamic>)? onDeleteTap,
    required Function(Map<String, dynamic>)? onEditTap,
    required bool isConnecting,
    required VoidCallback onConnect,
    required Future<void> Function() onRefresh,
  }) {
    context.push('/billing-list', extra: {
      'billingList': billingList,
      'userBillingData': userBillingData,
      'isLoading': isLoading,
      'totalBalance': totalBalance,
      'totalAldangi': totalAldangi,
      'onBillingTap': onBillingTap,
      'expandAddressAbbreviations': expandAddressAbbreviations,
      'onDeleteTap': onDeleteTap,
      'onEditTap': onEditTap,
      'isConnecting': isConnecting,
      'onConnect': onConnect,
      'onRefresh': onRefresh,
    });
  }
}
