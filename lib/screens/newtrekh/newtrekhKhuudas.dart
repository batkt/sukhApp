import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/widgets/auth/registration_modal.dart';
import 'package:sukh_app/widgets/auth/forgot_password_modal.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/main.dart' show navigatorKey;
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/biometric_service.dart';

/// Modern minimal background with subtle gradient
// SharedBgPainter is used from common widgets

class Newtrekhkhuudas extends StatefulWidget {
  const Newtrekhkhuudas({super.key});

  @override
  State<Newtrekhkhuudas> createState() => _NewtrekhkhuudasState();
}

class _NewtrekhkhuudasState extends State<Newtrekhkhuudas> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showPasswordInput = false;
  bool _isCheckingPhone = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
    passwordController.addListener(() => setState(() {}));
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
    final icon = await BiometricService.getBiometricIcon();
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricIcon = icon;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_biometricAvailable) {
      showGlassSnackBar(
        context,
        message: 'Биометрийн баталгаажуулалт боломжгүй байна',
        icon: Icons.error,
        iconColor: Colors.orange,
      );
      return;
    }

    final savedPhone = await StorageService.getSavedPhoneNumber();
    final savedPassword = await StorageService.getSavedPasswordForBiometric();

    if (savedPhone == null || savedPassword == null) {
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!isLoggedIn) {
        showGlassSnackBar(
          context,
          message: 'Эхлээд нэвтэрч, биометрийн мэдээлэл хадгалах шаардлагатай',
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
        return;
      }
      showGlassSnackBar(
        context,
        message:
            'Биометрийн мэдээлэл олдсонгүй. Тохиргооноос биометрийн нэвтрэлтийг идэвхжүүлэх үү',
        icon: Icons.error,
        iconColor: Colors.orange,
      );
      return;
    }

    final authenticated = await BiometricService.authenticate();
    if (!authenticated) return;

    setState(() {
      phoneController.text = savedPhone;
      passwordController.text = savedPassword;
      _isLoading = true;
    });

    _performLoginWithCredentials(savedPhone, savedPassword);
  }

  Future<void> _checkPhoneExistence() async {
    String phone = phoneController.text.trim();
    if (phone.length != 8) {
      showGlassSnackBar(
        context,
        message: "Утасны дугаар 8 оронтой байх ёстой",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isCheckingPhone = true);
    try {
      final exists = await ApiService.checkPhoneExists(utas: phone);

      if (exists != null) {
        // User exists in primary records
        setState(() {
          _showPasswordInput = true;
          _isCheckingPhone = false;
        });
        passwordFocusNode.requestFocus();
      } else {
        // Not in primary, check if linked via Easy Register
        try {
          final easyData = await ApiService.easyRegisterUserSearch(
            identity: phone,
            phoneNum: phone,
          );

          // If this record is already linked to a resident ID, treat as existing user
          if (easyData != null &&
              (easyData['orshinSuugchiinId'] != null ||
                  easyData['orshinSuugchiid'] != null)) {
            setState(() {
              _showPasswordInput = true;
              _isCheckingPhone = false;
            });
            passwordFocusNode.requestFocus();
            return;
          }
        } catch (e) {
          debugPrint('EasyRegister pre-check error: $e');
        }

        setState(() => _isCheckingPhone = false);
        _showRegistrationModal();
      }
    } catch (e) {
      setState(() => _isCheckingPhone = false);
      showGlassSnackBar(
        context,
        message: "Алдаа гарлаа: $e",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

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
    }
    if (inputPassword.isEmpty) {
      showGlassSnackBar(
        context,
        message: "Нууц код оруулна уу",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);
    _performLoginWithCredentials(inputPhone, inputPassword);
  }

  Future<void> _performLoginWithCredentials(
    String phone,
    String password,
  ) async {
    try {
      var savedBairId = await StorageService.getWalletBairId();
      var savedDoorNo = await StorageService.getWalletDoorNo();
      var savedBairName = await StorageService.getWalletBairName();
      final savedBaiguullagiinId =
          await StorageService.getWalletBairBaiguullagiinId();
      final savedBarilgiinId = await StorageService.getWalletBairBarilgiinId();
      final savedSource = await StorageService.getWalletBairSource();

      final isOwnOrg =
          savedSource == 'OWN_ORG' &&
          savedBaiguullagiinId != null &&
          savedBarilgiinId != null;

      final loginResponse = await ApiService.loginUser(
        utas: phone,
        nuutsUg: password,
        bairId: savedBairId,
        doorNo: savedDoorNo,
        bairName: savedSource == 'WALLET_API' ? savedBairName : null,
        baiguullagiinId: isOwnOrg ? savedBaiguullagiinId : null,
        barilgiinId: isOwnOrg ? savedBarilgiinId : null,
      );

      final userDataDynamic =
          loginResponse['result'] ?? loginResponse['orshinSuugch'];
      final userData = userDataDynamic is Map<String, dynamic>
          ? userDataDynamic
          : null;

      if (mounted) {
        await StorageService.savePhoneNumber(phone);
        final loginOrgId = userData?['baiguullagiinId']?.toString();
        final hasBaiguullagiinId =
            loginOrgId != null &&
            loginOrgId.trim().isNotEmpty &&
            loginOrgId.trim().toLowerCase() != 'null';

        // Address check
        bool hasAddress = await StorageService.hasSavedAddress();
        if (!hasAddress && userData != null) {
          final wBairId = userData['walletBairId']?.toString();
          final wDoorNo = userData['walletDoorNo']?.toString();
          if (wBairId != null &&
              wBairId.isNotEmpty &&
              wDoorNo != null &&
              wDoorNo.isNotEmpty) {
            await StorageService.saveWalletAddress(
              bairId: wBairId,
              doorNo: wDoorNo,
            );
            hasAddress = true;
          }
        }

        // Profile check
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
            extra: {'baiguullagiinId': loginOrgId, 'utas': phone},
          );
          return;
        }

        try {
          await SocketService.instance.connect();
        } catch (_) {}

        setState(() => _isLoading = false);
        showGlassSnackBar(
          context,
          message: 'Нэвтрэлт амжилттай',
          icon: Icons.check_outlined,
          iconColor: Colors.green,
        );

        // --- Biometric Onboarding/Fix Logic ---
        final biometricEnabled = await StorageService.isBiometricEnabled();
        final savedBiometricPw =
            await StorageService.getSavedPasswordForBiometric();

        if (biometricEnabled &&
            savedBiometricPw == null &&
            _biometricAvailable) {
          // Fix for users who enabled it but didn't save password
          await StorageService.savePasswordForBiometric(password);
        } else if (!biometricEnabled && _biometricAvailable) {
          // Offer to enable if context is right
          await _showBiometricEnablePrompt(context, password);
        }
        // --------------------------------------

        final taniltsuulgaKharakhEsekh =
            await StorageService.getTaniltsuulgaKharakhEsekh();
        final targetRoute = taniltsuulgaKharakhEsekh ? '/ekhniikh' : '/nuur';

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.go(targetRoute);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showGlassSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordModal(),
    );
  }

  void _showRegistrationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RegistrationModal(initialPhone: phoneController.text.trim()),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: CustomPaint(
        painter: SharedBgPainter(
          isDark: isDark,
          brandColor: AppColors.deepGreen,
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          child: _buildBranding(isDark, isTablet),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: _buildLoginForm(context, isDark, isTablet),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              children: [
                                Spacer(flex: isTablet ? 3 : 2),
                                _buildBranding(isDark, isTablet),
                                Spacer(flex: isTablet ? 2 : 2),
                                _buildLoginForm(context, isDark, isTablet),
                                const Spacer(flex: 3),
                                _buildFooter(isDark),
                                SizedBox(height: 24.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark, bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(isTablet ? 24.r : 18.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepGreen.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const SelectableLogoImage(height: 64),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          "Тавтай морилно уу",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontSize: isTablet ? 28.sp : 24.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "Нэвтрэх хэсэг",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : AppColors.lightTextSecondary.withOpacity(0.7),
            fontSize: isTablet ? 15.sp : 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isDark, bool isTablet) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 480 : 380),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 30.r : 20.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.0)
                  : AppColors.lightBorderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                label: "Утасны дугаар",
                hint: "Дугаар оруулна уу",
                controller: phoneController,
                focusNode: phoneFocusNode,
                icon: Icons.phone_android_rounded,
                isDark: isDark,
                readOnly: _showPasswordInput,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                onFieldSubmitted: (_) =>
                    !_showPasswordInput ? _checkPhoneExistence() : null,
              ),
              if (_showPasswordInput) ...[
                SizedBox(height: 20.h),
                _buildInputField(
                  label: "Нууц код",
                  hint: "Нууц код оруулна уу",
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : AppColors.lightTextSecondary.withOpacity(0.4),
                      size: 20.sp,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.deepGreenLight
                          : AppColors.deepGreen,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    child: Text(
                      "Нууц код мартсан?",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              if (!_showPasswordInput)
                Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryButton(
                        context: context,
                        onTap: _isCheckingPhone ? null : _checkPhoneExistence,
                        isLoading: _isCheckingPhone,
                        label: "Үргэлжлүүлэх",
                        isDark: isDark,
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      SizedBox(width: 12.w),
                      _buildBiometricButton(
                        context: context,
                        onTap: _isLoading ? null : _authenticateWithBiometrics,
                        isDark: isDark,
                      ),
                    ],
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryButton(
                            context: context,
                            onTap: _isLoading ? null : _handleLogin,
                            isLoading: _isLoading,
                            label: "Нэвтрэх",
                            isDark: isDark,
                          ),
                        ),
                        if (_biometricAvailable) ...[
                          SizedBox(width: 12.w),
                          _buildBiometricButton(
                            context: context,
                            onTap: _isLoading
                                ? null
                                : _authenticateWithBiometrics,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => setState(() {
                        _showPasswordInput = false;
                        passwordController.clear();
                      }),
                      child: Text(
                        "Буцах",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black45,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    FocusNode? focusNode,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: readOnly
                  ? AppColors.deepGreen.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onFieldSubmitted: onFieldSubmitted,
            style: TextStyle(
              color: isDark
                  ? (readOnly ? Colors.white60 : Colors.white)
                  : (readOnly ? Colors.black54 : AppColors.lightTextPrimary),
              fontSize: 16.sp,
              fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey,
                fontSize: 15.sp,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark
                    ? (readOnly ? AppColors.deepGreen : Colors.white38)
                    : (readOnly ? AppColors.deepGreen : Colors.grey),
                size: 20.sp,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required bool isLoading,
    required String label,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.deepGreen,
            borderRadius: BorderRadius.circular(14.r),
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
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.deepGreen.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(_biometricIcon, color: AppColors.deepGreen, size: 28.sp),
        ),
      ),
    );
  }

  Future<void> _showBiometricEnablePrompt(
    BuildContext context,
    String password,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(_biometricIcon, color: AppColors.deepGreen),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? 'Face ID ашиглах уу?'
                      : 'Хурууны хээ ашиглах уу?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Дараагийн удаа илүү хурдан нэвтрэхийн тулд биометрийг идэвхжүүлэх үү?',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Үгүй, баярлалаа',
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final authenticated = await BiometricService.authenticate();
                if (authenticated) {
                  await StorageService.savePasswordForBiometric(password);
                  await StorageService.setBiometricEnabled(true);
                  if (context.mounted) {
                    showGlassSnackBar(
                      context,
                      message: 'Биометрийн нэвтрэлт идэвхэжлээ',
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                    );
                    setState(() {
                      _checkBiometricStatus();
                    });
                  }
                }
                if (context.mounted) {
                  Navigator.pop(dialogContext); // Close dialog AFTER scanning
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              child: Text(
                'Тийм, идэвхжүүлье',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          "© 2026 Powered by Zevtabs LLC",
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Version 2.1.3",
          style: TextStyle(
            color: isDark ? Colors.white12 : Colors.black12,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
