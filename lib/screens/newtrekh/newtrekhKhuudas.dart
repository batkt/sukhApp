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
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
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
    if (!_biometricAvailable) {
      return;
    }

    try {
      // First authenticate with biometric
      final didAuthenticate = await BiometricService.authenticate();
      if (!didAuthenticate || !mounted) {
        return;
      }

      // Get saved credentials
      final savedPhone = await StorageService.getSavedPhoneNumber();
      final savedPassword = await StorageService.getSavedPasswordForBiometric();

      // If no saved credentials, show message to login first
      if (savedPhone == null || savedPassword == null) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Эхлээд нэвтрэх шаардлагатай',
            icon: Icons.info,
            iconColor: Colors.orange,
          );
        }
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
                              Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: _biometricAvailable ? 62.w : 0,
                                    ),
                                    child: Column(
                                      children: [
                                        // Login Button
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFCAD2DB,
                                                ).withOpacity(0.4),
                                                offset: const Offset(0, 6),
                                                blurRadius: 12,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              onTap: _isLoading
                                                  ? null
                                                  : () async {
                                                      String inputPhone =
                                                          phoneController.text
                                                              .trim();
                                                      String inputPassword =
                                                          passwordController
                                                              .text
                                                              .trim();

                                                      if (inputPhone.isEmpty ||
                                                          inputPassword
                                                              .isEmpty) {
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
                                                          message:
                                                              "Зөвхөн тоо оруулна уу!",
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
                                                          nuutsUg:
                                                              inputPassword,
                                                        );

                                                        if (mounted) {
                                                          // Save or clear phone number based on remember me checkbox
                                                          if (_rememberMe) {
                                                            await StorageService.savePhoneNumber(
                                                              inputPhone,
                                                            );
                                                          } else {
                                                            await StorageService.clearSavedPhoneNumber();
                                                          }

                                                          // Always save password for biometric if biometric is available (regardless of remember me)
                                                          if (_biometricAvailable) {
                                                            await StorageService.savePasswordForBiometric(
                                                              inputPassword,
                                                            );
                                                            await StorageService.setBiometricEnabled(
                                                              true,
                                                            );
                                                          } else {
                                                            // Clear biometric data if biometric is not available
                                                            await StorageService.clearSavedPasswordForBiometric();
                                                            await StorageService.setBiometricEnabled(
                                                              false,
                                                            );
                                                          }

                                                          // Check if we should show onboarding
                                                          final taniltsuulgaKharakhEsekh =
                                                              await StorageService.getTaniltsuulgaKharakhEsekh();

                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                          showGlassSnackBar(
                                                            context,
                                                            message:
                                                                'Нэвтрэлт амжилттай',
                                                            icon: Icons
                                                                .check_outlined,
                                                            iconColor:
                                                                Colors.green,
                                                          );

                                                          // Navigate to onboarding if taniltsuulgaKharakhEsekh is true, otherwise go to home
                                                          final targetRoute =
                                                              taniltsuulgaKharakhEsekh
                                                              ? '/ekhniikh'
                                                              : '/nuur';

                                                          // Navigate and wait for it to complete
                                                          context.go(
                                                            targetRoute,
                                                          );

                                                          // Show shake hint modal after navigation
                                                          // Use WidgetsBinding to ensure we're in the next frame
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback((
                                                                _,
                                                              ) {
                                                                Future.delayed(
                                                                  const Duration(
                                                                    milliseconds:
                                                                        800,
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

                                                          // Extract the error message from the exception
                                                          String errorMessage =
                                                              e.toString();

                                                          // Remove "Exception: " prefix if it exists
                                                          if (errorMessage
                                                              .startsWith(
                                                                'Exception: ',
                                                              )) {
                                                            errorMessage =
                                                                errorMessage
                                                                    .substring(
                                                                      11,
                                                                    );
                                                          }

                                                          // If it's still empty, use default
                                                          if (errorMessage
                                                              .isEmpty) {
                                                            errorMessage =
                                                                "Утасны дугаар эсвэл нууц үг буруу байна";
                                                          }

                                                          showGlassSnackBar(
                                                            context,
                                                            message:
                                                                errorMessage,
                                                            icon: Icons.error,
                                                            iconColor:
                                                                Colors.red,
                                                          );
                                                        }
                                                      }
                                                    },
                                              splashColor: Colors.white
                                                  .withOpacity(0.2),
                                              highlightColor: Colors.white
                                                  .withOpacity(0.1),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 16.h,
                                                  horizontal: 20.w,
                                                ),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  gradient: _isLoading
                                                      ? null
                                                      : LinearGradient(
                                                          colors: [
                                                            const Color(
                                                              0xFFCAD2DB,
                                                            ),
                                                            const Color(
                                                              0xFFCAD2DB,
                                                            ).withOpacity(0.9),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                  color: _isLoading
                                                      ? const Color(
                                                          0xFFCAD2DB,
                                                        ).withOpacity(0.7)
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                ),
                                                child: _isLoading
                                                    ? SizedBox(
                                                        height: 20.h,
                                                        width: 20.w,
                                                        child: const CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.black),
                                                        ),
                                                      )
                                                    : Text(
                                                        'Нэвтрэх',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        // Register Button
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: const Offset(0, 4),
                                                blurRadius: 12,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              onTap: () {
                                                context.push(
                                                  '/burtguulekh_neg',
                                                );
                                              },
                                              splashColor: Colors.white
                                                  .withOpacity(0.2),
                                              highlightColor: Colors.white
                                                  .withOpacity(0.1),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 16.h,
                                                  horizontal: 20.w,
                                                ),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .inputGrayColor
                                                      .withOpacity(0.4),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Бүртгүүлэх',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Biometric authentication button - circular shape
                                  if (_biometricAvailable)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.grayColor
                                                    .withOpacity(0.3),
                                                offset: const Offset(0, 4),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: _isLoading
                                                  ? null
                                                  : _authenticateWithBiometric,
                                              splashColor: AppColors.grayColor
                                                  .withOpacity(0.2),
                                              highlightColor: AppColors
                                                  .grayColor
                                                  .withOpacity(0.1),
                                              child: Container(
                                                width: 56.w,
                                                height: 56.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors.grayColor
                                                        .withOpacity(0.6),
                                                    width: 2,
                                                  ),
                                                  color: AppColors
                                                      .inputGrayColor
                                                      .withOpacity(0.2),
                                                ),
                                                child: Icon(
                                                  Platform.isIOS
                                                      ? Icons.face_rounded
                                                      : Icons
                                                            .fingerprint_rounded,
                                                  size: 28.sp,
                                                  color: AppColors.grayColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
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
