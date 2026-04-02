import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/widgets/common_footer.dart';

enum SignupStep { phone, otp, password }

/// Modern minimal background with subtle gradient
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      height: double.infinity,
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

class BurtguulekhSignup extends StatefulWidget {
  /// If true, this screen must behave as "NO baiguullagiinId" signup,
  /// even if some old orgId exists in storage from a previous session.
  final bool forceNoOrg;

  /// When completing profile for WEB-created users, pass their orgId explicitly.
  final String? baiguullagiinId;

  /// Optional prefill
  final String? prefillPhone;
  const BurtguulekhSignup({
    super.key,
    this.forceNoOrg = false,
    this.baiguullagiinId,
    this.prefillPhone,
  });

  @override
  State<BurtguulekhSignup> createState() => _BurtguulekhSignupState();
}

class _BurtguulekhSignupState extends State<BurtguulekhSignup> {
  // Step: 0 = phone, 1 = OTP, 2 = password+register
  int _step = 0;

  // Form keys per step
  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // OTP / PIN
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _resendTimer;

  // Org info
  String? _baiguullagiinId;
  final int _tsahilgaaniiZaalt = 200;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step handling
  SignupStep _currentStep = SignupStep.phone;
  String _verifiedCode = '';

  // PIN Controllers & FocusNodes
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  // Timer for resend
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();

    if (widget.prefillPhone != null && widget.prefillPhone!.trim().isNotEmpty) {
      _phoneController.text = widget.prefillPhone!.trim();
    }

    if (widget.forceNoOrg) {
      _baiguullagiinId = null;
      return;
    }

    final providedId = (widget.baiguullagiinId ?? '').trim();
    if (providedId.isNotEmpty && providedId.toLowerCase() != 'null') {
      _baiguullagiinId = providedId;
      return;
    }

    _loadAutoFillData();
  }

  Future<void> _loadAutoFillData() async {
    final savedBaiguullagiinId =
        await StorageService.getWalletBairBaiguullagiinId();

    final normalizedBaiguullagiinId = (savedBaiguullagiinId ?? '').trim();
    final baiguullagiinId =
        normalizedBaiguullagiinId.isEmpty ||
            normalizedBaiguullagiinId.toLowerCase() == 'null'
        ? null
        : normalizedBaiguullagiinId;

    if (mounted) {
      setState(() {
        _baiguullagiinId = baiguullagiinId;
      });
    }
  }

  bool get _hasOrg {
    final id = (_baiguullagiinId ?? widget.baiguullagiinId ?? '').trim();
    return id.isNotEmpty && id.toLowerCase() != 'null';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Timer ───────────────────────────────────────────
  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendSeconds > 0) { _resendSeconds--; } else { _canResend = true; t.cancel(); }
      });
    });
  }

  // ─── Step 0 → 1: Send OTP ────────────────────────────
  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_hasOrg) {
      try {
        await ApiService.verifyPhoneNumber(
          baiguullagiinId: _orgId,
          purpose: 'signup',
          utas: _phoneController.text.trim(),
          duureg: '',
          horoo: '',
          soh: '',
        );
      } catch (e) {
        debugPrint('OTP send warning (still advancing): $e');
      }
      if (mounted) {
        setState(() { _isLoading = false; _step = 1; });
        _startResendTimer();
        Future.delayed(Duration.zero, () => _pinFocusNodes[0].requestFocus());
      }
    } else {
      // No org — skip OTP and go straight to password step
      if (mounted) setState(() { _isLoading = false; _step = 2; });
    }
  }

  // ─── Resend OTP ───────────────────────────────────────
  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.verifyPhoneNumber(
        baiguullagiinId: _orgId,
        purpose: 'signup',
        utas: _phoneController.text.trim(),
        duureg: '',
        horoo: '',
        soh: '',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        for (var c in _pinControllers) c.clear();
        _startResendTimer();
        _pinFocusNodes[0].requestFocus();
        showGlassSnackBar(context, message: 'Код дахин илгээлээ', icon: Icons.check_circle, iconColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showGlassSnackBar(context, message: 'Алдаа гарлаа', icon: Icons.error, iconColor: Colors.red);
      }
    }
  }

  // ─── Step 1 → 2: Verify OTP ──────────────────────────
  Future<void> _verifyOtp() async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length != 4) {
      showGlassSnackBar(context, message: '4 оронтой код оруулна уу', icon: Icons.error, iconColor: Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.verifySecretCode(
        utas: _phoneController.text.trim(),
        code: pin,
        baiguullagiinId: _orgId.isNotEmpty ? _orgId : 'default',
        purpose: 'signup',
      );
      if (mounted) setState(() { _isLoading = false; _step = 2; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        showGlassSnackBar(context, message: msg.isNotEmpty ? msg : 'Баталгаажуулах код буруу байна', icon: Icons.error, iconColor: Colors.red);
        for (var c in _pinControllers) c.clear();
        _pinFocusNodes[0].requestFocus();
      }
    }
  }

  void _handlePinChange(String value, int index) {
    if (value.length == 1 && index < 3) _pinFocusNodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) _pinFocusNodes[index - 1].requestFocus();
    if (_pinControllers.map((c) => c.text).join().length == 4) _verifyOtp();
  }

  // ─── Step 2: Register ─────────────────────────────────
  Future<void> _register() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final registrationData = <String, dynamic>{
        'utas': _phoneController.text.trim(),
        'nuutsUg': _passwordController.text.trim(),
        'code': _verifiedCode, // Matching "like password reset"
      };

      final savedCustomerId = await StorageService.getWalletCustomerId();
      if (savedCustomerId != null && savedCustomerId.isNotEmpty) {
        registrationData['customerId'] = savedCustomerId;
      }
      if (_hasOrg) {
        registrationData['baiguullagiinId'] = _orgId;
        registrationData['tsahilgaaniiZaalt'] = _tsahilgaaniiZaalt;
      }

      final response = await ApiService.registerUser(registrationData);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response['success'] == false) {
          showGlassSnackBar(
            context,
            message: response['message'] ?? response['aldaa'] ?? 'Бүртгэл үүсгэхэд алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        showGlassSnackBar(context, message: 'Бүртгэл амжилттай үүслээ! Нэвтэрч байна...', icon: Icons.check_circle, iconColor: Colors.green);

        bool loginSuccess = false;
        try {
          await ApiService.loginUser(utas: _phoneController.text.trim(), nuutsUg: _passwordController.text.trim());
          await StorageService.savePhoneNumber(_phoneController.text.trim());
          loginSuccess = true;
        } catch (e) {
          debugPrint('Auto-login failed: $e');
        }

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          if (!_hasOrg && loginSuccess) {
            context.go('/address_selection');
          } else if (loginSuccess) {
            final showIntro = await StorageService.getTaniltsuulgaKharakhEsekh();
            context.go(showIntro ? '/ekhniikh' : '/nuur');
          } else {
            context.go('/newtrekh');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        showGlassSnackBar(context, message: msg, icon: Icons.error, iconColor: Colors.red);
      }
    }
  }

  // ─── Build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isTablet = ScreenUtil().screenWidth > 700;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8FAFB),
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 16.h),
                                    
                                    // Logo matched with login screen
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
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
                                        SizedBox(
                                          width: 100.w,
                                          height: 100.w,
                                          child: const SelectableLogoImage(
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Title matched with login screen
                                    Text(
                                      'Бүртгэл дуусгах',
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
                                      'Бүртгүүлээд үйлчилгээ авах боломжтой.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.5)
                                            : AppColors.lightTextSecondary
                                                  .withOpacity(0.7),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    _buildInputField(
                                      controller: _phoneController,
                                      labelText: 'Утасны дугаар',
                                      hintText: '8888****',
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone_iphone_rounded,
                                      isDark: isDark,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(8),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Утасны дугаар оруулна уу';
                                        if (value.length != 8) return 'Дугаар 8 оронтой байх ёстой';
                                        return null;
                                      },
                                    ),

                                    _buildInputField(
                                      controller: _passwordController,
                                      labelText: 'Нууц код (4 оронтой)',
                                      hintText: '****',
                                      keyboardType: TextInputType.number,
                                      obscureText: _obscurePassword,
                                      icon: Icons.lock_rounded,
                                      isDark: isDark,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          color: AppColors.deepGreen.withOpacity(0.6),
                                          size: 20.sp,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Нууц код оруулна уу';
                                        if (value.length != 4) return 'Нууц код 4 оронтой байх ёстой';
                                        return null;
                                      },
                                    ),

                                    _buildInputField(
                                      controller: _confirmPasswordController,
                                      labelText: 'Нууц код давтах',
                                      hintText: '****',
                                      keyboardType: TextInputType.number,
                                      obscureText: _obscureConfirmPassword,
                                      icon: Icons.lock_rounded,
                                      isDark: isDark,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          color: AppColors.deepGreen.withOpacity(0.6),
                                          size: 20.sp,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Нууц кодыг давтаж оруулна уу';
                                        if (value != _passwordController.text) return 'Нууц код таарахгүй байна';
                                        return null;
                                      },
                                    ),

                                    SizedBox(height: 32.h),
                                    
                                    _buildButton(
                                      onTap: _isLoading ? null : _handleRegistration,
                                      label: 'Бүртгүүлэх',
                                      isLoading: _isLoading,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTransparentButton(
                                      onTap: () => context.go('/newtrekh'),
                                      label: 'Буцах',
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: CommonAppFooter(isDark: isDark),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : AppColors.lightTextSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 8.h),
        Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
              filled: false, // Prevent theme from causing double-box look
              prefixIcon: Icon(icon, color: AppColors.deepGreen, size: 20.sp),
              suffixIcon: suffixIcon,
              counterText: '',
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPinInputRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 55.w,
          child: Container(
            constraints: BoxConstraints(minHeight: 65.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _pinFocusNodes[index].hasFocus
                    ? AppColors.deepGreen
                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
                width: 1.5,
              ),
            ),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_pinControllers[index].text.isEmpty && index > 0) {
                    _pinControllers[index - 1].clear();
                    _pinFocusNodes[index - 1].requestFocus();
                    setState(() {});
                  }
                }
              },
              child: TextField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.0, // Set to 1.0 to prevent vertical displacement
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  filled: false, 
                  contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    _pinFocusNodes[index + 1].requestFocus();
                  }

                  // Auto verify if all 4 digits are entered
                  if (_pinControllers.every((c) => c.text.isNotEmpty)) {
                    _handleVerifyOtp();
                  }
                  setState(() {});
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Primary button ───────────────────────────────────
  Widget _buildButton({required VoidCallback? onTap, required String label, bool isLoading = false, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: (onTap == null || isLoading) ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.5)] : [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [if (onTap != null && !isLoading) BoxShadow(color: AppColors.deepGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: isLoading
            ? Center(child: SizedBox(width: 22.r, height: 22.r, child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
            : Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  // ─── Ghost button ─────────────────────────────────────
  Widget _buildTransparentButton({required VoidCallback onTap, required String label, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 15.sp, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

