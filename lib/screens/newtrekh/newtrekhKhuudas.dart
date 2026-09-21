import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/services/push_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/auth/forgot_password_modal.dart';
import 'package:sukh_app/widgets/auth/registration_modal.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';
import 'package:sukh_app/widgets/common_footer.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';

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
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneNumber();
    _checkBiometricStatus();
    phoneController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
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

  String? _getOperator(String phone) {
    final clean = phone.trim();
    if (clean.length < 2) return null;
    final prefix = clean.substring(0, 2);
    const mobicom = {'99', '95', '94', '85'};
    const unitel = {'88', '86', '89'};
    const skytel = {'90', '91', '96'};
    const gmobile = {'98', '93', '97'};

    if (mobicom.contains(prefix)) return 'Mobicom';
    if (unitel.contains(prefix)) return 'Unitel';
    if (skytel.contains(prefix)) return 'Skytel';
    if (gmobile.contains(prefix)) return 'G-Mobile';
    return null;
  }

  Color _getOperatorColor(String? op) {
    switch (op) {
      case 'Mobicom':
        return const Color(0xFFE50027);
      case 'Unitel':
        return const Color(0xFF00A859);
      case 'Skytel':
        return const Color(0xFF0072CE);
      case 'G-Mobile':
        return const Color(0xFFFF6F00);
      default:
        return AppColors.deepGreen;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_biometricAvailable) {
      showGlassSnackBar(
        context,
        message: 'Биометрийн баталгаажуулалт боломжгүй байна',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    final savedPhone = await StorageService.getSavedPhoneNumber();
    final savedPassword = await StorageService.getSavedPasswordForBiometric();

    if (savedPhone == null || savedPassword == null) {
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!mounted) return;
      if (!isLoggedIn) {
        showGlassSnackBar(
          context,
          message: 'Эхлээд нэвтэрч, биометрийн мэдээлэл хадгалах шаардлагатай',
          icon: Icons.info_outline_rounded,
          iconColor: Colors.blue,
        );
        return;
      }
      showGlassSnackBar(
        context,
        message: 'Биометрийн мэдээлэл олдсонгүй. Нууц кодоороо нэвтэрнэ үү',
        icon: Icons.error_outline_rounded,
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

  Future<void> _handleLogin() async {
    String inputPhone = phoneController.text.trim();
    String inputPassword = passwordController.text.trim();

    if (inputPhone.isEmpty) {
      showGlassSnackBar(
        context,
        message: "Утасны дугаараа оруулна уу",
        icon: Icons.phone_android_rounded,
        iconColor: Colors.redAccent,
      );
      phoneFocusNode.requestFocus();
      return;
    }

    if (inputPhone.length != 8) {
      showGlassSnackBar(
        context,
        message: "Утасны дугаар 8 оронтой байх ёстой",
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      phoneFocusNode.requestFocus();
      return;
    }

    if (inputPassword.isEmpty) {
      showGlassSnackBar(
        context,
        message: "Нууц кодоо оруулна уу",
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.redAccent,
      );
      passwordFocusNode.requestFocus();
      return;
    }

    if (inputPassword.length < 4) {
      showGlassSnackBar(
        context,
        message: "Нууц код 4 оронтой байх ёстой",
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.redAccent,
      );
      passwordFocusNode.requestFocus();
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

      final pushToken = await PushService.tokenAvya();

      final loginResponse = await ApiService.loginUser(
        utas: phone,
        nuutsUg: password,
        firebaseToken: pushToken,
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

        // Address check
        bool hasAddress = false;
        if (userData != null) {
          String? wBairId = userData['walletBairId']?.toString();
          String? wDoorNo = userData['walletDoorNo']?.toString();
          final toots = userData['toots'];

          if ((wBairId == null ||
                  wBairId.isEmpty ||
                  wDoorNo == null ||
                  wDoorNo.isEmpty) &&
              toots is List) {
            final tootWithWalletAddress = toots.cast<dynamic>().firstWhere(
              (item) =>
                  item is Map &&
                  item['walletBairId']?.toString().isNotEmpty == true &&
                  item['walletDoorNo']?.toString().isNotEmpty == true,
              orElse: () => null,
            );
            if (tootWithWalletAddress is Map) {
              wBairId = tootWithWalletAddress['walletBairId']?.toString();
              wDoorNo = tootWithWalletAddress['walletDoorNo']?.toString();
            }
          }

          final hasWalletAddress =
              wBairId != null &&
              wBairId.isNotEmpty &&
              wDoorNo != null &&
              wDoorNo.isNotEmpty;

          if (hasWalletAddress) {
            await StorageService.saveWalletAddress(
              bairId: wBairId,
              doorNo: wDoorNo,
            );
            hasAddress = true;
          } else {
            final baiguullagiinId = userData['baiguullagiinId']?.toString();
            final barilgiinId = userData['barilgiinId']?.toString();

            final hasOwnOrgAddress =
                baiguullagiinId != null &&
                baiguullagiinId.isNotEmpty &&
                barilgiinId != null &&
                barilgiinId.isNotEmpty;

            if (hasOwnOrgAddress) {
              await StorageService.saveWalletAddress(
                bairId: barilgiinId,
                doorNo: 'OWN_ORG',
                source: 'OWN_ORG',
                baiguullagiinId: baiguullagiinId,
                barilgiinId: barilgiinId,
              );
              hasAddress = true;
            } else {
              await StorageService.clearWalletAddress();
            }
          }
        } else {
          await StorageService.clearWalletAddress();
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

        if (!mounted) return;
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

        if (!mounted) return;
        setState(() => _isLoading = false);
        showGlassSnackBar(
          context,
          message: 'Амжилттай нэвтэрлээ',
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
        );

        final biometricEnabled = await StorageService.isBiometricEnabled();
        final savedBiometricPw =
            await StorageService.getSavedPasswordForBiometric();

        if (!mounted) return;
        if (biometricEnabled &&
            savedBiometricPw == null &&
            _biometricAvailable) {
          await StorageService.savePasswordForBiometric(password);
        } else if (!biometricEnabled && _biometricAvailable) {
          await _showBiometricEnablePrompt(context, password);
        }

        final taniltsuulgaKharakhEsekh =
            await StorageService.getTaniltsuulgaKharakhEsekh();
        final targetRoute = taniltsuulgaKharakhEsekh
            ? '/ekhniikh'
            : (hasAddress ? '/nuur' : '/address_selection');

        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) context.go(targetRoute);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errText = e.toString().replaceFirst('Exception: ', '');
        showGlassSnackBar(
          context,
          message: errText,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
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
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = screenWidth >= 600;

    final double maxFormWidth = screenWidth >= 1100 ? 580.0 : double.infinity;

    final double horizontalPadding;
    if (screenWidth < 350) {
      horizontalPadding = 14.0;
    } else if (screenWidth < 600) {
      horizontalPadding = 20.0;
    } else if (screenWidth < 1100) {
      horizontalPadding = 28.0;
    } else {
      horizontalPadding = 44.0;
    }

    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF0F1215) : const Color(0xFFF8FAFC),
      body: CustomPaint(
        painter: SharedBgPainter(
          isDark: isDark,
          brandColor: AppColors.deepGreen,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: keyboardHeight,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          height: isKeyboardOpen
                              ? (isTablet ? 36.h : 24.h)
                              : (isTablet ? 96.h : 84.h),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: isKeyboardOpen
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: _buildBranding(isDark, isTablet),
                          secondChild: const SizedBox.shrink(),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          height: isKeyboardOpen
                              ? 12.h
                              : (isTablet ? 44.h : 36.h),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxFormWidth),
                          child: _buildLoginForm(context, isDark, isTablet),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isKeyboardOpen)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildFooter(isDark),
                ),
            ],
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
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepGreen.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SelectableLogoImage(
              height: isTablet ? 92 : 76,
              zovkhonTungalag: true,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          "Тавтай морилно уу",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontSize: isTablet ? 26.sp : 22.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Бүртгэлтэй утасны дугаар, нууц кодоо оруулна уу",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.65)
                : AppColors.lightTextSecondary.withValues(alpha: 0.8),
            fontSize: isTablet ? 14.sp : 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isDark, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsets cardPadding = screenWidth < 350
        ? EdgeInsets.all(16.r)
        : EdgeInsets.all(isTablet ? 26.r : 20.r);

    final operator = _getOperator(phoneController.text);

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B20) : Colors.white,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Утасны дугаар
          _buildFieldLabel("Утасны дугаар", isDark),
          SizedBox(height: 7.h),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: TextFormField(
              key: const ValueKey('login_phone_field'),
              controller: phoneController,
              focusNode: phoneFocusNode,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (val) {
                if (val.length == 8 && passwordController.text.isEmpty) {
                  passwordFocusNode.requestFocus();
                }
              },
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
              decoration: InputDecoration(
                hintText: "99112233",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey,
                  fontSize: 14.sp,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.phone_iphone_rounded,
                  color: AppColors.deepGreen,
                  size: 20.sp,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (operator != null)
                      Container(
                        margin: EdgeInsets.only(right: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getOperatorColor(operator).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          operator,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: _getOperatorColor(operator),
                          ),
                        ),
                      ),
                    if (phoneController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 16.sp,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onPressed: () => phoneController.clear(),
                      ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 2. Нууц код
          _buildFieldLabel("Нууц код", isDark),
          SizedBox(height: 7.h),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: TextFormField(
              key: const ValueKey('login_password_field'),
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: _obscurePassword,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: "••••",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey,
                  fontSize: 16.sp,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.deepGreen,
                  size: 20.sp,
                ),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark ? Colors.white38 : Colors.grey,
                    size: 20.sp,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),

          // Нууц код мартсан холбоос
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.deepGreenLight
                    : AppColors.deepGreen,
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
              ),
              child: Text(
                "Нууц код мартсан?",
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // 3. Нэвтрэх товч + Биометр
          Row(
            children: [
              Expanded(
                child: _buildSubmitButton(
                  context: context,
                  onTap: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
              ),
              if (_biometricAvailable) ...[
                SizedBox(width: 10.w),
                _buildBiometricButton(
                  context: context,
                  onTap: _isLoading ? null : _authenticateWithBiometrics,
                  isDark: isDark,
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),

          // 4. Бүртгүүлэх холбоос
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Бүртгэлгүй юу? ",
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.lightTextSecondary,
                    fontSize: 13.sp,
                  ),
                ),
                GestureDetector(
                  onTap: _showRegistrationModal,
                  child: Text(
                    "Шинээр бүртгүүлэх",
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // 5. Гэр бүлийн урилгаар нэвтрэх
          _buildGerBulUrilgaTovch(isDark),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.75)
            : AppColors.lightTextSecondary,
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubmitButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isLoading ? context.inputGrayColor : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.deepGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: isLoading
            ? SizedBox(
                height: 22.h,
                width: 22.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 19.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Нэвтрэх",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
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
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 52.h,
          width: 52.h,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.deepGreen.withValues(alpha: 0.12)
                : AppColors.deepGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.deepGreen.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              _biometricIcon,
              color: AppColors.deepGreen,
              size: 26.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// Гэр бүлийн гишүүнээр уригдсан хүн кодоороо энд нэвтэрнэ.
  Widget _buildGerBulUrilgaTovch(bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: InkWell(
        onTap: () {
          final utas = phoneController.text.trim();
          context.push(
            utas.length == 8
                ? '/ger-bul-batalgaajuulakh?utas=$utas'
                : '/ger-bul-batalgaajuulakh',
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_rounded,
              size: 18.sp,
              color: AppColors.deepGreen,
            ),
            SizedBox(width: 8.w),
            Text(
              "Гэр бүлийн урилга ирсэн үү? ",
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              "Кодоор нэвтрэх",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
            ),
          ],
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
          backgroundColor: isDark ? const Color(0xFF1C2228) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.deepGreen.withValues(alpha: 0.12),
                ),
                child: Icon(_biometricIcon, color: AppColors.deepGreen, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? 'Face ID ашиглах уу?'
                      : 'Хурууны хээ ашиглах уу?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Дараагийн удаа илүү хурдан бөгөөд хялбар нэвтрэхийн тулд биометрийг идэвхжүүлэх үү?',
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
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
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                elevation: 0,
              ),
              child: Text(
                'Тийм, идэвхжүүлье',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(bool isDark) {
    return CommonAppFooter(isDark: isDark);
  }
}
