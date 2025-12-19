import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

/// Standard AppBar for all pages - matches ebarimt page style
AppBar buildStandardAppBar(
  BuildContext context, {
  required String title,
  VoidCallback? onBackPressed,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  final isDark = context.isDarkMode;
  return AppBar(
    backgroundColor: AppColors.getDeepGreen(isDark),
    toolbarHeight: context.responsiveSpacing(
      small: 70,
      medium: 75,
      large: 80,
      tablet: 85,
      veryNarrow: 60,
    ),
    leading: automaticallyImplyLeading
        ? IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: context.responsiveIconSize(
                small: 28,
                medium: 30,
                large: 32,
                tablet: 34,
                veryNarrow: 24,
              ),
            ),
            onPressed: onBackPressed ?? () => context.pop(),
          )
        : null,
    title: Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsiveFontSize(
          small: 18,
          medium: 20,
          large: 22,
          tablet: 24,
          veryNarrow: 16,
        ),
        fontWeight: FontWeight.w600,
      ),
    ),
    centerTitle: true,
    elevation: 0,
    actions: actions,
  );
}
