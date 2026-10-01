import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/widgets/otp_code_input.dart';

class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

enum ForgotPasswordStep { phone, otp, password }

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.phone;
  bool _isLoading = false;
  String? _baiguullagiinId;
  String _verifiedCode = '';

  // Step 1: Phone
  final TextEditingController _phoneController = TextEditingController();

  // Step 2: OTP
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _resendSeconds = 30;
  Timer? _timer;

  // Step 3: Password
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _handlePhoneSubmit() async {
    if (_phoneController.text.length != 8) return;

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.validatePhoneForPasswordReset(
        utas: _phoneController.text.trim(),
      );

      if (result['success'] == false) {
        throw Exception(result['message'] ?? 'Дугаар бүртгэлтгүй байна');
      }

      setState(() {
        _baiguullagiinId = result['baiguullagiinId'];
        _currentStep = ForgotPasswordStep.otp;
        _isLoading = false;
      });
      _startTimer();

      // Auto focus first OTP field
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNode.requestFocus();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: friendlyError(
          e,
          fallback: 'Утасны дугаар шалгаж чадсангүй. Дахин оролдоно уу.',
        ),
        icon: Icons.error,
      );
    }
  }

  Future<void> _handleOtpSubmit() async {
    String otp = _otpController.text;
    // Автоматаар илгээх үед давхар дуудагдахаас сэргийлнэ
    if (otp.length != 4 || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      if (_baiguullagiinId == null)
        throw Exception('Байгууллагийн мэдээлэл олдсонгүй');

      await ApiService.verifySecretCode(
        utas: _phoneController.text.trim(),
        code: otp,
        purpose: 'password_reset',
        baiguullagiinId: _baiguullagiinId!,
      );

      setState(() {
        _verifiedCode = otp;
        _currentStep = ForgotPasswordStep.password;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: friendlyError(
          e,
          fallback: 'Баталгаажуулах код буруу байна. Дахин оролдоно уу.',
        ),
        icon: Icons.error,
      );
      _otpController.clear();
      _otpFocusNode.requestFocus();
    }
  }

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
      await ApiService.resetPassword(
        utas: _phoneController.text.trim(),
        code: _verifiedCode,
        shineNuutsUg: _passwordController.text.trim(),
      );

      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Нууц код амжилттай солигдлоо!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: friendlyError(
          e,
          fallback: 'Нууц үг сэргээж чадсангүй. Дахин оролдоно уу.',
        ),
        icon: Icons.error,
      );
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
      // Жижиг дэлгэцэнд гар нээгдэхэд хальж гарахгүй
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case ForgotPasswordStep.phone:
        return _buildPhoneStep(isDark);
      case ForgotPasswordStep.otp:
        return _buildOtpStep(isDark);
      case ForgotPasswordStep.password:
        return _buildPasswordStep(isDark);
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
          'Нууц код сэргээх',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Бүртгэлтэй утасны дугаараа оруулж баталгаажуулах код авна уу.',
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
          label: 'Код авах',
          isLoading: _isLoading,
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
          'Баталгаажуулах',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '${_phoneController.text} дугаарт илгээсэн 4 оронтой кодыг оруулна уу.',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        SizedBox(height: 32.h),
        OtpCodeInput(
          controller: _otpController,
          focusNode: _otpFocusNode,
          autofocus: false,
          onCompleted: (_) => _handleOtpSubmit(),
        ),
        SizedBox(height: 32.h),
        Center(
          child: _resendSeconds > 0
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        SizedBox(height: 12.h),
        _buildSecondaryButton(
          onTap: () => setState(() => _currentStep = ForgotPasswordStep.phone),
          label: 'Дугаар солих',
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
          'Шинэ нууц код',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Шинэ 4 оронтой нууц кодоо оруулна уу.',
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
        _buildPrimaryButton(
          onTap: _isLoading ? null : _handlePasswordSubmit,
          label: 'Нууц код шинэчлэх',
          isLoading: _isLoading,
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
              filled: false,
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
                  fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
