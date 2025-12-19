import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/services/session_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? baiguullagiinId;
  final String? duureg;
  final String? horoo;
  final String? soh;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.baiguullagiinId,
    this.duureg,
    this.horoo,
    this.soh,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _isPhoneSubmitted = false;
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // OTP is automatically sent on successful login, so we just need to verify it
    // Show message that OTP was sent and start timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isPhoneSubmitted = true;
      });
      _startResendTimer();
      // Focus on first PIN field
      Future.delayed(Duration.zero, () {
        _pinFocusNodes[0].requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
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

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final baiguullagiinId =
          widget.baiguullagiinId ?? await StorageService.getBaiguullagiinId();

      if (baiguullagiinId == null || baiguullagiinId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: 'Байгууллагын мэдээлэл олдсонгүй',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      await ApiService.verifyPhoneNumber(
        baiguullagiinId: baiguullagiinId,
        purpose: "login",
        utas: widget.phoneNumber,
        duureg: widget.duureg ?? '',
        horoo: widget.horoo ?? '',
        soh: widget.soh ?? '',
      );

      if (mounted) {
        for (var controller in _pinControllers) {
          controller.clear();
        }

        setState(() {
          _isLoading = false;
        });

        showGlassSnackBar(
          context,
          message: "Баталгаажуулах код дахин илгээлээ",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        _startResendTimer();
        _pinFocusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showGlassSnackBar(
          context,
          message: "Алдаа гарлаа: $e",
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    String pin = _pinControllers.map((c) => c.text).join();
    if (pin.length != 4) {
      showGlassSnackBar(
        context,
        message: "4 оронтой код оруулна уу",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baiguullagiinId =
          widget.baiguullagiinId ?? await StorageService.getBaiguullagiinId();

      if (baiguullagiinId == null || baiguullagiinId.isEmpty) {
        throw Exception('БайгууллагийнId олдсонгүй');
      }

      // Use the login OTP verification endpoint
      await ApiService.verifyLoginOTP(
        utas: widget.phoneNumber,
        code: pin,
        baiguullagiinId: baiguullagiinId,
      );

      if (mounted) {
        // Mark phone as verified in storage
        await StorageService.setPhoneVerified(true);

        // Save current device ID as the verified device
        final deviceId = await StorageService.getOrCreateDeviceId();
        await StorageService.saveLastVerifiedDeviceId(deviceId);
        print('📱 [VERIFY] Phone verified on device: $deviceId');

        setState(() {
          _isLoading = false;
        });

        showGlassSnackBar(
          context,
          message: "Утас баталгаажлаа!",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        // Navigate back with success
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Extract error message
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        print('❌ [VERIFY_CODE] Error: $errorMessage');

        showGlassSnackBar(
          context,
          message: errorMessage.isNotEmpty
              ? errorMessage
              : "Баталгаажуулах код буруу байна",
          icon: Icons.error,
          iconColor: Colors.red,
        );

        for (var controller in _pinControllers) {
          controller.clear();
        }
        _pinFocusNodes[0].requestFocus();
      }
    }
  }

  void _handlePinChange(String value, int index) {
    if (value.length == 1 && index < 3) {
      _pinFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 4 digits are entered
    String pin = _pinControllers.map((c) => c.text).join();
    if (pin.length == 4 && _isPhoneSubmitted) {
      _verifyCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Clear auth data when user presses back - token was saved during login
        // but verification was cancelled, so we need to logout
        await SessionService.logout();
        // Return false to go back to login screen
        if (mounted) {
          context.pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
            onPressed: () async {
              // Clear auth data when user presses back - token was saved during login
              // but verification was cancelled, so we need to logout
              await SessionService.logout();
              // Return false to indicate verification was cancelled
              // This will keep user on login screen
              if (mounted) {
                context.pop(false);
              }
            },
          ),
          title: Text(
            'Утас баталгаажуулах',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: context.responsiveFontSize(
                small: 18,
                medium: 20,
                large: 22,
                tablet: 24,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: context.responsivePadding(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 20,
                    medium: 24,
                    large: 28,
                    tablet: 32,
                  ),
                ),
                // Phone number display
                Container(
                  padding: context.responsivePadding(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.secondaryAccent.withOpacity(0.3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 22,
                      ),
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.lightInputGray,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_android,
                        color: AppColors.deepGreen,
                        size: context.responsiveIconSize(
                          small: 24,
                          medium: 26,
                          large: 28,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: context.responsiveSpacing(
                          small: 12,
                          medium: 14,
                          large: 16,
                          tablet: 18,
                        ),
                      ),
                      Text(
                        widget.phoneNumber,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: context.responsiveFontSize(
                            small: 18,
                            medium: 20,
                            large: 22,
                            tablet: 24,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 32,
                    medium: 36,
                    large: 40,
                    tablet: 44,
                  ),
                ),
                // Instruction text
                Text(
                  'Утасны дугаар руу илгээсэн 4 оронтой кодыг оруулна уу',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                    ),
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 32,
                    medium: 36,
                    large: 40,
                    tablet: 44,
                  ),
                ),
                // PIN input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: context.responsiveSpacing(
                        small: 60,
                        medium: 65,
                        large: 70,
                        tablet: 75,
                      ),
                      child: TextField(
                        controller: _pinControllers[index],
                        focusNode: _pinFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: context.responsiveFontSize(
                            small: 24,
                            medium: 26,
                            large: 28,
                            tablet: 30,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.secondaryAccent.withOpacity(0.3)
                              : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                              ),
                            ),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.lightInputGray,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                              ),
                            ),
                            borderSide: BorderSide(
                              color: AppColors.deepGreen,
                              width: 2.5,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _handlePinChange(value, index),
                      ),
                    );
                  }),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 32,
                    medium: 36,
                    large: 40,
                    tablet: 44,
                  ),
                ),
                // Resend code button
                TextButton(
                  onPressed: _canResend && !_isLoading ? _resendCode : null,
                  child: Text(
                    _canResend
                        ? 'Код дахин илгээх'
                        : 'Код дахин илгээх ($_resendSeconds сек)',
                    style: TextStyle(
                      color: _canResend && !_isLoading
                          ? AppColors.deepGreen
                          : isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 17,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                  ),
                ),
                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSpacing(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 22,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                        ),
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: context.responsiveSpacing(
                            small: 20,
                            medium: 22,
                            large: 24,
                            tablet: 26,
                          ),
                          width: context.responsiveSpacing(
                            small: 20,
                            medium: 22,
                            large: 24,
                            tablet: 26,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Баталгаажуулах',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                              small: 16,
                              medium: 18,
                              large: 20,
                              tablet: 22,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
