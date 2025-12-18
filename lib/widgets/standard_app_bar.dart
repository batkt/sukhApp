import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

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
    leading: automaticallyImplyLeading
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackPressed ?? () => context.pop(),
          )
        : null,
    title: Text(title, style: const TextStyle(color: Colors.white)),
    centerTitle: true,
    elevation: 0,
    actions: actions,
  );
}
