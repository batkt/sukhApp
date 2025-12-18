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
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/main.dart' show navigatorKey;
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.getGradientColors(isDark),
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: child,
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

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
  }

  Future<void> _loadSavedPhoneNumber() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    if (savedPhone != null && mounted) {
      setState(() {
        phoneController.text = savedPhone;
      });
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
                        maxWidth: isTablet
                            ? context.maxContentWidth
                            : double.infinity,
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: context
                              .responsiveHorizontalPadding(
                                small: 28,
                                medium: 32,
                                large: 36,
                                tablet: 40,
                              )
                              .copyWith(
                                top: context.responsiveSpacing(
                                  small: 12,
                                  medium: 14,
                                  large: 16,
                                  tablet: 20,
                                ),
                                bottom: context.responsiveSpacing(
                                  small: 12,
                                  medium: 14,
                                  large: 16,
                                  tablet: 20,
                                ),
                              ),
                          child: Column(
                            children: [
                              const Spacer(),
                              const AppLogo(),
                              SizedBox(height: 12.h),
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: context.isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.accentColor,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 24.h),
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
                                child: Builder(
                                  builder: (context) {
                                    final isDark = context.isDarkMode;
                                    return TextFormField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      autofocus: false,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Утасны дугаар',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : AppColors.lightTextSecondary
                                                    .withOpacity(0.6),
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? AppColors.secondaryAccent
                                                  .withOpacity(0.3)
                                            : Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 16.h,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : AppColors.lightInputGray,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? AppColors.grayColor
                                                      .withOpacity(0.8)
                                                : AppColors.deepGreen,
                                            width: 2,
                                          ),
                                        ),
                                        suffixIcon:
                                            phoneController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear_rounded,
                                                  color: isDark
                                                      ? Colors.grey.withOpacity(
                                                          0.7,
                                                        )
                                                      : AppColors
                                                            .lightTextSecondary,
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
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12.h),
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
                                child: Builder(
                                  builder: (context) {
                                    final isDark = context.isDarkMode;
                                    return TextFormField(
                                      controller: passwordController,
                                      obscureText: _obscurePassword,
                                      keyboardType: TextInputType.number,
                                      autofocus: false,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Нууц код',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : AppColors.lightTextSecondary
                                                    .withOpacity(0.6),
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? AppColors.secondaryAccent
                                                  .withOpacity(0.3)
                                            : Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 16.h,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : AppColors.lightInputGray,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? AppColors.grayColor
                                                      .withOpacity(0.8)
                                                : AppColors.deepGreen,
                                            width: 2,
                                          ),
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (passwordController
                                                .text
                                                .isNotEmpty)
                                              IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_off_rounded
                                                      : Icons
                                                            .visibility_rounded,
                                                  color: isDark
                                                      ? Colors.grey.withOpacity(
                                                          0.7,
                                                        )
                                                      : AppColors
                                                            .lightTextSecondary,
                                                  size: 20.sp,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                            if (passwordController
                                                .text
                                                .isNotEmpty)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.clear_rounded,
                                                  color: isDark
                                                      ? Colors.grey.withOpacity(
                                                          0.7,
                                                        )
                                                      : AppColors
                                                            .lightTextSecondary,
                                                  size: 20.sp,
                                                ),
                                                onPressed: () {
                                                  passwordController.clear();
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  _showEmailField
                                      ? 'Системд бүртгэлгүй байна. Имэйл хаягаа оруулна уу'
                                      : 'Системд бүртгэлтэй утасны дугаараа оруулна уу',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.secondaryAccent
                                        .withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              if (_showEmailField) ...[
                                SizedBox(height: 12.h),
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
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Имэйл хаяг',
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
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.grayColor
                                              .withOpacity(0.8),
                                          width: 2,
                                        ),
                                      ),
                                      suffixIcon:
                                          emailController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                size: 20.sp,
                                              ),
                                              onPressed: () =>
                                                  emailController.clear(),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        String inputPhone = phoneController.text
                                            .trim();
                                        String inputPassword =
                                            passwordController.text.trim();

                                        if (inputPhone.isEmpty) {
                                          showGlassSnackBar(
                                            context,
                                            message: "Утасны дугаар оруулна уу",
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

                                        if (!_showEmailField &&
                                            inputPassword.isEmpty) {
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
                                            final inputEmail = emailController
                                                .text
                                                .trim();

                                            if (inputEmail.isEmpty) {
                                              if (mounted) {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                showGlassSnackBar(
                                                  context,
                                                  message:
                                                      'Имэйл хаяг оруулна уу',
                                                  icon: Icons.error,
                                                  iconColor: Colors.red,
                                                );
                                              }
                                              return;
                                            }

                                            if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(inputEmail)) {
                                              if (mounted) {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                showGlassSnackBar(
                                                  context,
                                                  message:
                                                      'Зөв имэйл хаяг оруулна уу',
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
                                          // Backend will also check saved address in user profile if not provided
                                          var savedBairId =
                                              await StorageService.getWalletBairId();
                                          var savedDoorNo =
                                              await StorageService.getWalletDoorNo();

                                          // If address not in local storage, try to get from previous login response
                                          // This handles cases where address was saved to backend but not to local storage
                                          if (savedBairId == null ||
                                              savedDoorNo == null) {
                                            print(
                                              '📍 [LOGIN] Address not in local storage, backend will use saved address from profile',
                                            );
                                          }

                                          // Try to login - backend automatically handles billing connection
                                          print(
                                            '🔐 [LOGIN] Attempting login with phone: $inputPhone',
                                          );
                                          print(
                                            '🔐 [LOGIN] Sending address - bairId: $savedBairId, doorNo: $savedDoorNo',
                                          );

                                          // Some WEB-created users require baiguullagiinId to login.
                                          // First try without orgId; if backend says "Хэрэглэгч олдсонгүй!",
                                          // retry with stored baiguullagiinId (if we have one) before treating
                                          // the user as a new NO-ORG signup.
                                          Map<String, dynamic> loginResponse;
                                          try {
                                            loginResponse =
                                                await ApiService.loginUser(
                                                  utas: inputPhone,
                                                  nuutsUg: inputPassword,
                                                  bairId: savedBairId,
                                                  doorNo: savedDoorNo,
                                                );
                                          } catch (e) {
                                            final raw = e.toString();
                                            final msg =
                                                raw.startsWith('Exception: ')
                                                ? raw.substring(11)
                                                : raw;

                                            final isUserNotFound =
                                                msg.toLowerCase().contains(
                                                  'олдсонгүй',
                                                ) ||
                                                msg.toLowerCase().contains(
                                                  'not found',
                                                );

                                            if (isUserNotFound) {
                                              final storedOrgId =
                                                  await StorageService.getBaiguullagiinId();
                                              if (storedOrgId != null &&
                                                  storedOrgId
                                                      .trim()
                                                      .isNotEmpty) {
                                                print(
                                                  '🏢 [LOGIN] Retry login with stored baiguullagiinId=$storedOrgId',
                                                );
                                                loginResponse =
                                                    await ApiService.loginUser(
                                                      utas: inputPhone,
                                                      nuutsUg: inputPassword,
                                                      bairId: savedBairId,
                                                      doorNo: savedDoorNo,
                                                      baiguullagiinId:
                                                          storedOrgId.trim(),
                                                    );
                                              } else {
                                                // No orgId available to retry - keep original error behavior
                                                rethrow;
                                              }
                                            } else {
                                              rethrow;
                                            }
                                          }

                                          // Normalize user payload key: backend may return `result` or `orshinSuugch`
                                          final userDataDynamic =
                                              loginResponse['result'] ??
                                              loginResponse['orshinSuugch'];
                                          final userData =
                                              userDataDynamic
                                                  is Map<String, dynamic>
                                              ? userDataDynamic
                                              : null;

                                          print(
                                            '✅ [LOGIN] Login response received',
                                          );
                                          print(
                                            '   - Success: ${loginResponse['success']}',
                                          );
                                          print(
                                            '   - Has token: ${loginResponse['token'] != null}',
                                          );
                                          print(
                                            '   - Has result: ${loginResponse['result'] != null}',
                                          );
                                          print(
                                            '   - Has orshinSuugch: ${loginResponse['orshinSuugch'] != null}',
                                          );
                                          print(
                                            '   - Has billingInfo: ${loginResponse['billingInfo'] != null}',
                                          );

                                          // Verify token was saved before proceeding
                                          final tokenSaved =
                                              await StorageService.isLoggedIn();
                                          print(
                                            '🔑 [LOGIN] Token saved check: $tokenSaved',
                                          );

                                          if (!tokenSaved) {
                                            throw Exception(
                                              'Токен хадгалахад алдаа гарлаа. Дахин оролдоно уу.',
                                            );
                                          }

                                          if (mounted) {
                                            print(
                                              '📱 [LOGIN] ========== STARTING POST-LOGIN FLOW ==========',
                                            );
                                            await StorageService.savePhoneNumber(
                                              inputPhone,
                                            );
                                            print(
                                              '📱 [LOGIN] Phone number saved',
                                            );

                                            // CRITICAL: Check phone verification FIRST, before address/profile checks
                                            // OTP is automatically sent on login, so we need to verify it immediately
                                            print(
                                              '📱 [LOGIN] ========== PHONE VERIFICATION CHECK ==========',
                                            );
                                            print(
                                              '📱 [LOGIN] Checking if phone verification is needed...',
                                            );
                                            final needsVerification =
                                                await StorageService.needsPhoneVerification();
                                            print(
                                              '📱 [LOGIN] needsVerification result: $needsVerification',
                                            );

                                            // FORCE OTP verification for now to debug - always show OTP screen
                                            // TODO: Remove this and use needsVerification check once working
                                            print(
                                              '📱 [LOGIN] FORCING OTP verification - showing verification screen',
                                            );

                                            // Show phone verification screen IMMEDIATELY after login
                                            // OTP is automatically sent on login, so we just need to verify it
                                            final verificationResult =
                                                await context.push<bool>(
                                                  '/phone_verification',
                                                  extra: {
                                                    'phoneNumber': inputPhone,
                                                    'baiguullagiinId':
                                                        userData?['baiguullagiinId']
                                                            ?.toString(),
                                                    'duureg':
                                                        userData?['duureg']
                                                            ?.toString(),
                                                    'horoo': userData?['horoo']
                                                        ?.toString(),
                                                    'soh': userData?['soh']
                                                        ?.toString(),
                                                  },
                                                );

                                            print(
                                              '📱 [LOGIN] Verification result: $verificationResult',
                                            );

                                            // If verification was cancelled or failed, don't proceed
                                            if (verificationResult != true) {
                                              print(
                                                '⚠️ [LOGIN] Phone verification cancelled or failed - staying on login screen',
                                              );

                                              // IMPORTANT: Logout user if they cancel OTP verification
                                              // This prevents router from redirecting to home page
                                              // because the token was already saved during login
                                              print(
                                                '🔓 [LOGIN] Logging out user because OTP verification was cancelled',
                                              );
                                              await SessionService.logout();

                                              setState(() {
                                                _isLoading = false;
                                              });
                                              return;
                                            }

                                            print(
                                              '✅ [LOGIN] Phone verification successful - continuing with login flow',
                                            );

                                            // Determine if this is a WEB-created user (has baiguullagiinId)
                                            // or a MOBILE-created user (no baiguullagiinId).
                                            // Only WEB-created users should go through Wallet address selection.
                                            final loginOrgId =
                                                userData?['baiguullagiinId']
                                                    ?.toString();
                                            final hasBaiguullagiinId =
                                                loginOrgId != null &&
                                                loginOrgId.trim().isNotEmpty &&
                                                loginOrgId
                                                        .trim()
                                                        .toLowerCase() !=
                                                    'null';

                                            print(
                                              '🏢 [LOGIN] baiguullagiinId from loginResponse: $loginOrgId (hasBaiguullagiinId=$hasBaiguullagiinId)',
                                            );

                                            // Check if user has address in their profile
                                            // The login response has walletBairId and walletDoorNo
                                            bool hasAddress = false;

                                            // MOBILE-created users: do not require Wallet address selection on login.
                                            // Their "Хаягийн мэдээлэл" is collected during signup.
                                            if (!hasBaiguullagiinId) {
                                              hasAddress =
                                                  true; // skip address selection block below
                                              print(
                                                '📍 [LOGIN] NO-ORG user detected -> skipping wallet address checks and address_selection screen',
                                              );
                                            } else if (userData != null) {
                                              final walletBairId =
                                                  userData['walletBairId']
                                                      ?.toString();
                                              final walletDoorNo =
                                                  userData['walletDoorNo']
                                                      ?.toString();

                                              if (walletBairId != null &&
                                                  walletBairId.isNotEmpty &&
                                                  walletDoorNo != null &&
                                                  walletDoorNo.isNotEmpty) {
                                                // Save address from user profile to local storage
                                                await StorageService.saveWalletAddress(
                                                  bairId: walletBairId,
                                                  doorNo: walletDoorNo,
                                                );
                                                hasAddress = true;
                                                print(
                                                  '📍 [LOGIN] Address found in user profile: $walletBairId / $walletDoorNo',
                                                );

                                                // If billingInfo is not in response but we have address,
                                                // the backend should have fetched it automatically
                                                // If not, we'll fetch it manually as fallback
                                                if (loginResponse['billingInfo'] ==
                                                    null) {
                                                  print(
                                                    '⚠️ [LOGIN] Address exists but billingInfo missing - will fetch manually',
                                                  );
                                                }
                                              } else {
                                                // Check if address is already saved locally
                                                hasAddress =
                                                    await StorageService.hasSavedAddress();
                                                print(
                                                  '📍 [LOGIN] Address not in profile, checking local storage: $hasAddress',
                                                );
                                              }
                                            } else {
                                              // Fallback to local storage check
                                              hasAddress =
                                                  await StorageService.hasSavedAddress();
                                              print(
                                                '📍 [LOGIN] No user data in response, checking local storage: $hasAddress',
                                              );
                                            }

                                            final taniltsuulgaKharakhEsekh =
                                                await StorageService.getTaniltsuulgaKharakhEsekh();

                                            print(
                                              '📍 [LOGIN] Final hasAddress: $hasAddress',
                                            );

                                            print(
                                              '📍 [LOGIN] Has saved address: $hasAddress',
                                            );
                                            if (hasAddress) {
                                              final bairId =
                                                  await StorageService.getWalletBairId();
                                              final doorNo =
                                                  await StorageService.getWalletDoorNo();
                                              print(
                                                '📍 [LOGIN] Saved address - bairId: $bairId, doorNo: $doorNo',
                                              );
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

                                            try {
                                              await SocketService.instance
                                                  .connect();
                                            } catch (e) {
                                              print(
                                                'Failed to connect socket: $e',
                                              );
                                            }

                                            // Backend now automatically handles billing connection
                                            // Check billingInfo in response to see if billing was connected
                                            if (loginResponse['billingInfo'] !=
                                                null) {
                                              final billingInfo =
                                                  loginResponse['billingInfo'];
                                              final billingConnected =
                                                  loginResponse['billingConnected'] ==
                                                  true;

                                              print(
                                                '✅ [LOGIN] Billing info received from backend',
                                              );
                                              print(
                                                '   - Billing ID: ${billingInfo['billingId']}',
                                              );
                                              print(
                                                '   - Billing Name: ${billingInfo['billingName']}',
                                              );
                                              print(
                                                '   - Customer Name: ${billingInfo['customerName']}',
                                              );
                                              print(
                                                '   - Billing Connected: $billingConnected',
                                              );

                                              if (!billingConnected &&
                                                  loginResponse['connectionError'] !=
                                                      null) {
                                                print(
                                                  '⚠️ [LOGIN] Billing connection failed: ${loginResponse['connectionError']}',
                                                );
                                              }
                                            } else {
                                              // No billingInfo in response
                                              // Check if user has address - backend should have used it automatically
                                              if (hasAddress) {
                                                print(
                                                  '⚠️ [LOGIN] User has address but no billingInfo in response',
                                                );
                                                print(
                                                  '   Backend should have automatically fetched billing using saved address',
                                                );
                                                print(
                                                  '   Attempting to fetch billing manually...',
                                                );

                                                // Try to fetch billing manually using the address from profile
                                                try {
                                                  final bairId =
                                                      await StorageService.getWalletBairId();
                                                  final doorNo =
                                                      await StorageService.getWalletDoorNo();

                                                  if (bairId != null &&
                                                      doorNo != null) {
                                                    await ApiService.fetchWalletBilling(
                                                      bairId: bairId,
                                                      doorNo: doorNo,
                                                    );
                                                    print(
                                                      '✅ [LOGIN] Billing fetched manually after login',
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    '⚠️ [LOGIN] Could not fetch billing manually: $e',
                                                  );
                                                  // This is not critical - user can still use the app
                                                }
                                              } else {
                                                print(
                                                  'ℹ️ [LOGIN] No billing info in response (user may not have address)',
                                                );
                                              }
                                            }

                                            // Navigate to home
                                            final targetRoute =
                                                taniltsuulgaKharakhEsekh
                                                ? '/ekhniikh'
                                                : '/nuur';

                                            // Only WEB-created (ORG) users should be forced to pick a wallet address
                                            if (!hasAddress &&
                                                hasBaiguullagiinId) {
                                              // Check if user has address on server before showing address selection
                                              // Check user profile to see if they have walletBairId and walletDoorNo
                                              bool hasServerAddress = false;
                                              try {
                                                final userProfile =
                                                    await ApiService.getUserProfile();
                                                if (userProfile['result'] !=
                                                    null) {
                                                  final userData =
                                                      userProfile['result'];
                                                  final walletBairId =
                                                      userData['walletBairId']
                                                          ?.toString();
                                                  final walletDoorNo =
                                                      userData['walletDoorNo']
                                                          ?.toString();

                                                  if (walletBairId != null &&
                                                      walletBairId.isNotEmpty &&
                                                      walletDoorNo != null &&
                                                      walletDoorNo.isNotEmpty) {
                                                    // User has address on server, save it locally and skip address selection
                                                    await StorageService.saveWalletAddress(
                                                      bairId: walletBairId,
                                                      doorNo: walletDoorNo,
                                                    );
                                                    hasServerAddress = true;
                                                    hasAddress = true;
                                                    print(
                                                      '📍 [LOGIN] Address found on server, skipping address selection screen',
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                print(
                                                  '⚠️ [LOGIN] Error checking server address: $e',
                                                );
                                                // Continue to address selection if check fails
                                              }

                                              if (!hasServerAddress) {
                                                // If user doesn't have address on server, show address selection screen
                                                // Address selection will fetch billing data separately
                                                print(
                                                  '📍 [LOGIN] No saved address, showing address selection screen',
                                                );
                                                final addressSaved =
                                                    await context.push<bool>(
                                                      '/address_selection',
                                                    );

                                                // Only navigate to home if address was successfully saved
                                                // If user pressed back, addressSaved will be null/false, stay on login screen
                                                if (addressSaved != true) {
                                                  print(
                                                    '⚠️ [LOGIN] Address selection cancelled or failed, staying on login screen',
                                                  );
                                                  return; // Exit early, don't navigate to home
                                                }
                                              }
                                            }

                                            // Check if user has profile (ner and ovog)
                                            bool hasProfile = false;
                                            if (userData != null) {
                                              final hasNer =
                                                  userData['ner'] != null &&
                                                  userData['ner']
                                                      .toString()
                                                      .isNotEmpty;
                                              final hasOvog =
                                                  userData['ovog'] != null &&
                                                  userData['ovog']
                                                      .toString()
                                                      .isNotEmpty;
                                              hasProfile = hasNer || hasOvog;

                                              print(
                                                '👤 [LOGIN] Profile check - hasNer: $hasNer, hasOvog: $hasOvog, hasProfile: $hasProfile',
                                              );
                                            }

                                            // If user has no profile, redirect to signup window
                                            if (!hasProfile) {
                                              print(
                                                '⚠️ [LOGIN] User has no profile, redirecting to signup',
                                              );
                                              // Navigate to signup window
                                              context.go(
                                                '/burtguulekh_signup',
                                                extra: {
                                                  // WEB-created user -> has orgId, no address required here
                                                  'baiguullagiinId': loginOrgId,
                                                  'utas': inputPhone,
                                                },
                                              );
                                              return;
                                            }

                                            // Navigate to home (phone verification was already handled earlier in the flow)
                                            print(
                                              '🚀 [LOGIN] Preparing to navigate to: $targetRoute',
                                            );

                                            // Small delay to ensure any screens are fully closed
                                            await Future.delayed(
                                              const Duration(milliseconds: 300),
                                            );

                                            if (!mounted) {
                                              print(
                                                '⚠️ [LOGIN] Widget not mounted, skipping navigation',
                                              );
                                              return;
                                            }

                                            try {
                                              print(
                                                '🚀 [LOGIN] Navigating to: $targetRoute',
                                              );
                                              context.go(targetRoute);
                                              print(
                                                '✅ [LOGIN] Navigation successful',
                                              );
                                            } catch (e) {
                                              print(
                                                '❌ [LOGIN] Navigation error: $e',
                                              );
                                              // Try alternative navigation method
                                              if (mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pushNamedAndRemoveUntil(
                                                  targetRoute,
                                                  (route) => false,
                                                );
                                              }
                                            }

                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  Future.delayed(
                                                    const Duration(
                                                      milliseconds: 800,
                                                    ),
                                                    () {
                                                      if (mounted) {
                                                        _showModalAfterNavigation();
                                                      }
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
                                                  "Нэвтрэхэд алдаа гарлаа";
                                            }

                                            // If login fails because user is not registered, show warning and redirect to signup page
                                            if (errorMessage.contains(
                                                  'бүртгэлгүй',
                                                ) ||
                                                errorMessage.contains(
                                                  'бүртгэлтэй биш',
                                                ) ||
                                                errorMessage.contains(
                                                  'not found',
                                                ) ||
                                                errorMessage.contains(
                                                  'олдсонгүй',
                                                )) {
                                              print(
                                                '⚠️ [LOGIN] User not found, redirecting to signup page',
                                              );
                                              // Show warning message
                                              showGlassSnackBar(
                                                context,
                                                message:
                                                    'Бүртгэлгүй хэрэглэгч бүртгүүлнэ үү',
                                                icon: Icons.warning_rounded,
                                                iconColor: Colors.orange,
                                              );
                                              // Wait a moment for user to see the message, then redirect
                                              await Future.delayed(
                                                const Duration(
                                                  milliseconds: 1500,
                                                ),
                                              );
                                              // Redirect to signup page instead of showing email field
                                              if (mounted) {
                                                context.go(
                                                  '/burtguulekh_signup',
                                                  extra: {
                                                    // New MOBILE user -> force NO-ORG signup flow with address required
                                                    'forceNoOrg': true,
                                                    'utas': phoneController.text
                                                        .trim(),
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
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
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
                                          _showEmailField
                                              ? 'Бүртгүүлэх'
                                              : 'Нэвтрэх',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: context.isDarkMode
                                                ? AppColors.darkTextPrimary
                                                : AppColors.darkTextPrimary,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              GestureDetector(
                                onTap: () {
                                  // Manual signup from login screen -> force NO-ORG flow
                                  context.push(
                                    '/burtguulekh_signup',
                                    extra: {'forceNoOrg': true},
                                  );
                                },
                                child: Text(
                                  'Бүртгүүлэх',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: context.isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.accentColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
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
                                'Version 1.1',
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
