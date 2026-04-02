import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';

class RegistrationModal extends StatefulWidget {
  final String? initialPhone;

  const RegistrationModal({super.key, this.initialPhone});

  @override
  State<RegistrationModal> createState() => _RegistrationModalState();
}

enum RegistrationStep { phone, otp, password, biometric }

class _RegistrationModalState extends State<RegistrationModal> {
  RegistrationStep _currentStep = RegistrationStep.phone;
  bool _isLoading = false;

  // Step 1: Phone
  final TextEditingController _phoneController = TextEditingController();

  // Step 2: OTP
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  bool _enableBiometric = false;

  // Step 3: Password
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  IconData _biometricIcon = Icons.fingerprint;



  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Pre-fill phone number if provided from login
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Standard health check
      await UpdateService.checkForUpdate();
      
      // Load biometric availability
      final isAvailable = await BiometricService.isAvailable();
      final icon = await BiometricService.getBiometricIcon();
      if (mounted) {
        setState(() {
          _biometricAvailable = isAvailable;
          _biometricIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('Registration init error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendSeconds = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _handlePhoneSubmit() async {
    if (_phoneController.text.length != 8) return;

    setState(() => _isLoading = true);
    try {
<<<<<<< HEAD
      // 1. Check if phone is already registered
=======
      // Check if phone already registered
>>>>>>> 2ae09eb (a)
      final exists = await ApiService.checkPhoneExists(
        utas: _phoneController.text.trim(),
      );
      if (exists != null) {
        throw Exception('Энэ дугаар аль хэдийн бүртгэгдсэн байна');
      }

<<<<<<< HEAD
      // 2. Load baiguullagiinId for OTP request
      final baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId() 
          ?? '698e7fd3b6dd386b6c56a808'; // Default Pure Wallet Org ID

      // 3. Send OTP
      await ApiService.verifyPhoneNumber(
        baiguullagiinId: baiguullagiinId,
        purpose: 'registration',
=======
      // Get org id for OTP
      final baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId() ?? '698e7fd3b6dd386b6c56a808';

      // Send OTP
      await ApiService.verifyPhoneNumber(
        baiguullagiinId: baiguullagiinId,
        purpose: 'signup',
>>>>>>> 2ae09eb (a)
        utas: _phoneController.text.trim(),
        duureg: '',
        horoo: '',
        soh: '',
      );

      if (mounted) {
        setState(() {
          _currentStep = RegistrationStep.otp;
          _isLoading = false;
        });
        _startTimer();
<<<<<<< HEAD
        
        // Auto-focus first PIN box
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
        
        showGlassSnackBar(
          context,
          message: 'Баталгаажуулах код илгээлээ',
          icon: Icons.check_circle,
        );
=======
        Future.delayed(Duration.zero, () => _otpFocusNodes[0].requestFocus());
>>>>>>> 2ae09eb (a)
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error,
      );
    }
  }

  Future<void> _handleOtpSubmit() async {
    final pin = _otpControllers.map((c) => c.text).join();
<<<<<<< HEAD
    if (pin.length != 4) return;

    setState(() => _isLoading = true);
    try {
      final baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId()
          ?? '698e7fd3b6dd386b6c56a808';

=======
    if (pin.length != 4) {
      showGlassSnackBar(context, message: '4 оронтой код оруулна уу', icon: Icons.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId() ?? '698e7fd3b6dd386b6c56a808';
>>>>>>> 2ae09eb (a)
      await ApiService.verifySecretCode(
        utas: _phoneController.text.trim(),
        code: pin,
        baiguullagiinId: baiguullagiinId,
<<<<<<< HEAD
        purpose: 'registration',
      );

=======
        purpose: 'signup',
      );
>>>>>>> 2ae09eb (a)
      if (mounted) {
        setState(() {
          _currentStep = RegistrationStep.password;
          _isLoading = false;
        });
<<<<<<< HEAD
        showGlassSnackBar(
          context,
          message: 'Баталгаажуулалт амжилттай',
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: 'Баталгаажуулах код буруу байна',
        icon: Icons.error,
      );
    }
  }

=======
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showGlassSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          icon: Icons.error,
        );
        for (var c in _otpControllers) c.clear();
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final baiguullagiinId = await StorageService.getWalletBairBaiguullagiinId() ?? '698e7fd3b6dd386b6c56a808';
      await ApiService.verifyPhoneNumber(
        baiguullagiinId: baiguullagiinId,
        purpose: 'signup',
        utas: _phoneController.text.trim(),
        duureg: '',
        horoo: '',
        soh: '',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        for (var c in _otpControllers) c.clear();
        _startTimer();
        _otpFocusNodes[0].requestFocus();
        showGlassSnackBar(context, message: 'Код дахин илгээлээ', icon: Icons.check_circle, iconColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showGlassSnackBar(context, message: 'Алдаа гарлаа', icon: Icons.error);
      }
    }
  }

  void _handleOtpChange(String value, int index) {
    if (value.length == 1 && index < 3) _otpFocusNodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
    if (_otpControllers.map((c) => c.text).join().length == 4) _handleOtpSubmit();
  }

>>>>>>> 2ae09eb (a)
  Future<void> _handlePasswordSubmit() async {
    if (_passwordController.text.length != 4 ||
        _passwordController.text != _confirmPasswordController.text) {
      showGlassSnackBar(
        context,
        message: 'Нууц код таарахгүй байна',
        icon: Icons.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final savedBaiguullagiinId =
          await StorageService.getWalletBairBaiguullagiinId();
      final registrationData = {
        'utas': _phoneController.text.trim(),
        'nuutsUg': _passwordController.text.trim(),
        'baiguullagiinId':
            savedBaiguullagiinId ??
            '698e7fd3b6dd386b6c56a808', // Use saved or Pure Wallet Org ID
        'tsahilgaaniiZaalt':
            200, // Default value as used in other registration screens
      };

      final response = await ApiService.registerUser(registrationData);

      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Бүртгэл үүсгэхэд алдаа гарлаа');
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        setState(() {
          _currentStep = RegistrationStep.biometric;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error,
      );
    }
  }

  Future<void> _handleBiometricSetup(bool enable) async {
    setState(() => _isLoading = true);
    if (enable) {
      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        setState(() {
          _enableBiometric = true;
          _isLoading = false;
        });
        _finishRegistration();
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      _finishRegistration();
    }
  }

  Future<void> _finishRegistration() async {
    if (_enableBiometric) {
      await StorageService.savePasswordForBiometric(
        _passwordController.text.trim(),
      );
      await StorageService.setBiometricEnabled(true);
    }

    if (mounted) {
      showGlassSnackBar(
        context,
        message: 'Амжилттай бүртгүүллээ!',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      Navigator.pop(context);
      // Navigate to address selection as requested
      context.go('/address_selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.w,
        right: 24.w,
        top: 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle/Indicator
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(isDark),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case RegistrationStep.phone:
        return _buildPhoneStep(isDark);
      case RegistrationStep.password:
        return _buildPasswordStep(isDark);
      case RegistrationStep.otp:
        return _buildOtpStep(isDark);
      case RegistrationStep.biometric:
        return _buildBiometricStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStep(bool isDark) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Бүртгүүлэх',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
<<<<<<< HEAD
          'Бүртгүүлж үйлчилгээ авахын тулд утасны дугаараа баталгаажуулна уу.',
=======
          'Утасны дугаараа оруулна уу. Баталгаажуулах код илгээж бүртгэлийг баталгаажуулна.',
>>>>>>> 2ae09eb (a)
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        SizedBox(height: 24.h),
        _buildInputField(
          label: 'Утасны дугаар',
          hint: '99001122',
          controller: _phoneController,
          icon: Icons.phone_android_rounded,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
        ),
        SizedBox(height: 24.h),
        _buildPrimaryButton(
          onTap: _isLoading ? null : _handlePhoneSubmit,
          label: 'Үргэлжлүүлэх',
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPasswordStep(bool isDark) {
    return Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Нууц код тохируулах',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Аппликейшнд нэвтрэх 4 оронтой нууц кодоо оруулна уу.',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        SizedBox(height: 24.h),
        _buildInputField(
          label: 'Шинэ нууц код',
          hint: '••••',
          controller: _passwordController,
          icon: Icons.lock_rounded,
          isDark: isDark,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20.sp,
              color: AppColors.deepGreen.withOpacity(0.5),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          label: 'Нууц код давтах',
          hint: '••••',
          controller: _confirmPasswordController,
          icon: Icons.lock_clock_rounded,
          isDark: isDark,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                onTap: () =>
                    setState(() => _currentStep = RegistrationStep.phone),
                label: 'Буцах',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPrimaryButton(
                onTap: _isLoading ? null : _handlePasswordSubmit,
                label: 'Дуусгах',
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometricStep(bool isDark) {
    return Column(
      key: const ValueKey('biometric'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(_biometricIcon, size: 72.sp, color: AppColors.deepGreen),
        SizedBox(height: 24.h),
        Text(
          'Биометрээр нэвтрэх',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Та дараагийн удаа нэвтрэхдээ нууц код ашиглахгүйгээр хурдан нэвтрэх боломжтой.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        SizedBox(height: 32.h),
        _buildPrimaryButton(
          onTap: _isLoading ? null : () => _handleBiometricSetup(true),
          label: 'Идэвхижүүлэх',
          isLoading: _isLoading,
        ),
        SizedBox(height: 12.h),
        _buildSecondaryButton(
          onTap: _isLoading ? null : () => _handleBiometricSetup(false),
          label: 'Дараа тохируулъя',
        ),
      ],
    );
  }

  Widget _buildOtpStep(bool isDark) {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
<<<<<<< HEAD
          'Баталгаажуулах',
=======
          'Утас баталгаажуулах',
>>>>>>> 2ae09eb (a)
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
<<<<<<< HEAD
        Text(
          '${_phoneController.text} дугаарт илгээсэн 4 оронтой кодыг оруулна уу.',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        SizedBox(height: 32.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 55.w,
              child: Container(
                constraints: BoxConstraints(minHeight: 65.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _otpFocusNodes[index].hasFocus 
                        ? AppColors.deepGreen 
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    width: 1.5,
                  ),
                ),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_otpControllers[index].text.isEmpty && index > 0) {
                        _otpControllers[index - 1].clear();
                        _otpFocusNodes[index - 1].requestFocus();
                        setState(() {});
                      }
                    }
                  },
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.0, // Prevent vertical displacement
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
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        // This case is also covered by KeyboardListener but keeps it consistent
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _handleOtpSubmit();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 32.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _resendSeconds > 0
                ? Text(
                    'Дахин илгээх (${_resendSeconds}с)',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                  )
                : TextButton(
                    onPressed: _isLoading ? null : _handlePhoneSubmit,
                    child: Text(
                      'Дахин илгээх',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.deepGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            TextButton(
              onPressed: () => setState(() => _currentStep = RegistrationStep.phone),
              child: Text(
                'Дугаар солих',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
=======
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _phoneController.text.trim(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
              ),
              TextSpan(
                text: ' дугаарт илгээсэн 4 оронтой кодыг оруулна уу.',
                style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => SizedBox(
            width: 60.w,
            child: TextField(
              controller: _otpControllers[i],
              focusNode: _otpFocusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F2F5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.deepGreen, width: 2.5),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _handleOtpChange(v, i),
            ),
          )),
        ),
        SizedBox(height: 16.h),
        Center(
          child: TextButton(
            onPressed: _canResend && !_isLoading ? _resendOtp : null,
            child: Text(
              _canResend ? 'Код дахин илгээх' : 'Дахин илгээх ($_resendSeconds с)',
              style: TextStyle(
                color: _canResend && !_isLoading ? AppColors.deepGreen : (isDark ? Colors.white38 : Colors.black38),
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        _buildPrimaryButton(
          onTap: _isLoading ? null : _handleOtpSubmit,
          label: 'Баталгаажуулах',
          isLoading: _isLoading,
        ),
        SizedBox(height: 12.h),
        _buildSecondaryButton(
          onTap: () => setState(() => _currentStep = RegistrationStep.phone),
          label: 'Буцах',
>>>>>>> 2ae09eb (a)
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(icon, color: AppColors.deepGreen, size: 20.sp),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              filled: false, // Ensure we don't have double filling
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
    required VoidCallback? onTap,
    required String label,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.withOpacity(0.3)
              : AppColors.deepGreen,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            if (onTap != null)
              BoxShadow(
                color: AppColors.deepGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
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
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.deepGreen.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.deepGreen,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
