import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class BiometricOnboardingScreen extends StatefulWidget {
  const BiometricOnboardingScreen({super.key});

  @override
  State<BiometricOnboardingScreen> createState() =>
      _BiometricOnboardingScreenState();
}

class _BiometricOnboardingScreenState extends State<BiometricOnboardingScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricService.isAvailable();
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
      });
    }
  }

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    // Save biometric preference
    await StorageService.setBiometricEnabled(_biometricEnabled);

    // If disabled, clear any saved biometric data
    if (!_biometricEnabled) {
      await StorageService.clearSavedPasswordForBiometric();
    }

    // Mark that user has seen biometric onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenBiometricOnboarding', true);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      context.go('/nuur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grayColor.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.grayColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Platform.isIOS
                      ? CustomPaint(
                          painter: FaceIdIconPainter(
                            color: AppColors.grayColor,
                          ),
                          size: Size(60.w, 60.w),
                        )
                      : Icon(
                          Icons.fingerprint_rounded,
                          size: 60.sp,
                          color: AppColors.grayColor,
                        ),
                ),
                SizedBox(height: 32.h),

                // Title
                Text(
                  'Биометрийн баталгаажуулалт',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),

                // Description
                Text(
                  Platform.isIOS
                      ? 'Face ID ашиглан хурдан, аюулгүй нэвтрэх боломжтой'
                      : 'Хурууны хээ ашиглан хурдан, аюулгүй нэвтрэх боломжтой',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),

                // Biometric Toggle Card
                if (_biometricAvailable)
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _biometricEnabled
                            ? AppColors.grayColor.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Биометрийн баталгаажуулалт идэвхжүүлэх',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                Platform.isIOS
                                    ? 'Face ID ашиглан нэвтрэх'
                                    : 'Хурууны хээ ашиглан нэвтрэх',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _biometricEnabled = !_biometricEnabled;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              color: _biometricEnabled
                                  ? AppColors.grayColor
                                  : Colors.white.withOpacity(0.3),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  left: _biometricEnabled ? 26.w : 4.w,
                                  top: 4.h,
                                  child: Container(
                                    width: 24.w,
                                    height: 24.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 24.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            'Таны төхөөрөмж дээр биометрийн баталгаажуулалт боломжгүй байна',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            'Үргэлжлүүлэх',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
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

/// Custom painter for iOS Face ID icon
class FaceIdIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  FaceIdIconPainter({required this.color, this.strokeWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final faceWidth = size.width * 0.5;
    final faceHeight = size.height * 0.5;

    // Draw corner frame segments
    final cornerLength = size.width * 0.25;
    final cornerThickness = strokeWidth * 1.5;

    // Top-left corner
    final topLeftPath = Path()
      ..moveTo(centerX - faceWidth / 2, centerY - faceHeight / 2 - cornerLength)
      ..lineTo(centerX - faceWidth / 2, centerY - faceHeight / 2)
      ..lineTo(
        centerX - faceWidth / 2 - cornerLength,
        centerY - faceHeight / 2,
      );
    canvas.drawPath(topLeftPath, paint..strokeWidth = cornerThickness);

    // Top-right corner
    final topRightPath = Path()
      ..moveTo(centerX + faceWidth / 2, centerY - faceHeight / 2 - cornerLength)
      ..lineTo(centerX + faceWidth / 2, centerY - faceHeight / 2)
      ..lineTo(
        centerX + faceWidth / 2 + cornerLength,
        centerY - faceHeight / 2,
      );
    canvas.drawPath(topRightPath, paint..strokeWidth = cornerThickness);

    // Bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(centerX - faceWidth / 2, centerY + faceHeight / 2 + cornerLength)
      ..lineTo(centerX - faceWidth / 2, centerY + faceHeight / 2)
      ..lineTo(
        centerX - faceWidth / 2 - cornerLength,
        centerY + faceHeight / 2,
      );
    canvas.drawPath(bottomLeftPath, paint..strokeWidth = cornerThickness);

    // Bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(centerX + faceWidth / 2, centerY + faceHeight / 2 + cornerLength)
      ..lineTo(centerX + faceWidth / 2, centerY + faceHeight / 2)
      ..lineTo(
        centerX + faceWidth / 2 + cornerLength,
        centerY + faceHeight / 2,
      );
    canvas.drawPath(bottomRightPath, paint..strokeWidth = cornerThickness);

    // Draw face features
    final facePaint = paint..strokeWidth = strokeWidth;

    // Left eye (vertical oval)
    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - faceWidth * 0.2, centerY - faceHeight * 0.15),
        width: faceWidth * 0.15,
        height: faceWidth * 0.2,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(leftEyeRect, facePaint);

    // Right eye (vertical oval)
    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + faceWidth * 0.2, centerY - faceHeight * 0.15),
        width: faceWidth * 0.15,
        height: faceWidth * 0.2,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(rightEyeRect, facePaint);

    // Nose (vertical oval, slightly offset to left)
    final noseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - faceWidth * 0.05, centerY),
        width: faceWidth * 0.12,
        height: faceWidth * 0.25,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(noseRect, facePaint);

    // Smile (upward-curving arc)
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + faceHeight * 0.1),
        width: faceWidth * 0.6,
        height: faceHeight * 0.4,
      ),
      -0.3,
      0.6,
    );
    canvas.drawPath(smilePath, facePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
