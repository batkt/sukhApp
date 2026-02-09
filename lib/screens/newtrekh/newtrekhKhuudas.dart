import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/main.dart' show navigatorKey;
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/services/biometric_service.dart';

/// Modern minimal background with subtle gradient
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8FAFB),
      ),
      child: Stack(
        children: [
          // Subtle decorative circles for visual interest
          Positioned(
            top: -100.h,
            right: -80.w,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.deepGreen.withOpacity(0.15),
                          AppColors.deepGreen.withOpacity(0.0),
                        ]
                      : [
                          AppColors.deepGreen.withOpacity(0.08),
                          AppColors.deepGreen.withOpacity(0.0),
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120.h,
            left: -100.w,
            child: Container(
              width: 320.w,
              height: 320.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.deepGreenAccent.withOpacity(0.1),
                          AppColors.deepGreenAccent.withOpacity(0.0),
                        ]
                      : [
                          AppColors.deepGreenAccent.withOpacity(0.06),
                          AppColors.deepGreenAccent.withOpacity(0.0),
                        ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
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
  final TextEditingController emailController = TextEditingController();

  bool _isLoading = false;
  bool _showEmailField = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
    _checkBiometricStatus();
  }

  Future<void> _loadSavedPhoneNumber() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    if (savedPhone != null && mounted) {
      setState(() {
        phoneController.text = savedPhone;
      });
    }
  }

  Future<void> _checkBiometricStatus() async {
    final isAvailable = await BiometricService.isAvailable();
    print('🔐 [BIOMETRIC] Available: $isAvailable');
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricAvailable) {
      showGlassSnackBar(
        context,
        message: 'Биометрийн баталгаажуулалт боломжгүй байна',
        icon: Icons.error,
        iconColor: Colors.orange,
      );
      return;
    }

    // Get saved phone and password
    final savedPhone = await StorageService.getSavedPhoneNumber();
    final savedPassword = await StorageService.getSavedPasswordForBiometric();

    // If no saved credentials, we can't use biometric login
    if (savedPhone == null || savedPassword == null) {
      // Check if user is currently logged in
      final isLoggedIn = await StorageService.isLoggedIn();

      if (!isLoggedIn) {
        // User not logged in - need to login first to set up biometric
        showGlassSnackBar(
          context,
          message: 'Эхлээд нэвтэрч, биометрийн мэдээлэл хадгалах шаардлагатай',
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
        return;
      }

      // User is logged in but biometric not set up
      // This shouldn't happen if setup was done after login, but handle it
      showGlassSnackBar(
        context,
        message:
            'Биометрийн мэдээлэл олдсонгүй. Тохиргооноос биометрийн нэвтрэлтийг идэвхжүүлнэ үү',
        icon: Icons.error,
        iconColor: Colors.orange,
      );
      return;
    }

    // Authenticate with biometric
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      return; // User cancelled or authentication failed
    }

    // Set phone and password in controllers
    setState(() {
      phoneController.text = savedPhone;
      passwordController.text = savedPassword;
      _isLoading = true;
    });

    // Perform login with saved credentials
    try {
      // Get saved address to send with login
      var savedBairId = await StorageService.getWalletBairId();
      var savedDoorNo = await StorageService.getWalletDoorNo();

      // Get OWN_ORG IDs if address is OWN_ORG type
      final savedBaiguullagiinId =
          await StorageService.getWalletBairBaiguullagiinId();
      final savedBarilgiinId = await StorageService.getWalletBairBarilgiinId();
      final savedSource = await StorageService.getWalletBairSource();

      final isOwnOrg =
          savedSource == 'OWN_ORG' &&
          savedBaiguullagiinId != null &&
          savedBarilgiinId != null;

      // Perform login
      final loginResponse = await ApiService.loginUser(
        utas: savedPhone,
        nuutsUg: savedPassword,
        bairId: savedBairId,
        doorNo: savedDoorNo,
        baiguullagiinId: isOwnOrg ? savedBaiguullagiinId : null,
        barilgiinId: isOwnOrg ? savedBarilgiinId : null,
      );

      // Normalize user payload
      final userDataDynamic =
          loginResponse['result'] ?? loginResponse['orshinSuugch'];
      final userData = userDataDynamic is Map<String, dynamic>
          ? userDataDynamic
          : null;

      // Verify token was saved
      final tokenSaved = await StorageService.isLoggedIn();
      if (!tokenSaved) {
        throw Exception('Токен хадгалахад алдаа гарлаа. Дахин оролдоно уу.');
      }

      if (mounted) {
        await StorageService.savePhoneNumber(savedPhone);

        // Check if user needs OTP verification
        final loginOrgId = userData?['baiguullagiinId']?.toString();
        final hasBaiguullagiinId =
            loginOrgId != null &&
            loginOrgId.trim().isNotEmpty &&
            loginOrgId.trim().toLowerCase() != 'null';

        // TODO: Re-enable phone verification later
        // if (hasBaiguullagiinId) {
        //   final needsVerification =
        //       await StorageService.needsPhoneVerification();
        //   if (needsVerification) {
        //     final verificationResult = await context.push<bool>(
        //       '/phone_verification',
        //       extra: {
        //         'phoneNumber': savedPhone,
        //         'baiguullagiinId': loginOrgId,
        //         'duureg': userData?['duureg']?.toString(),
        //         'horoo': userData?['horoo']?.toString(),
        //         'soh': userData?['soh']?.toString(),
        //       },
        //     );
        //
        //     if (verificationResult != true) {
        //       await SessionService.logout();
        //       setState(() {
        //         _isLoading = false;
        //       });
        //       return;
        //     }
        //   }
        // }

        // Check address and navigate
        bool hasAddress = false;
        if (!hasBaiguullagiinId) {
          final walletBairId = userData?['walletBairId']?.toString();
          final walletDoorNo = userData?['walletDoorNo']?.toString();
          if (walletBairId != null &&
              walletBairId.isNotEmpty &&
              walletDoorNo != null &&
              walletDoorNo.isNotEmpty) {
            await StorageService.saveWalletAddress(
              bairId: walletBairId,
              doorNo: walletDoorNo,
            );
            hasAddress = true;
          } else {
            hasAddress = await StorageService.hasSavedAddress();
          }

          if (!hasAddress) {
            final addressSaved = await context.push<bool>('/address_selection');
            if (addressSaved != true) {
              setState(() {
                _isLoading = false;
              });
              return;
            }
            hasAddress = true;
          }
        } else if (userData != null) {
          final walletBairId = userData['walletBairId']?.toString();
          final walletDoorNo = userData['walletDoorNo']?.toString();
          if (walletBairId != null &&
              walletBairId.isNotEmpty &&
              walletDoorNo != null &&
              walletDoorNo.isNotEmpty) {
            await StorageService.saveWalletAddress(
              bairId: walletBairId,
              doorNo: walletDoorNo,
            );
            hasAddress = true;
          } else {
            hasAddress = await StorageService.hasSavedAddress();
          }
        } else {
          hasAddress = await StorageService.hasSavedAddress();
        }

        // Check profile
        bool hasProfile = false;
        if (userData != null) {
          final hasNer =
              userData['ner'] != null && userData['ner'].toString().isNotEmpty;
          final hasOvog =
              userData['ovog'] != null &&
              userData['ovog'].toString().isNotEmpty;
          hasProfile = hasNer || hasOvog;
        }

        if (!hasProfile) {
          context.go(
            '/burtguulekh_signup',
            extra: {'baiguullagiinId': loginOrgId, 'utas': savedPhone},
          );
          return;
        }

        // Connect socket
        try {
          await SocketService.instance.connect();
        } catch (e) {
          print('Failed to connect socket: $e');
        }

        setState(() {
          _isLoading = false;
        });

        showGlassSnackBar(
          context,
          message: 'Нэвтрэлт амжилттай',
          icon: Icons.check_outlined,
          iconColor: Colors.green,
        );

        // Navigate to home
        final taniltsuulgaKharakhEsekh =
            await StorageService.getTaniltsuulgaKharakhEsekh();
        final targetRoute = taniltsuulgaKharakhEsekh ? '/ekhniikh' : '/nuur';

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go(targetRoute);
        }
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
          errorMessage = "Нэвтрэхэд алдаа гарлаа";
        }

        showGlassSnackBar(
          context,
          message: errorMessage,
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
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ScreenUtil().screenWidth > 700;
    final isDark = context.isDarkMode;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 420.w : double.infinity,
                      ),
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 16.h),
                              
                              // Logo with elegant circular background
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Green background circle for logo
                                  Container(
                                    width: 130.w,
                                    height: 130.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Logo
                                  SizedBox(
                                    width: 100.w,
                                    height: 100.w,
                                    child: SelectableLogoImage(
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              
                              // Welcome text - clean typography
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Нэвтрэх мэдээллээ оруулна уу',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : AppColors.lightTextSecondary.withOpacity(0.7),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              
                              SizedBox(height: 24.h),
                              
                              // Phone input
                              _buildModernInputField(
                                context: context,
                                controller: phoneController,
                                label: 'Утасны дугаар',
                                hint: '99001122',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                                isDark: isDark,
                              ),
                              
                              SizedBox(height: 16.h),
                              
                              // Password input
                              _buildModernInputField(
                                context: context,
                                controller: passwordController,
                                label: 'Нууц код',
                                hint: '••••',
                                icon: Icons.lock_outline_rounded,
                                keyboardType: TextInputType.number,
                                obscureText: _obscurePassword,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                isDark: isDark,
                                suffixIcon: passwordController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : AppColors.lightTextSecondary.withOpacity(0.5),
                                          size: 20.sp,
                                        ),
                                      )
                                    : null,
                              ),
                              
                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                  ),
                                  child: Text(
                                    'Нууц код мартсан?',
                                    style: TextStyle(
                                      color: AppColors.deepGreen,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Email field (conditional)
                              if (_showEmailField) ...[
                                SizedBox(height: 12.h),
                                _buildModernInputField(
                                  context: context,
                                  controller: emailController,
                                  label: 'Имэйл хаяг',
                                  hint: 'example@mail.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  isDark: isDark,
                                ),
                              ],
                              
                              SizedBox(height: 16.h),
                              
                              // Login button row with biometric
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPrimaryButton(
                                      context: context,
                                      onTap: _isLoading ? null : _handleLogin,
                                      isLoading: _isLoading,
                                      label: _showEmailField ? 'Бүртгүүлэх' : 'Нэвтрэх',
                                      isDark: isDark,
                                    ),
                                  ),
                                  if (_biometricAvailable && !_showEmailField) ...[
                                    SizedBox(width: 12.w),
                                    _buildBiometricButton(
                                      context: context,
                                      onTap: _isLoading ? null : _handleBiometricLogin,
                                      isDark: isDark,
                                    ),
                                  ],
                                ],
                              ),
                              
                              SizedBox(height: 12.h),
                              
                              // Hint text (only when in signup mode)
                              if (_showEmailField) ...[
                                Text(
                                  'Системд бүртгэлгүй байна',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.4)
                                        : AppColors.lightTextSecondary.withOpacity(0.6),
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                              ],
                              
                              // Divider with text
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    child: Text(
                                      'эсвэл',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.3)
                                            : AppColors.lightTextSecondary.withOpacity(0.5),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12.h),
                              
                              // Sign up button
                              GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/burtguulekh_signup',
                                    extra: {'forceNoOrg': true},
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32.w,
                                    vertical: 14.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.deepGreen.withOpacity(0.5)
                                          : AppColors.deepGreen.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Шинээр бүртгүүлэх',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? AppColors.deepGreenLight
                                          : AppColors.deepGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 16.h),
                              
                              // Footer
                              Column(
                                children: [
                                  Text(
                                    '© 2026 Powered by Zevtabs LLC',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.25)
                                          : Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Version 1.2.1',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.25),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                            ],
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
  
  // Modern input field widget
  Widget _buildModernInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.lightTextSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofocus: false,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.lightTextSecondary.withOpacity(0.4),
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 12.w),
                child: Icon(
                  icon,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : AppColors.lightTextSecondary.withOpacity(0.5),
                  size: 20.sp,
                ),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 48.w),
              suffixIcon: suffixIcon ?? (controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () => controller.clear(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : AppColors.lightTextSecondary.withOpacity(0.4),
                        size: 18.sp,
                      ),
                    )
                  : null),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }
  
  // Primary button widget
  Widget _buildPrimaryButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required bool isLoading,
    required String label,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepGreen,
              AppColors.deepGreenDark,
            ],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
  
  // Biometric button widget
  Widget _buildBiometricButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? AppColors.deepGreen.withOpacity(0.3)
                : AppColors.deepGreen.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Theme.of(context).platform == TargetPlatform.iOS
            ? Image.asset(
                'lib/assets/img/face-id.png',
                width: 26.sp,
                height: 26.sp,
                color: isDark
                    ? AppColors.deepGreenLight
                    : AppColors.deepGreen,
              )
            : Icon(
                Icons.fingerprint,
                color: isDark
                    ? AppColors.deepGreenLight
                    : AppColors.deepGreen,
                size: 26.sp,
              ),
      ),
    );
  }
  
  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    // Navigate to the password reset screen
    context.push('/nuuts-ug-sergeekh');
  }
  
  // Handle login logic - extracted for cleaner code
  Future<void> _handleLogin() async {
    String inputPhone = phoneController.text.trim();
    String inputPassword = passwordController.text.trim();

    if (inputPhone.isEmpty) {
      showGlassSnackBar(
        context,
        message: "Утасны дугаар оруулна уу",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    } else if (!RegExp(r'^\d+$').hasMatch(inputPhone)) {
      showGlassSnackBar(
        context,
        message: "Зөвхөн тоо оруулна уу!",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    if (!_showEmailField && inputPassword.isEmpty) {
      showGlassSnackBar(
        context,
        message: "Нууц код оруулна уу",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If email field is shown, user needs to register first
      if (_showEmailField) {
        final inputEmail = emailController.text.trim();

        if (inputEmail.isEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message: 'Имэйл хаяг оруулна уу',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          return;
        }

        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(inputEmail)) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message: 'Зөв имэйл хаяг оруулна уу',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          return;
        }

        // Register in Wallet API first
        await ApiService.registerWalletUser(
          utas: inputPhone,
          mail: inputEmail,
        );
      }

      // Get saved address to send with login
      var savedBairId = await StorageService.getWalletBairId();
      var savedDoorNo = await StorageService.getWalletDoorNo();

      if (savedBairId == null || savedDoorNo == null) {
        print('📍 [LOGIN] Address not in local storage, backend will use saved address from profile');
      }

      print('🔐 [LOGIN] Attempting login with phone: $inputPhone');
      print('🔐 [LOGIN] Sending address - bairId: $savedBairId, doorNo: $savedDoorNo');

      // Get OWN_ORG IDs if address is OWN_ORG type
      final savedBaiguullagiinId = await StorageService.getWalletBairBaiguullagiinId();
      final savedBarilgiinId = await StorageService.getWalletBairBarilgiinId();
      final savedSource = await StorageService.getWalletBairSource();

      final isOwnOrg = savedSource == 'OWN_ORG' &&
          savedBaiguullagiinId != null &&
          savedBarilgiinId != null;

      if (isOwnOrg) {
        print('🏢 [LOGIN] OWN_ORG address detected - baiguullagiinId: $savedBaiguullagiinId, barilgiinId: $savedBarilgiinId');
      }

      Map<String, dynamic> loginResponse;
      try {
        loginResponse = await ApiService.loginUser(
          utas: inputPhone,
          nuutsUg: inputPassword,
          bairId: savedBairId,
          doorNo: savedDoorNo,
          baiguullagiinId: isOwnOrg ? savedBaiguullagiinId : null,
          barilgiinId: isOwnOrg ? savedBarilgiinId : null,
        );
      } catch (e) {
        final raw = e.toString();
        final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;

        final isUserNotFound = msg.toLowerCase().contains('олдсонгүй') ||
            msg.toLowerCase().contains('not found');

        if (isUserNotFound) {
          final storedOrgId = await StorageService.getBaiguullagiinId();
          if (storedOrgId != null && storedOrgId.trim().isNotEmpty) {
            print('🏢 [LOGIN] Retry login with stored baiguullagiinId=$storedOrgId');
            loginResponse = await ApiService.loginUser(
              utas: inputPhone,
              nuutsUg: inputPassword,
              bairId: savedBairId,
              doorNo: savedDoorNo,
              baiguullagiinId: storedOrgId.trim(),
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Normalize user payload
      final userDataDynamic = loginResponse['result'] ?? loginResponse['orshinSuugch'];
      final userData = userDataDynamic is Map<String, dynamic> ? userDataDynamic : null;

      print('✅ [LOGIN] Login response received');
      print('   - Success: ${loginResponse['success']}');
      print('   - Has token: ${loginResponse['token'] != null}');

      // Verify token was saved
      final tokenSaved = await StorageService.isLoggedIn();
      print('🔑 [LOGIN] Token saved check: $tokenSaved');

      if (!tokenSaved) {
        throw Exception('Токен хадгалахад алдаа гарлаа. Дахин оролдоно уу.');
      }

      if (mounted) {
        print('📱 [LOGIN] ========== STARTING POST-LOGIN FLOW ==========');
        await StorageService.savePhoneNumber(inputPhone);
        print('📱 [LOGIN] Phone number saved');

        final loginOrgId = userData?['baiguullagiinId']?.toString();
        final hasBaiguullagiinId = loginOrgId != null &&
            loginOrgId.trim().isNotEmpty &&
            loginOrgId.trim().toLowerCase() != 'null';

        print('🏢 [LOGIN] baiguullagiinId from loginResponse: $loginOrgId (hasBaiguullagiinId=$hasBaiguullagiinId)');

        // TODO: Re-enable phone verification later
        // Handle OTP verification for WEB-created users
        // if (hasBaiguullagiinId) {
        //   print('📱 [LOGIN] ========== PHONE VERIFICATION CHECK ==========');
        //   final needsVerification = await StorageService.needsPhoneVerification();
        //   print('📱 [LOGIN] needsVerification result: $needsVerification');
        //
        //   if (needsVerification) {
        //     print('📱 [LOGIN] Phone verification required - showing verification screen');
        //
        //     final verificationResult = await context.push<bool>(
        //       '/phone_verification',
        //       extra: {
        //         'phoneNumber': inputPhone,
        //         'baiguullagiinId': loginOrgId,
        //         'duureg': userData?['duureg']?.toString(),
        //         'horoo': userData?['horoo']?.toString(),
        //         'soh': userData?['soh']?.toString(),
        //       },
        //     );
        //
        //     print('📱 [LOGIN] Verification result: $verificationResult');
        //
        //     if (verificationResult != true) {
        //       print('⚠️ [LOGIN] Phone verification cancelled or failed');
        //       print('🔓 [LOGIN] Logging out user because OTP verification was cancelled');
        //       await SessionService.logout();
        //       setState(() {
        //         _isLoading = false;
        //       });
        //       return;
        //     }
        //     print('✅ [LOGIN] Phone verification successful');
        //   }
        // } else {
        //   print('✅ [LOGIN] User without baiguullagiinId - skipping OTP verification');
        // }
        print('📱 [LOGIN] Phone verification TEMPORARILY DISABLED');

        // Save credentials for biometric
        await StorageService.savePhoneNumber(inputPhone);
        await StorageService.savePasswordForBiometric(inputPassword);
        print('🔐 [LOGIN] Credentials saved for biometric login');

        // Check address
        bool hasAddress = false;
        if (!hasBaiguullagiinId) {
          final walletBairId = userData?['walletBairId']?.toString();
          final walletDoorNo = userData?['walletDoorNo']?.toString();
          if (walletBairId != null && walletBairId.isNotEmpty &&
              walletDoorNo != null && walletDoorNo.isNotEmpty) {
            await StorageService.saveWalletAddress(
              bairId: walletBairId,
              doorNo: walletDoorNo,
            );
            hasAddress = true;
          } else {
            hasAddress = await StorageService.hasSavedAddress();
          }

          if (!hasAddress) {
            final addressSaved = await context.push<bool>('/address_selection');
            if (addressSaved != true) {
              setState(() {
                _isLoading = false;
              });
              return;
            }
            hasAddress = true;
          }
        } else if (userData != null) {
          final walletBairId = userData['walletBairId']?.toString();
          final walletDoorNo = userData['walletDoorNo']?.toString();
          if (walletBairId != null && walletBairId.isNotEmpty &&
              walletDoorNo != null && walletDoorNo.isNotEmpty) {
            await StorageService.saveWalletAddress(
              bairId: walletBairId,
              doorNo: walletDoorNo,
            );
            hasAddress = true;
          } else {
            hasAddress = await StorageService.hasSavedAddress();
          }
        } else {
          hasAddress = await StorageService.hasSavedAddress();
        }

        // Check profile
        bool hasProfile = false;
        if (userData != null) {
          final hasNer = userData['ner'] != null && userData['ner'].toString().isNotEmpty;
          final hasOvog = userData['ovog'] != null && userData['ovog'].toString().isNotEmpty;
          hasProfile = hasNer || hasOvog;
        }

        if (!hasProfile) {
          context.go(
            '/burtguulekh_signup',
            extra: {'baiguullagiinId': loginOrgId, 'utas': inputPhone},
          );
          return;
        }

        // Connect socket
        try {
          await SocketService.instance.connect();
        } catch (e) {
          print('Failed to connect socket: $e');
        }

        setState(() {
          _isLoading = false;
          _showEmailField = false;
        });

        showGlassSnackBar(
          context,
          message: 'Нэвтрэлт амжилттай',
          icon: Icons.check_outlined,
          iconColor: Colors.green,
        );

        // Navigate to home
        final taniltsuulgaKharakhEsekh = await StorageService.getTaniltsuulgaKharakhEsekh();
        final targetRoute = taniltsuulgaKharakhEsekh ? '/ekhniikh' : '/nuur';

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go(targetRoute);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showModalAfterNavigation();
            }
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
          errorMessage = "Нэвтрэхэд алдаа гарлаа";
        }

        // If user not found, redirect to signup
        if (errorMessage.contains('бүртгэлгүй') ||
            errorMessage.contains('бүртгэлтэй биш') ||
            errorMessage.contains('not found') ||
            errorMessage.contains('олдсонгүй')) {
          print('⚠️ [LOGIN] User not found, redirecting to signup page');
          showGlassSnackBar(
            context,
            message: 'Бүртгэлгүй хэрэглэгч бүртгүүлнэ үү',
            icon: Icons.warning_rounded,
            iconColor: Colors.orange,
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            context.go(
              '/burtguulekh_signup',
              extra: {
                'forceNoOrg': true,
                'utas': phoneController.text.trim(),
              },
            );
          }
          return;
        }

        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
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
