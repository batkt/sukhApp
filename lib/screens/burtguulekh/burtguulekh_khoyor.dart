import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/utils/page_transitions.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/common_footer.dart';

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

// ignore: camel_case_types
class Burtguulekh_Khoyor extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Khoyor({super.key, this.locationData});

  @override
  State<Burtguulekh_Khoyor> createState() => _Burtguulekh_Khoyor_state();
}

// ignore: camel_case_types
class _Burtguulekh_Khoyor_state extends State<Burtguulekh_Khoyor> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneSubmitted = false;
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final FocusNode phoneFocus = FocusNode();
  final List<FocusNode> _pinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    phoneFocus.dispose();
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
      final baiguullagiinId = widget.locationData?['baiguullagiinId'];

      if (baiguullagiinId == null) {
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
        purpose: "registration",
        utas: _phoneController.text,
        duureg: widget.locationData?['duureg'] ?? '',
        horoo: widget.locationData?['horoo'] ?? '',
        soh: widget.locationData?['soh'] ?? '',
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

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isPhoneSubmitted) {
        setState(() {
          _isLoading = true;
        });

        try {
          final baiguullagiinId = widget.locationData?['baiguullagiinId'];

          if (baiguullagiinId == null) {
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
            utas: _phoneController.text,
            purpose: "registration",
            duureg: widget.locationData?['duureg'] ?? '',
            horoo: widget.locationData?['horoo'] ?? '',
            soh: widget.locationData?['soh'] ?? '',
          );

          if (mounted) {
            setState(() {
              _isPhoneSubmitted = true;
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message: "4 оронтой баталгаажуулах код илгээлээ",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            );
            _startResendTimer();

            Future.delayed(Duration.zero, () {
              _pinFocusNodes[0].requestFocus();
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            String errorMessage = "Алдаа гарлаа: $e";
            if (e.toString().contains('409')) {
              errorMessage = "Дугаар бүртгэлтэй байна";
            }

            showGlassSnackBar(
              context,
              message: errorMessage,
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
        }
      } else {
        String pin = _pinControllers.map((c) => c.text).join();
        if (pin.length == 4) {
          setState(() {
            _isLoading = true;
          });

          try {
            final baiguullagiinId = widget.locationData?['baiguullagiinId'];

            if (baiguullagiinId == null) {
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

            await ApiService.verifySecretCode(
              utas: _phoneController.text,
              code: pin,
              baiguullagiinId: baiguullagiinId,
              purpose: "registration",
            );

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              showGlassSnackBar(
                context,
                message: "Утас баталгаажлаа!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );

              Navigator.push(
                context,
                PageTransitions.createRoute(
                    Burtguulekh_Guraw(
                      registrationData: {
                        ...?widget.locationData,
                        'utas': _phoneController.text,
                      },
                    ),
                ),
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

              for (var controller in _pinControllers) {
                controller.clear();
              }
              _pinFocusNodes[0].requestFocus();
            }
          }
        }
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
                                      'Баталгаажуулах',
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
                                      _isPhoneSubmitted
                                          ? 'Танд илгээсэн 4 оронтой кодыг оруулна уу'
                                          : 'Утасны дугаараа оруулаад баталгаажуулна уу',
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

                                    SizedBox(height: 40.h),
                                    
                                    _buildPhoneNumberField(isDark),
                                    if (_isPhoneSubmitted) ...[
                                      SizedBox(height: 32.h),
                                      _buildSecretCodeField(isDark),
                                    ],
                                    
                                    SizedBox(height: 48.h),
                                    _buildButton(
                                      onTap: _isLoading ? null : _validateAndSubmit,
                                      label: _isPhoneSubmitted ? 'Үргэлжлүүлэх' : 'Код авах',
                                      isLoading: _isLoading,
                                      canContinue: !_isPhoneSubmitted
                                          ? _phoneController.text.length == 8
                                          : _pinControllers.every((c) => c.text.isNotEmpty),
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTransparentButton(
                                      onTap: () => Navigator.pop(context),
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

  Widget _buildPhoneNumberField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Утасны дугаар',
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
            controller: _phoneController,
            focusNode: phoneFocus,
            enabled: !_isPhoneSubmitted,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              hintText: '8888****',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                size: 20.sp,
                color: AppColors.deepGreen,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Утасны дугаар оруулна уу';
              }
              if (value.length != 8) {
                return 'Утасны дугаар 8 оронтой байх ёстой';
              }
              return null;
            },
            onChanged: (value) {
              if (_isPhoneSubmitted && value.length != 8) {
                setState(() {
                  _isPhoneSubmitted = false;
                  _timer?.cancel();
                  for (var controller in _pinControllers) {
                    controller.clear();
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecretCodeField(bool isDark) {
    return Column(
      children: [
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return _buildPinBox(index, isDark);
            }),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _canResend ? _resendCode : null,
              child: Text(
                _canResend ? 'Дахин илгээх' : 'Дахин илгээх ($_resendSeconds)',
                style: TextStyle(
                  color: _canResend ? AppColors.deepGreen : Colors.grey,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinBox(int index, bool isDark) {
    return Container(
      width: 65.w,
      height: 75.h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _pinFocusNodes[index].hasFocus
              ? AppColors.deepGreen
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05)),
          width: 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_pinControllers[index].text.isEmpty && index > 0) {
              _pinControllers[index - 1].clear();
              _pinFocusNodes[index - 1].requestFocus();
              setState(() {});
            }
          }
        },
        child: TextFormField(
          controller: _pinControllers[index],
          focusNode: _pinFocusNodes[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            height: 1.2, // Perfect for centering
          ),
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          enableInteractiveSelection: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          onChanged: (value) {
            if (value.length > 1) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              for (int i = 0; i < digits.length && i < 4; i++) {
                if (index + i < 4) {
                  _pinControllers[index + i].text = digits[i];
                }
              }
              final lastIndex = (index + digits.length - 1).clamp(0, 3);
              _pinFocusNodes[lastIndex].requestFocus();
              setState(() {});
              return;
            }
            if (value.isNotEmpty && index < 3) {
              _pinFocusNodes[index + 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onTap,
    required String label,
    bool isLoading = false,
    bool canContinue = true,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: (onTap == null || isLoading || !canContinue)
                ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.5)]
                : [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            if (onTap != null && !isLoading && canContinue)
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
                  height: 20.r,
                  width: 20.r,
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
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
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
