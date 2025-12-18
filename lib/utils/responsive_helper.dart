import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive helper utility for handling different screen sizes
class ResponsiveHelper {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is tablet (>= 600px width)
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// Check if device is large tablet (>= 900px width)
  static bool isLargeTablet(BuildContext context) {
    return screenWidth(context) >= 900;
  }

  /// Check if device is foldable or very wide (>= 840px width)
  static bool isFoldable(BuildContext context) {
    return screenWidth(context) >= 840;
  }

  /// Check if device is small phone (< 360px width)
  static bool isSmallPhone(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Check if device is medium phone (360-600px width)
  static bool isMediumPhone(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// Get responsive padding based on device type
  static EdgeInsets getPadding(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);
    double padding;

    if (width >= 900 && tablet != null) {
      padding = tablet;
    } else if (width >= 600 && large != null) {
      padding = large;
    } else if (width >= 400 && medium != null) {
      padding = medium;
    } else {
      padding = small ?? 16.0;
    }

    return EdgeInsets.all(padding.w);
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);
    double padding;

    if (width >= 900 && tablet != null) {
      padding = tablet;
    } else if (width >= 600 && large != null) {
      padding = large;
    } else if (width >= 400 && medium != null) {
      padding = medium;
    } else {
      padding = small ?? 20.0;
    }

    return EdgeInsets.symmetric(horizontal: padding.w);
  }

  /// Get responsive vertical padding
  static EdgeInsets getVerticalPadding(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);
    double padding;

    if (width >= 900 && tablet != null) {
      padding = tablet;
    } else if (width >= 600 && large != null) {
      padding = large;
    } else if (width >= 400 && medium != null) {
      padding = medium;
    } else {
      padding = small ?? 16.0;
    }

    return EdgeInsets.symmetric(vertical: padding.h);
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);

    if (width >= 900 && tablet != null) {
      return tablet.sp;
    } else if (width >= 600 && large != null) {
      return large.sp;
    } else if (width >= 400 && medium != null) {
      return medium.sp;
    } else {
      return small.sp;
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);

    if (width >= 900 && tablet != null) {
      return tablet.h;
    } else if (width >= 600 && large != null) {
      return large.h;
    } else if (width >= 400 && medium != null) {
      return medium.h;
    } else {
      return small.h;
    }
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);

    if (width >= 900 && tablet != null) {
      return tablet.r;
    } else if (width >= 600 && large != null) {
      return large.r;
    } else if (width >= 400 && medium != null) {
      return medium.r;
    } else {
      return small.r;
    }
  }

  /// Get max content width for tablets/desktops
  static double getMaxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) {
      return 800.w;
    } else if (width >= 900) {
      return 700.w;
    } else if (width >= 600) {
      return 600.w;
    } else {
      return double.infinity;
    }
  }

  /// Get responsive modal height (for bottom sheets)
  static double getModalHeight(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final height = screenHeight(context);
    final width = screenWidth(context);
    
    // For tablets and foldables, use percentage of screen height
    if (width >= 900 && tablet != null) {
      return height * tablet;
    } else if (width >= 600 && large != null) {
      return height * large;
    } else if (width >= 400 && medium != null) {
      return height * medium;
    } else {
      return height * (small ?? 0.9);
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = screenWidth(context);

    if (width >= 900 && tablet != null) {
      return tablet.sp;
    } else if (width >= 600 && large != null) {
      return large.sp;
    } else if (width >= 400 && medium != null) {
      return medium.sp;
    } else {
      return small.sp;
    }
  }
}

/// Extension on BuildContext for easier access
extension ResponsiveExtension on BuildContext {
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isLargeTablet => ResponsiveHelper.isLargeTablet(this);
  bool get isFoldable => ResponsiveHelper.isFoldable(this);
  bool get isSmallPhone => ResponsiveHelper.isSmallPhone(this);
  bool get isMediumPhone => ResponsiveHelper.isMediumPhone(this);
  
  double get screenWidth => ResponsiveHelper.screenWidth(this);
  double get screenHeight => ResponsiveHelper.screenHeight(this);
  
  EdgeInsets responsivePadding({
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getPadding(this, small: small, medium: medium, large: large, tablet: tablet);
  
  EdgeInsets responsiveHorizontalPadding({
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getHorizontalPadding(this, small: small, medium: medium, large: large, tablet: tablet);
  
  EdgeInsets responsiveVerticalPadding({
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getVerticalPadding(this, small: small, medium: medium, large: large, tablet: tablet);
  
  double responsiveFontSize({
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getFontSize(this, small: small, medium: medium, large: large, tablet: tablet);
  
  double responsiveSpacing({
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getSpacing(this, small: small, medium: medium, large: large, tablet: tablet);
  
  double responsiveBorderRadius({
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getBorderRadius(this, small: small, medium: medium, large: large, tablet: tablet);
  
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  
  double responsiveModalHeight({
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getModalHeight(this, small: small, medium: medium, large: large, tablet: tablet);
  
  double responsiveIconSize({
    required double small,
    double? medium,
    double? large,
    double? tablet,
  }) => ResponsiveHelper.getIconSize(this, small: small, medium: medium, large: large, tablet: tablet);
}

