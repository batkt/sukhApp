import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sukh_app/constants/constants.dart';

class BillerUtils {
  /// Transform biller name (e.g., Юнивижн -> Юнивишн)
  static String transformBillerName(String name) {
    if (name.contains('Юнивижн')) {
      return name.replaceAll('Юнивижн', 'Юнивишн');
    }
    // Transform ЦАХИЛГААН to Цахилгаан (capitalize first letter only)
    final nameLower = name.toLowerCase();
    if (nameLower.contains('цахилгаан') ||
        nameLower.contains('tsakhilgaan') ||
        nameLower.contains('tukh')) {
      return 'Цахилгаан';
    }
    return name;
  }

  /// Build logo or icon for biller
  static Widget buildBillerLogo(String billerName, {String? transformedName}) {
    // Check both raw and transformed names
    final namesToCheck = [billerName];
    if (transformedName != null && transformedName != billerName) {
      namesToCheck.add(transformedName);
    }

    for (final name in namesToCheck) {
      final nameLower = name.toLowerCase().trim();

      // Check if it's Төрийн банк and use state.png
      // if (nameLower.contains('төрийн банк') ||
      //     nameLower.contains('toriin bank') ||
      //     nameLower.contains('state bank')) {
      //   return Image.asset(
      //     'lib/assets/img/state.png',
      //     width: double.infinity,
      //     height: double.infinity,
      //     fit: BoxFit.contain,
      //   );
      // }

      // // Check if it's Юнивишн/Юнивижн and use uni.svg
      // if (nameLower.contains('юнивишн') ||
      //     nameLower.contains('юнивижн') ||
      //     nameLower.contains('univision') ||
      //     nameLower.contains('univishn')) {
      //   return SvgPicture.asset(
      //     'lib/assets/img/uni.svg',
      //     width: double.infinity,
      //     height: double.infinity,
      //     fit: BoxFit.contain,
      //     placeholderBuilder: (BuildContext context) => Icon(
      //       Icons.receipt_long_rounded,
      //       color: AppColors.secondaryAccent,
      //       size: 24.sp,
      //     ),
      //   );
      // }

      // // Check if it's Скаймедиа and use logo-skymedia-blue.svg
      // if (nameLower.contains('скаймедиа') ||
      //     nameLower.contains('скай медиа') ||
      //     nameLower.contains('скай-медиа') ||
      //     nameLower.contains('skymedia') ||
      //     nameLower.contains('sky media') ||
      //     nameLower.contains('sky-media') ||
      //     (nameLower.contains('скай') && nameLower.contains('медиа'))) {
      //   return SvgPicture.asset(
      //     'lib/assets/img/logo-skymedia-blue.svg',
      //     width: double.infinity,
      //     height: double.infinity,
      //     fit: BoxFit.contain,
      //     placeholderBuilder: (BuildContext context) => Icon(
      //       Icons.receipt_long_rounded,
      //       color: AppColors.secondaryAccent,
      //       size: 24.sp,
      //     ),
      //   );
      // }

      // Check if it's ЦАХИЛГААН and use tukh.png
      if (nameLower.contains('цахилгаан') ||
          nameLower.contains('tsakhilgaan') ||
          nameLower.contains('tukh') ||
          nameLower.contains('тух')) {
        return Image.asset(
          'lib/assets/img/tukh.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        );
      }
    }

    // Default icon for other billers
    return Icon(
      Icons.receipt_long_rounded,
      color: AppColors.secondaryAccent,
      size: 24.sp,
    );
  }
}
