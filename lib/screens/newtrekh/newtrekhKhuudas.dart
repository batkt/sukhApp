import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/main.dart' show navigatorKey;

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class Newtrekhkhuudas extends StatefulWidget {
  const Newtrekhkhuudas({super.key});

  @override
  State<Newtrekhkhuudas> createState() => _NewtrekhkhuudasState();
}

class _NewtrekhkhuudasState extends State<Newtrekhkhuudas> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
    _checkBiometricAvailability();
    _checkSavedCredentials();
  }

  @override
  void didUpdateWidget(Newtrekhkhuudas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh biometric status when widget updates
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricService.isAvailable();
    final isEnabled = await StorageService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _checkSavedCredentials() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    final savedPassword = await StorageService.getSavedPasswordForBiometric();
    if (mounted) {
      setState(() {
        _hasSavedCredentials =
            (savedPhone != null && savedPhone.isNotEmpty) &&
            (savedPassword != null && savedPassword.isNotEmpty);
      });
    }
  }

  Future<void> _loadSavedPhoneNumber() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    final rememberMe = await StorageService.isRememberMeEnabled();
    if (savedPhone != null && mounted) {
      setState(() {
        phoneController.text = savedPhone;
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      return;
    }

    // Check if credentials are saved before attempting authentication
    final savedPhone = await StorageService.getSavedPhoneNumber();
    final savedPassword = await StorageService.getSavedPasswordForBiometric();

    if (savedPhone == null || savedPassword == null) {
      // Don't show the button if no credentials, but if somehow triggered, just return silently
      return;
    }

    try {
      // First authenticate with biometric
      final didAuthenticate = await BiometricService.authenticate();
      if (!didAuthenticate || !mounted) {
        return;
      }

      setState(() {
        _isLoading = true;
        phoneController.text = savedPhone;
      });

      try {
        await ApiService.loginUser(utas: savedPhone, nuutsUg: savedPassword);

        if (mounted) {
          final taniltsuulgaKharakhEsekh =
              await StorageService.getTaniltsuulgaKharakhEsekh();

          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: 'Нэвтрэлт амжилттай',
            icon: Icons.check_outlined,
            iconColor: Colors.green,
          );

          final targetRoute = taniltsuulgaKharakhEsekh ? '/ekhniikh' : '/nuur';
          context.go(targetRoute);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _showModalAfterNavigation();
            });
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          if (errorMessage.isEmpty) {
            errorMessage = "Утасны дугаар эсвэл нууц үг буруу байна";
          }

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Биометрийн баталгаажуулалт амжилтгүй',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _showModalAfterNavigation() async {
    // Wait for navigation to complete (page transition is 300ms)
    await Future.delayed(const Duration(milliseconds: 1000));

    // Try multiple times with increasing delays to ensure context is ready
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));

      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        try {
          // Show the modal - it will check storage internally
          showShakeHintModal(navigatorContext);
          return; // Successfully showed modal, exit
        } catch (e) {
          // Continue trying if there's an error
          continue;
        }
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ScreenUtil().screenWidth > 700;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 300.w : double.infinity,
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28.w,
                            vertical: 12.h,
                          ),
                          child: Column(
                            children: [
                              const Spacer(),
                              const AppLogo(),
                              SizedBox(height: 12.h),
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 22.sp,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              // Phone Input Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  autofocus: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Утасны дугаар',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.3),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 16.h,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: AppColors.grayColor.withOpacity(
                                          0.8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: phoneController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear_rounded,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              size: 20.sp,
                                            ),
                                            onPressed: () =>
                                                phoneController.clear(),
                                          )
                                        : null,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(8),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // Password Input Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: passwordController,
                                  keyboardType: TextInputType.number,
                                  obscureText: !_isPasswordVisible,
                                  autofocus: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Нууц код',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.3),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 16.h,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: AppColors.grayColor.withOpacity(
                                          0.8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon:
                                        passwordController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              size: 20.sp,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 4.h,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 20.w,
                                            height: 20.w,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                              border: Border.all(
                                                color: _rememberMe
                                                    ? AppColors.grayColor
                                                    : AppColors.grayColor
                                                          .withOpacity(0.5),
                                                width: 2,
                                              ),
                                              color: _rememberMe
                                                  ? AppColors.grayColor
                                                  : Colors.transparent,
                                            ),
                                            child: _rememberMe
                                                ? Icon(
                                                    Icons.check_rounded,
                                                    size: 14.sp,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(
                                              'Намайг сана',
                                              style: TextStyle(
                                                color: AppColors.grayColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () {
                                        context.push('/nuutsUg');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Нууц код сэргээх',
                                        style: TextStyle(
                                          color: AppColors.grayColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.grayColor
                                              .withOpacity(0.5),
                                          decorationThickness: 1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),
                              // Login Button - New Design
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        String inputPhone = phoneController.text
                                            .trim();
                                        String inputPassword =
                                            passwordController.text.trim();

                                        if (inputPhone.isEmpty ||
                                            inputPassword.isEmpty) {
                                          showGlassSnackBar(
                                            context,
                                            message:
                                                "Утасны дугаар болон нууц үгийг оруулна уу",
                                            icon: Icons.error,
                                            iconColor: Colors.red,
                                          );
                                          return;
                                        } else if (!RegExp(
                                          r'^\d+$',
                                        ).hasMatch(inputPhone)) {
                                          showGlassSnackBar(
                                            context,
                                            message: "Зөвхөн тоо оруулна уу!",
                                            icon: Icons.error,
                                            iconColor: Colors.red,
                                          );
                                          return;
                                        }

                                        setState(() {
                                          _isLoading = true;
                                        });

                                        try {
                                          await ApiService.loginUser(
                                            utas: inputPhone,
                                            nuutsUg: inputPassword,
                                          );

                                          if (mounted) {
                                            if (_rememberMe) {
                                              await StorageService.savePhoneNumber(
                                                inputPhone,
                                              );
                                            } else {
                                              await StorageService.clearSavedPhoneNumber();
                                            }

                                            // Check current biometric enabled state before saving
                                            final currentBiometricEnabled =
                                                await StorageService.isBiometricEnabled();

                                            if (_biometricAvailable &&
                                                currentBiometricEnabled) {
                                              // Only save password if biometric is enabled in settings
                                              await StorageService.savePasswordForBiometric(
                                                inputPassword,
                                              );
                                              // Refresh credentials state after saving
                                              await _checkSavedCredentials();
                                              await _checkBiometricAvailability();
                                            } else {
                                              // Clear biometric data if disabled or not available
                                              await StorageService.clearSavedPasswordForBiometric();
                                              if (!_biometricAvailable) {
                                                await StorageService.setBiometricEnabled(
                                                  false,
                                                );
                                              }
                                              // Refresh credentials state after clearing
                                              await _checkSavedCredentials();
                                              await _checkBiometricAvailability();
                                            }

                                            final taniltsuulgaKharakhEsekh =
                                                await StorageService.getTaniltsuulgaKharakhEsekh();

                                            setState(() {
                                              _isLoading = false;
                                            });
                                            showGlassSnackBar(
                                              context,
                                              message: 'Нэвтрэлт амжилттай',
                                              icon: Icons.check_outlined,
                                              iconColor: Colors.green,
                                            );

                                            final targetRoute =
                                                taniltsuulgaKharakhEsekh
                                                ? '/ekhniikh'
                                                : '/nuur';

                                            context.go(targetRoute);

                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  Future.delayed(
                                                    const Duration(
                                                      milliseconds: 800,
                                                    ),
                                                    () {
                                                      _showModalAfterNavigation();
                                                    },
                                                  );
                                                });
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            setState(() {
                                              _isLoading = false;
                                            });

                                            String errorMessage = e.toString();
                                            if (errorMessage.startsWith(
                                              'Exception: ',
                                            )) {
                                              errorMessage = errorMessage
                                                  .substring(11);
                                            }
                                            if (errorMessage.isEmpty) {
                                              errorMessage =
                                                  "Утасны дугаар эсвэл нууц үг буруу байна";
                                            }

                                            showGlassSnackBar(
                                              context,
                                              message: errorMessage,
                                              icon: Icons.error,
                                              iconColor: Colors.red,
                                            );
                                          }
                                        }
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCAD2DB),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: _isLoading
                                      ? Center(
                                          child: SizedBox(
                                            height: 20.h,
                                            width: 20.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.black),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Нэвтрэх',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              // Register Button - New Design
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        context.push('/burtguulekh_neg');
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 11.5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          border: Border.all(
                                            color: AppColors.grayColor
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Text(
                                          'Бүртгүүлэх',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.grayColor,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_biometricAvailable &&
                                      _biometricEnabled &&
                                      _hasSavedCredentials) ...[
                                    SizedBox(width: 12.w),
                                    GestureDetector(
                                      onTap: (_isLoading || !_biometricEnabled)
                                          ? null
                                          : _authenticateWithBiometric,
                                      child: Opacity(
                                        opacity: _biometricEnabled ? 1.0 : 0.5,
                                        child: Container(
                                          width: 56.w,
                                          height: 48.w,
                                          decoration: BoxDecoration(
                                            color: AppColors.inputGrayColor
                                                .withOpacity(0.3),
                                            border: Border.all(
                                              color: _biometricEnabled
                                                  ? AppColors.grayColor
                                                        .withOpacity(0.5)
                                                  : Colors.white.withOpacity(
                                                      0.2,
                                                    ),
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Image.asset(
                                            'lib/assets/img/face-id.png',
                                            width: 22.w,
                                            height: 22.w,
                                            color: _biometricEnabled
                                                ? AppColors.grayColor
                                                : Colors.white.withOpacity(0.3),
                                            colorBlendMode: BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '© 2025 Powered by Zevtabs LLC',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Version 1.0',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
