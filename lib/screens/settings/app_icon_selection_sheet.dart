import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class AppIconOption {
  final String name;
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData previewIcon;

  const AppIconOption({
    required this.name,
    required this.displayName,
    required this.primaryColor,
    required this.secondaryColor,
    this.previewIcon = Icons.home_rounded,
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

  // Define available icon variants
  static const List<AppIconOption> iconOptions = [
    AppIconOption(
      name: 'default',
      displayName: 'Үндсэн',
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF4CAF50),
    ),
    AppIconOption(
      name: 'blue',
      displayName: 'Цэнхэр',
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFF42A5F5),
    ),
    AppIconOption(
      name: 'purple',
      displayName: 'Ягаан',
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFAB47BC),
    ),
    AppIconOption(
      name: 'orange',
      displayName: 'Улбар шар',
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFFF9800),
    ),
    AppIconOption(
      name: 'red',
      displayName: 'Улаан',
      primaryColor: Color(0xFFC62828),
      secondaryColor: Color(0xFFEF5350),
    ),
    AppIconOption(
      name: 'teal',
      displayName: 'Ногоон цэнхэр',
      primaryColor: Color(0xFF00695C),
      secondaryColor: Color(0xFF26A69A),
    ),
    AppIconOption(
      name: 'dark',
      displayName: 'Хар',
      primaryColor: Color(0xFF212121),
      secondaryColor: Color(0xFF424242),
    ),
    AppIconOption(
      name: 'gold',
      displayName: 'Алтан',
      primaryColor: Color(0xFFFF8F00),
      secondaryColor: Color(0xFFFFD54F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<bool> _isPhysicalDevice() async {
    if (!kIsWeb && Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.isPhysicalDevice;
    }
    return true;
  }

  Future<void> _loadCurrentIcon() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final iconName = await FlutterDynamicIconPlus.alternateIconName;
        setState(() {
          currentIconName = iconName ?? 'default';
        });
      } else {
        // For Android or Web, load from shared preferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          currentIconName = prefs.getString('app_icon') ?? 'default';
        });
      }
    } catch (e) {
      setState(() {
        currentIconName = 'default';
      });
    }
  }

  Future<void> _changeIcon(AppIconOption option) async {
    if (currentIconName == option.name) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (!kIsWeb && Platform.isIOS) {
        // Check if running on simulator (dynamic icons don't work on simulator)
        final isSimulator = !await _isPhysicalDevice();
        if (isSimulator) {
          // Just save preference, don't try to change icon on simulator
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_icon', option.name);
          
          setState(() {
            currentIconName = option.name;
            isLoading = false;
          });
          
          if (mounted) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Симулятор дээр дүрс солих боломжгүй. Бодит төхөөрөмж дээр туршина уу.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
          return;
        }
        
        if (option.name == 'default') {
          await FlutterDynamicIconPlus.setAlternateIconName(iconName: null);
        } else {
          await FlutterDynamicIconPlus.setAlternateIconName(iconName: option.name);
        }
      }

      // Save to shared preferences for platforms
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_icon', option.name);

      setState(() {
        currentIconName = option.name;
        isLoading = false;
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Апп дүрс "${option.displayName}" болж өөрчлөгдлөө'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Дүрс солиход алдаа гарлаа: ${e.message ?? e.code}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('PlatformException changing icon: ${e.code} - ${e.message}');
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
                crossAxisCount: 4,
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

          SizedBox(height: 24.h),

          // Note for iOS
          if (!kIsWeb && Platform.isIOS)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
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
                        'Дүрс солиход iOS системийн мэдэгдэл гарч болно',
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
              color: isSelected ? option.primaryColor : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon preview
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [option.primaryColor, option.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: option.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 28.sp,
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
                            color: option.primaryColor,
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
                      ? option.primaryColor
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
