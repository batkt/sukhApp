import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateModal extends StatelessWidget {
  final AppVersionInfo versionInfo;

  const UpdateModal({super.key, required this.versionInfo});

  Future<void> _openStore() async {
    try {
      final storeUrl = UpdateService.getStoreUrl();
      if (storeUrl.isNotEmpty) {
        final uri = Uri.parse(storeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error opening store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return PopScope(
      canPop: !versionInfo.isForceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing(
            small: 20,
            medium: 24,
            large: 28,
            tablet: 32,
            veryNarrow: 16,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        versionInfo.isForceUpdate
                            ? Icons.warning_rounded
                            : Icons.system_update_rounded,
                        color: versionInfo.isForceUpdate
                            ? Colors.orange
                            : AppColors.deepGreen,
                        size: context.responsiveFontSize(
                          small: 24,
                          medium: 26,
                          large: 28,
                          tablet: 30,
                          veryNarrow: 22,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        versionInfo.isForceUpdate
                            ? 'Заавал шинэчлэх шаардлагатай'
                            : 'Шинэ хувилбар гарсан байна',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 19,
                            veryNarrow: 15,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      versionInfo.message,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 17,
                          veryNarrow: 13,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _openStore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Шинэчлэх',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                              small: 15,
                              medium: 16,
                              large: 17,
                              tablet: 18,
                              veryNarrow: 14,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!versionInfo.isForceUpdate) ...[
                      SizedBox(height: 12.h),
                      // Later Button
                      TextButton(
                        onPressed: () {
                          UpdateService.dismissUpdate(versionInfo.version);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Дараа нь',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
