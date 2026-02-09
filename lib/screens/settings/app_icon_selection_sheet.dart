import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class AppIconOption {
  final String name;
  final String displayName;
  final String imagePath;

  const AppIconOption({
    required this.name,
    required this.displayName,
    required this.imagePath,
  });
}

class AppIconSelectionSheet extends StatefulWidget {
  const AppIconSelectionSheet({super.key});

  @override
  State<AppIconSelectionSheet> createState() => _AppIconSelectionSheetState();
}

class _AppIconSelectionSheetState extends State<AppIconSelectionSheet> {
  String? currentIconName;
  bool isLoading = false;

  // Define available logo variants (logo_3.png, logo_3black, logo_3blue, logo_3green)
  static const List<AppIconOption> iconOptions = [
    AppIconOption(
      name: 'default',
      displayName: 'Үндсэн',
      imagePath: AppLogoAssets.defaultLogo,
    ),
    AppIconOption(
      name: 'black',
      displayName: 'Хар',
      imagePath: AppLogoAssets.blackLogo,
    ),
    AppIconOption(
      name: 'blue',
      displayName: 'Цэнхэр',
      imagePath: AppLogoAssets.blueLogo,
    ),
    AppIconOption(
      name: 'green',
      displayName: 'Ногоон',
      imagePath: AppLogoAssets.greenLogo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon(); // async, will setState when done
  }

  Future<void> _loadCurrentIcon() async {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        final iconName = await FlutterDynamicIconPlus.alternateIconName;
        setState(() {
          currentIconName = _fromPlatformIconName(iconName);
        });
      } else {
        setState(() {
          currentIconName = AppLogoNotifier.currentIcon.value;
        });
      }
    } catch (e) {
      setState(() {
        currentIconName = AppLogoNotifier.currentIcon.value;
      });
    }
  }

  /// Map platform icon name (icon_1, icon_2, icon_3 on Android) to our option name
  String _fromPlatformIconName(String? platformName) {
    if (platformName == null) return 'default';
    if (!kIsWeb && Platform.isAndroid) {
      if (platformName == 'icon_1') return 'black';
      if (platformName == 'icon_2') return 'blue';
      if (platformName == 'icon_3') return 'green';
    }
    return platformName;
  }

  /// Map our option name to platform icon name for FlutterDynamicIconPlus
  String? _toPlatformIconName(String optionName) {
    if (optionName == 'default') return null;
    if (!kIsWeb && Platform.isAndroid) {
      if (optionName == 'black') return 'icon_1';
      if (optionName == 'blue') return 'icon_2';
      if (optionName == 'green') return 'icon_3';
    }
    return optionName; // iOS uses black, blue, green directly
  }

  Future<void> _changeIcon(AppIconOption option) async {
    if (currentIconName == option.name) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Change home screen app icon (iOS & Android)
      bool iconChanged = false;
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        try {
          final supportsAlt = await FlutterDynamicIconPlus.supportsAlternateIcons;
          if (supportsAlt) {
            await FlutterDynamicIconPlus.setAlternateIconName(
              iconName: _toPlatformIconName(option.name),
            );
            iconChanged = true;
          }
        } catch (e) {
          debugPrint('FlutterDynamicIconPlus error: $e');
        }
      }

      // Save preference and update in-app logo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_icon', option.name);
      AppLogoNotifier.setIcon(option.name);

      setState(() {
        currentIconName = option.name;
        isLoading = false;
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        final isAndroid = !kIsWeb && Platform.isAndroid;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              iconChanged && isAndroid
                  ? 'Апп дүрс солигдлоо. Өөрчлөлт харагдахын тулд аппаа бүрэн хаана уу.'
                  : 'Апп дүрс "${option.displayName}" болж өөрчлөгдлөө',
            ),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
            duration: isAndroid ? const Duration(seconds: 5) : const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Дүрс солиход алдаа гарлаа: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error changing icon: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Дүрс солиход алдаа гарлаа'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error changing icon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            'Апп дүрс сонгох',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),

          // Subtitle
          Text(
            'Өөрт тохирох өнгөний дүрсийг сонгоно уу',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 20.h),

          // Icon grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.85,
              ),
              itemCount: iconOptions.length,
              itemBuilder: (context, index) {
                final option = iconOptions[index];
                final isSelected = currentIconName == option.name;

                return _buildIconOption(option, isSelected);
              },
            ),
          ),

          // Android: icon changes when app is closed
          if (!kIsWeb && Platform.isAndroid)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.deepGreen,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Дүрс солиход аппаа бүрэн хаасны дараа шинэ дүрс харагдана',
                        style: TextStyle(
                          color: AppColors.deepGreen,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 24.h + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildIconOption(AppIconOption option, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => _changeIcon(option),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.deepGreen : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo preview
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.asset(
                        option.imagePath,
                        width: 44.w,
                        height: 44.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 2.w,
                        bottom: 2.h,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.deepGreen,
                            size: 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),

              // Label
              Text(
                option.displayName,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.deepGreen
                      : context.textSecondaryColor,
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the app icon selection sheet
void showAppIconSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const AppIconSelectionSheet(),
  );
}
