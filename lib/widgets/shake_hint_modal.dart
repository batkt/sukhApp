import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/storage_service.dart';

/// Show shake hint modal dialog (similar to tutorial overlay)
/// [forceShow] - If true, shows modal even if it was shown before
Future<void> showShakeHintModal(
  BuildContext context, {
  bool forceShow = false,
}) async {
  // Check if already shown (unless forced)
  if (!forceShow) {
    final hasBeenShown = await StorageService.hasShakeHintBeenShown();
    if (hasBeenShown) {
      // Already shown, don't show again
      return;
    }
  }

  // Ensure we have a valid context
  if (!context.mounted) {
    return;
  }

  // Use rootNavigator to ensure modal shows on top
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.75), // Less transparent background
    transitionDuration: const Duration(milliseconds: 400), // Smooth in
    useRootNavigator: true, // Ensure it shows on top of everything
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _ShakeHintModal();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Very smooth fade and scale animation
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeIn),
        ),
      );

      final scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      );
    },
  );
}

class _ShakeHintModal extends StatefulWidget {
  const _ShakeHintModal({Key? key}) : super(key: key);

  @override
  State<_ShakeHintModal> createState() => _ShakeHintModalState();
}

class _ShakeHintModalState extends State<_ShakeHintModal>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Shake animation (phone wiggling) - smoother
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Rotation animation for phone (tilting left and right)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Horizontal shake movement
    _shakeAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOutCubic),
    );

    // Rotation animation (tilting phone left and right)
    _pulseAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    // Mark as shown in storage
    await StorageService.setShakeHintShown(true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: Colors.transparent, // Transparent background
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phone icon with shake and rotation animation - TOP
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _shakeAnimation,
                    _pulseAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: Transform.rotate(
                        angle: _pulseAnimation.value,
                        child: Icon(
                          Icons.phone_iphone,
                          size: 100.sp,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 50.h),

                // Main text - BELOW animation (wrapped)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Утсаа сэгсрээд асуудлаа шалгуулах',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                  ),
                ),
                SizedBox(height: 24.h),

                // Subtitle text (wrapped)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Хэрвээ танд тусламж хэрэгтэй бол утсаа сэгсрэхэд л болно',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                  ),
                ),

                SizedBox(height: 50.h),

                // Done button - smaller like in image
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1a1a2e),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Дуусгах',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
