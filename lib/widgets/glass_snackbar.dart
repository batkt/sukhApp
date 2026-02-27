import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info,
  Color textColor = Colors.white,
  Color iconColor = Colors.white,
  double opacity = 0.1,
  double blur = 10, // kept for API compatibility (ignored)
  Duration duration = const Duration(seconds: 3),
}) {
  final cleanMessage = message.replaceAll("Exception: ", "");

  final isError = iconColor == Colors.red;
  final isSuccess = iconColor == Colors.green;

  Widget snackBarWidget;

  if (isError) {
    snackBarWidget = CustomSnackBar.error(
      message: cleanMessage,
      icon: Icon(icon, color: const Color(0x15000000), size: 120),
      backgroundColor: Colors.redAccent,
      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
    );
  } else if (isSuccess) {
    snackBarWidget = CustomSnackBar.success(
      message: cleanMessage,
      icon: Icon(icon, color: const Color(0x15000000), size: 120),
      backgroundColor: Colors.green,
      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
    );
  } else {
    snackBarWidget = CustomSnackBar.info(
      message: cleanMessage,
      icon: Icon(icon, color: const Color(0x15000000), size: 120),
      backgroundColor: Colors.black87,
      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  showTopSnackBar(
    Overlay.of(context),
    snackBarWidget,
    displayDuration: duration,
  );
}
