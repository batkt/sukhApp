import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class HomeBillingManager {
  static Future<bool> deleteBilling({
    required BuildContext context,
    required Map<String, dynamic> billing,
    required String Function(String) expandAddressAbbreviations,
  }) async {
    final billingId =
        billing['billingId']?.toString() ??
        billing['walletBillingId']?.toString();

    if (billingId == null) {
      if (billing['isLocalData'] == true) {
        showGlassSnackBar(
          context,
          message: 'Энэ биллинг API-тай холбогдоогүй байна.',
          icon: Icons.info_outline,
          iconColor: Colors.orange,
        );
      }
      return false;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Биллинг устгах',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: Text(
          'Та энэ биллингийг устгахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        backgroundColor: context.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Тийм',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    try {
      await ApiService.removeWalletBilling(billingId: billingId);
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: 'Биллинг амжилттай устгагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }
  }

  static Future<bool> editBilling({
    required BuildContext context,
    required Map<String, dynamic> billing,
    required String Function(String) expandAddressAbbreviations,
    List<Map<String, dynamic>>? billingList,
    VoidCallback? onUpdated,
  }) async {
    final billingId =
        billing['billingId']?.toString() ??
        billing['walletBillingId']?.toString();

    if (billingId == null) {
      showGlassSnackBar(
        context,
        message: 'Энэ биллинг засварлах боломжгүй байна.',
        icon: Icons.info_outline,
        iconColor: Colors.orange,
      );
      return false;
    }

    final currentNickname = billing['nickname']?.toString() ?? '';
    final controller = TextEditingController(text: currentNickname);
    final isDark = context.isDarkMode;

    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2229) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.deepGreen,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Нэр өгөх',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black38,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  billing['billingName']?.toString() ?? 'Биллинг',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Жишээ: Миний байр',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(ctx).pop(controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    child: Center(
                      child: Text(
                        'Хадгалах',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return false;

    try {
      await ApiService.setWalletBillingNickname(
        billingId: billingId,
        nickname: result,
      );
      billing['nickname'] = result.isEmpty ? null : result;
      // Also update in billingList for consistency
      if (billingList != null) {
        for (int i = 0; i < billingList.length; i++) {
          final itemBillingId =
              billingList[i]['billingId']?.toString() ??
              billingList[i]['walletBillingId']?.toString();
          if (itemBillingId == billingId) {
            billingList[i]['nickname'] = result.isEmpty ? null : result;
            break;
          }
        }
      }
      onUpdated?.call();
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: result.isEmpty
              ? 'Хоч нэр устгагдлаа'
              : 'Хоч нэр хадгалагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }
  }
}
