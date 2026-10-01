import 'dart:async';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/widgets/otp_code_input.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class NuutsUgSergeekh extends StatefulWidget {
  const NuutsUgSergeekh({super.key});

  @override
  State<NuutsUgSergeekh> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<NuutsUgSergeekh> {
  bool _isPhoneSubmitted = false;
  bool _isPinVerified = false;
  bool _isLoading = false;
  String _verifiedCode = '';
  String? _baiguullagiinId;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 30;
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

  Future<void> _validateAndSubmit() async {
    if (_isLoading) return;
    if (!_isPhoneSubmitted) {
      if (_phoneController.text.trim().isEmpty) {
        showGlassSnackBar(
          context,
          message: "Утасны дугаар оруулна уу",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
      if (_phoneController.text.length != 8) {
        showGlassSnackBar(
          context,
          message: "Утасны дугаар 8 оронтой байх ёстой",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Validate phone number and send verification code
        final validateResult = await ApiService.validatePhoneForPasswordReset(
          utas: _phoneController.text,
        );

        // Check if validation failed
        if (validateResult['success'] == false) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message: validateResult['message'] ?? "Дугаар бүртгэлтгүй байна",
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          return;
        }

        // Phone is registered and verification code sent successfully
        // Store baiguullagiinId from response
        if (mounted) {
          setState(() {
            _isPhoneSubmitted = true;
            _isLoading = false;
            _baiguullagiinId = validateResult['baiguullagiinId'];
          });
          showGlassSnackBar(
            context,
            message:
                validateResult['message'] ?? "Баталгаажуулах код илгээгдлээ",
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          _startResendTimer();

          Future.delayed(Duration.zero, () {
            _otpFocusNode.requestFocus();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: friendlyError(e),
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } else if (!_isPinVerified) {
      String pin = _otpController.text;
      if (pin.length == 4) {
        setState(() {
          _isLoading = true;
        });

        try {
          if (_baiguullagiinId == null) {
            throw Exception('БайгууллагийнId олдсонгүй');
          }

          await ApiService.verifySecretCode(
            utas: _phoneController.text,
            code: pin,
            purpose: 'password_reset',
            baiguullagiinId: _baiguullagiinId!,
          );

          if (mounted) {
            setState(() {
              _isPinVerified = true;
              _isLoading = false;
              _verifiedCode = pin;
            });
            showGlassSnackBar(
              context,
              message: "Баталгаажуулалт амжилттай!",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message: "Баталгаажуулах код буруу байна",
              icon: Icons.error,
              iconColor: Colors.red,
            );
            // Clear PIN fields on error
            _otpController.clear();
            _otpFocusNode.requestFocus();
          }
        }
      }
    } else {
      if (_newPasswordController.text.trim().isEmpty) {
        showGlassSnackBar(
          context,
          message: "Шинэ нууц код оруулна уу",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
      if (_newPasswordController.text.length != 4) {
        showGlassSnackBar(
          context,
          message: "Нууц код 4 оронтой тоо байх ёстой",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
      if (_confirmPasswordController.text.trim().isEmpty) {
        showGlassSnackBar(
          context,
          message: "Нууц кодоо давтан оруулна уу",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        showGlassSnackBar(
          context,
          message: "Нууц код таарахгүй байна",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.resetPassword(
          utas: _phoneController.text,
          code: _verifiedCode,
          shineNuutsUg: _newPasswordController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: "Нууц код амжилттай солигдлоо!",
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: friendlyError(e),
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40.w,
                              vertical: 30.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppLogo(),
                                SizedBox(
                                  height: context.responsiveSpacing(
                                    small: 30,
                                    medium: 34,
                                    large: 38,
                                    tablet: 42,
                                    veryNarrow: 24,
                                  ),
                                ),
                                Text(
                                  'Нууц код сэргээх',
                                  style: TextStyle(
                                    color: AppColors.grayColor,
                                    fontSize: context.responsiveFontSize(
                                      small: 22,
                                      medium: 24,
                                      large: 26,
                                      tablet: 28,
                                      veryNarrow: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: context.responsiveSpacing(
                                    small: 20,
                                    medium: 24,
                                    large: 28,
                                    tablet: 32,
                                    veryNarrow: 14,
                                  ),
                                ),
                                if (!_isPhoneSubmitted)
                                  _buildPhoneNumberField()
                                else if (!_isPinVerified)
                                  _buildSecretCodeField()
                                else
                                  _buildPasswordFields(),
                                SizedBox(
                                  height: context.responsiveSpacing(
                                    small: 16,
                                    medium: 18,
                                    large: 20,
                                    tablet: 22,
                                    veryNarrow: 12,
                                  ),
                                ),
                                if (_shouldShowContinueButton())
                                  AnimatedOpacity(
                                    opacity: _isButtonValid() ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: _buildContinueButton(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: OptimizedGlass(
                      borderRadius: BorderRadius.circular(16),
                      opacity: 0.12,
                      child: IconButton(
                        padding: const EdgeInsets.only(left: 7),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowContinueButton() {
    if (!_isPhoneSubmitted) {
      return _phoneController.text.isNotEmpty;
    } else if (!_isPinVerified) {
      return _otpController.text.length == 4;
    } else {
      return _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;
    }
  }

  bool _isButtonValid() {
    if (!_isPhoneSubmitted) {
      return _phoneController.text.length == 8;
    } else if (!_isPinVerified) {
      return _otpController.text.length == 4;
    } else {
      return _newPasswordController.text.length == 4 &&
          _confirmPasswordController.text.length == 4 &&
          _newPasswordController.text == _confirmPasswordController.text;
    }
  }

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.responsiveFontSize(
            small: 15,
            medium: 16,
            large: 17,
            tablet: 18,
            veryNarrow: 13,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        decoration: InputDecoration(
          hintText: 'Утасны дугаар',
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: context.responsiveFontSize(
              small: 15,
              medium: 16,
              large: 17,
              tablet: 18,
              veryNarrow: 13,
            ),
          ),
          filled: true,
          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 25.w,
            vertical: 16.h,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.grayColor,
              width: 1.5,
            ),
          ),
          suffixIcon: _phoneController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () => _phoneController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSecretCodeField() {
    return Column(
      children: [
        // Display phone number with edit button
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing(
              small: 25,
              medium: 28,
              large: 32,
              tablet: 36,
              veryNarrow: 18,
            ),
            vertical: context.responsiveSpacing(
              small: 18,
              medium: 20,
              large: 22,
              tablet: 24,
              veryNarrow: 14,
            ),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: AppColors.inputGrayColor.withOpacity(0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 10),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _phoneController.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsiveFontSize(
                    small: 16,
                    medium: 17,
                    large: 18,
                    tablet: 19,
                    veryNarrow: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPhoneSubmitted = false;
                    _timer?.cancel();
                    _canResend = false;
                    _resendSeconds = 30;
                    _otpController.clear();
                  });
                },
                child: Text(
                  'Солих',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: context.responsiveSpacing(
            small: 20,
            medium: 24,
            large: 28,
            tablet: 32,
            veryNarrow: 14,
          ),
        ),

        OtpCodeInput(
          controller: _otpController,
          focusNode: _otpFocusNode,
          autofocus: false,
          onChanged: (_) => setState(() {}),
          // Auto-submit when all 4 digits are filled (SMS autofill)
          onCompleted: (_) => _validateAndSubmit(),
        ),
        SizedBox(
          height: context.responsiveSpacing(
            small: 10,
            medium: 12,
            large: 14,
            tablet: 16,
            veryNarrow: 8,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _canResend
                  ? () async {
                      _otpController.clear();

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final resendResult =
                            await ApiService.validatePhoneForPasswordReset(
                              utas: _phoneController.text,
                            );

                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          showGlassSnackBar(
                            context,
                            message:
                                resendResult['message'] ??
                                "Баталгаажуулах код дахин илгээлээ",
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                          );
                          _startResendTimer();
                          _otpFocusNode.requestFocus();
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          showGlassSnackBar(
                            context,
                            message: friendlyError(e, fallback: 'Утасны дугаар шалгаж чадсангүй. Дахин оролдоно уу.'),
                            icon: Icons.error,
                            iconColor: Colors.red,
                          );
                        }
                      }
                    }
                  : null,
              child: Text(
                _canResend ? 'Дахин илгээх' : 'Дахин илгээх ($_resendSeconds)',
                style: TextStyle(
                  color: _canResend ? Colors.blue : Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 10),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            keyboardType: TextInputType.number,
            style: TextStyle(
          color: Colors.white,
          fontSize: context.responsiveFontSize(
            small: 15,
            medium: 16,
            large: 17,
            tablet: 18,
            veryNarrow: 13,
          ),
        ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'Шинэ нууц код (4 орон)',
              hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: context.responsiveFontSize(
              small: 15,
              medium: 16,
              large: 17,
              tablet: 18,
              veryNarrow: 13,
            ),
          ),
              filled: true,
              fillColor: AppColors.inputGrayColor.withOpacity(0.5),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 25.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(
                  color: AppColors.grayColor,
                  width: 1.5,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_newPasswordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () => _newPasswordController.clear(),
                    ),
                  IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: context.responsiveSpacing(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 12,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 10),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            keyboardType: TextInputType.number,
            style: TextStyle(
          color: Colors.white,
          fontSize: context.responsiveFontSize(
            small: 15,
            medium: 16,
            large: 17,
            tablet: 18,
            veryNarrow: 13,
          ),
        ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'Нууц код давтах',
              hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: context.responsiveFontSize(
              small: 15,
              medium: 16,
              large: 17,
              tablet: 18,
              veryNarrow: 13,
            ),
          ),
              filled: true,
              fillColor: AppColors.inputGrayColor.withOpacity(0.5),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 25.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(
                  color: AppColors.grayColor,
                  width: 1.5,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_confirmPasswordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () => _confirmPasswordController.clear(),
                    ),
                  IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    bool isValid = false;

    if (!_isPhoneSubmitted) {
      isValid = _phoneController.text.length == 8;
    } else if (!_isPinVerified) {
      isValid = _otpController.text.length == 4;
    } else {
      isValid =
          _newPasswordController.text.length == 4 &&
          _confirmPasswordController.text.length == 4 &&
          _newPasswordController.text == _confirmPasswordController.text;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (isValid && !_isLoading) ? _validateAndSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCAD2DB),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text('Үргэлжлүүлэх', style: TextStyle(fontSize: 16.sp)),
        ),
      ),
    );
  }
}
