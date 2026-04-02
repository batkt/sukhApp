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
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Hidden fields
  String? _baiguullagiinId;
  int _tsahilgaaniiZaalt = 200; // Default value

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    try {
      // 1. Check for app updates (Standard health check)
      await UpdateService.checkForUpdate();

      // 2. Load orgId/baiguullagiinId
      if (!widget.forceNoOrg) {
        final providedId = (widget.baiguullagiinId ?? '').trim();
        if (providedId.isNotEmpty && providedId.toLowerCase() != 'null') {
          _baiguullagiinId = providedId;
        } else {
          _baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId();
        }
      }

      // 3. If user is potentially logged in (completing profile), fetch their profile
      final isLoggedIn = await StorageService.isLoggedIn();
      if (isLoggedIn) {
        final profile = await ApiService.getUserProfile();
        if (profile['success'] == true && profile['result'] != null) {
          final userData = profile['result'];
          if (_phoneController.text.isEmpty && userData['utas'] != null) {
            final phone = userData['utas'] is List
                ? userData['utas'][0].toString()
                : userData['utas'].toString();
            _phoneController.text = phone;
          }
          // If already logged in, they already verified their number. Skip to password.
          _currentStep = SignupStep.password;
        }
      }
    } catch (e) {
      debugPrint('Error during signup initialization: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasBaiguullagiinId {
    final id = (_baiguullagiinId ?? '').trim();
    return id.isNotEmpty && id.toLowerCase() != 'null';
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 8) {
      showGlassSnackBar(
        context,
        message: 'Утасны дугаар оруулна уу',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    if (!_hasBaiguullagiinId) {
      showGlassSnackBar(
        context,
        message: 'Байгууллагын мэдээлэл олдсонгүй. Хаягаа дахин сонгоно уу.',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Standard duplicate resident check before sending OTP (Only for new registrations)
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!isLoggedIn) {
        final exists = await ApiService.checkPhoneExists(utas: phone);
        if (exists != null) {
          if (mounted) {
            showGlassSnackBar(
              context,
              message: 'Энэ дугаар аль хэдийн бүртгэгдсэн байна',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final response = await ApiService.verifyPhoneNumber(
        baiguullagiinId: _baiguullagiinId!,
        purpose: 'registration',
        utas: phone,
        duureg: '', // Backend handles these if needed, but not strictly required for sending OTP
        horoo: '',
        soh: '',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = SignupStep.otp;
        });
        _startResendTimer();
        
        // Focus first PIN box
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _pinFocusNodes[0].requestFocus();
        });

        showGlassSnackBar(
          context,
          message: response['message'] ?? 'Баталгаажуулах код илгээгдлээ',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.toString();
        if (msg.contains('409') || msg.contains('бүртгэгдсэн')) {
          msg = 'Энэ утасны дугаар аль хэдийн бүртгэгдсэн байна!';
        } else if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        
        showGlassSnackBar(
          context,
          message: msg,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length != 4) {
      showGlassSnackBar(
        context,
        message: '4 оронтой код оруулна уу',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifySecretCode(
        utas: _phoneController.text.trim(),
        code: pin,
        baiguullagiinId: _baiguullagiinId!,
        purpose: 'registration',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = SignupStep.password;
          _verifiedCode = pin;
        });

        showGlassSnackBar(
          context,
          message: response['message'] ?? 'Дугаар амжилттай баталгаажлаа!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        
        showGlassSnackBar(
          context,
          message: msg,
          icon: Icons.error,
          iconColor: Colors.red,
        );
        // Clear PIN on error
        for (var c in _pinControllers) {
          c.clear();
        }
        _pinFocusNodes[0].requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      final id = (_baiguullagiinId ?? widget.baiguullagiinId ?? '').trim();
      if (id.isNotEmpty && id.toLowerCase() != 'null') {
        registrationData['baiguullagiinId'] = id;
        registrationData['tsahilgaaniiZaalt'] = _tsahilgaaniiZaalt;
      }

      final response = await ApiService.registerUser(registrationData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success'] == false) {
          final errorMessage =
              response['message'] ??
              response['aldaa'] ??
              'Бүртгэл үүсгэхэд алдаа гарлаа';

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        showGlassSnackBar(
          context,
          message: 'Бүртгэл амжилттай үүслээ! Нэвтэрч байна...',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        bool loginSuccess = false;
        try {
          await ApiService.loginUser(
            utas: _phoneController.text.trim(),
            nuutsUg: _passwordController.text.trim(),
          );
          await StorageService.savePhoneNumber(_phoneController.text.trim());
          loginSuccess = true;
        } catch (e) {
          debugPrint('Автоматаар нэвтрэх үед алдаа гарлаа: $e');
        }

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          final hasOrgId = (_baiguullagiinId ?? widget.baiguullagiinId ?? '')
              .trim()
              .isNotEmpty;
              
          if (!hasOrgId && loginSuccess) {
            context.go('/address_selection');
          } else if (loginSuccess) {
            // Check taniltsuulga dynamically based on user
            final taniltsuulgaKharakhEsekh =
                await StorageService.getTaniltsuulgaKharakhEsekh();
            final targetRoute = taniltsuulgaKharakhEsekh ? '/ekhniikh' : '/nuur';
            context.go(targetRoute);
          } else {
            // Fallback to login screen if auto login fails
            context.go('/newtrekh');
          }
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

        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ScreenUtil().screenWidth > 700;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8FAFB),
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
                                      'Шинээр бүртгүүлж үйлчилгээ авах боломжтой.',
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

                                    if (_currentStep == SignupStep.phone) ...[
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
                                      SizedBox(height: 16.h),
                                      _buildButton(
                                        onTap: _isLoading ? null : _handleSendOtp,
                                        label: 'Үргэлжлүүлэх',
                                        isLoading: _isLoading,
                                        isDark: isDark,
                                      ),
                                    ] else if (_currentStep == SignupStep.otp) ...[
                                      Text(
                                        '${_phoneController.text} дугаарт илгээсэн\n4 оронтой кодыг оруулна уу',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                      _buildPinInputRow(isDark),
                                      SizedBox(height: 16.h),
                                      TextButton(
                                        onPressed: _canResend && !_isLoading ? _handleSendOtp : null,
                                        child: Text(
                                          _canResend ? 'Код дахин илгээх' : 'Код дахин илгээх ($_resendSeconds сек)',
                                          style: TextStyle(
                                            color: _canResend ? AppColors.deepGreen : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      _buildButton(
                                        onTap: _isLoading ? null : _handleVerifyOtp,
                                        label: 'Баталгаажуулах',
                                        isLoading: _isLoading,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 8.h),
                                      TextButton(
                                        onPressed: () => setState(() => _currentStep = SignupStep.phone),
                                        child: Text(
                                          'Дугаараа солих',
                                          style: TextStyle(
                                            color: isDark ? Colors.white38 : Colors.black38,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    ] else if (_currentStep == SignupStep.password) ...[
                                      _buildInputField(
                                        controller: _phoneController,
                                        labelText: 'Утасны дугаар',
                                        hintText: '8888****',
                                        keyboardType: TextInputType.phone,
                                        icon: Icons.phone_iphone_rounded,
                                        isDark: isDark,
                                        enabled: false,
                                      ),
                                      _buildInputField(
                                        controller: _passwordController,
                                        labelText: 'Шинэ нууц код (4 оронтой)',
                                        hintText: 'xxxx',
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
                                        label: 'Бүртгэл дуусгах',
                                        isLoading: _isLoading,
                                        isDark: isDark,
                                      ),
                                    ],
                                    SizedBox(height: 16.h),
                                    _buildTransparentButton(
                                      onTap: () {
                                        if (_currentStep == SignupStep.phone) {
                                          context.go('/newtrekh');
                                        } else if (_currentStep == SignupStep.otp) {
                                          setState(() => _currentStep = SignupStep.phone);
                                        } else {
                                          setState(() => _currentStep = SignupStep.otp);
                                        }
                                      },
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
        Text(
          labelText,
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.lightTextSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            enabled: enabled,
            style: TextStyle(
              color: isDark ? Colors.white : (enabled ? Colors.black : Colors.black38),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
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

  Widget _buildButton({
    required VoidCallback? onTap,
    required String label,
    bool isLoading = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: (onTap == null || isLoading)
                ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.5)]
                : [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            if (onTap != null && !isLoading)
              BoxShadow(
                color: AppColors.deepGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTransparentButton({
    required VoidCallback onTap,
    required String label,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
