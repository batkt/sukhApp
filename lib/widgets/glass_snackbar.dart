import 'package:flutter/material.dart';
import 'package:sukh_app/widgets/app_toast.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/error_message.dart';

void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info,
  Color textColor = Colors.white,
  Color iconColor = Colors.white,
  double opacity = 0.1,
  double blur = 10, // kept for API compatibility (ignored)
  Duration duration = const Duration(milliseconds: 1500),
}) {
  final isError = icon == Icons.error ||
      icon == Icons.error_outline ||
      icon == Icons.error_outline_rounded ||
      icon == Icons.warning ||
      icon == Icons.warning_amber_rounded;
  // Алдааны мэдэгдлээс техникийн текстийг (Exception:, SocketException, 500 г.м.)
  // ойлгомжтой тайлбар болгоно.
  final cleanMessage = isError
      ? cleanErrorText(message)
      : message.replaceAll("Exception: ", "");
  // Алдааг уншиж амжихаар арай удаан харуулна
  final effectiveDuration =
      isError && duration == const Duration(milliseconds: 1500)
          ? const Duration(milliseconds: 3500)
          : duration;

  // Determine the best icon color if it's default white
  Color? finalColor = iconColor;
  if (iconColor == Colors.white) {
    if (icon == Icons.error || icon == Icons.error_outline) {
      finalColor = AppColors.error;
    } else if (icon == Icons.check_circle || icon == Icons.check) {
      finalColor = AppColors.success;
    } else {
      finalColor = AppColors.deepGreen;
    }
  }

  AppToast.show(
    context,
    cleanMessage,
    icon: icon,
    color: finalColor,
    duration: effectiveDuration,
  );
}
