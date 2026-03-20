import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateModal extends StatefulWidget {
  final AppVersionInfo versionInfo;

  const UpdateModal({super.key, required this.versionInfo});

  @override
  State<UpdateModal> createState() => _UpdateModalState();
}

class _UpdateModalState extends State<UpdateModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      canPop: !widget.versionInfo.isForceUpdate,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.0),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.2),
                width: 2.r,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 24.h,
                    horizontal: 24.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26.r),
                      topRight: Radius.circular(26.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Modern Icon with Badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.system_update,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.deepGreen,
                                  width: 2.r,
                                ),
                              ),
                              child: Icon(
                                Icons.download,
                                color: AppColors.deepGreen,
                                size: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),
                      Text(
                        'Шинэ хувилбар гарсан байна',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Area
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Message Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                            width: 1.r,
                          ),
                        ),
                        child: Text(
                          widget.versionInfo.message,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 14.sp,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Action Buttons
                      Row(
                        children: [
                          // Skip Button - check condition explicitly
                          if (widget.versionInfo.isForceUpdate == false) ...[
                            // Skip Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  UpdateService.dismissUpdate(
                                    widget.versionInfo.version,
                                  );
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                ),
                                child: Text(
                                  'Дараа нь',
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          // Update Button
                          Expanded(
                            flex: widget.versionInfo.isForceUpdate ? 1 : 2,
                            child: ElevatedButton(
                              onPressed: _openStore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Шинэчлэх',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
