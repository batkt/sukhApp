import 'dart:async';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/utils/page_transitions.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: child,
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

  final TextEditingController ovogController = TextEditingController();
  final TextEditingController nerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final FocusNode ovogFocus = FocusNode();
  final FocusNode nerFocus = FocusNode();
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
    ovogController.addListener(() => setState(() {}));
    nerController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    ovogController.dispose();
    nerController.dispose();
    _phoneController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    ovogFocus.dispose();
    nerFocus.dispose();
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
          // Get baiguullagiinId from locationData passed from previous screen
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
        // Verify PIN code
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

              // Navigate to next page with all registration data
              Navigator.push(
                context,
                PageTransitions.createRoute(
                  Burtguulekh_Guraw(
                    registrationData: {
                      ...?widget.locationData,
                      'ovog': ovogController.text,
                      'ner': nerController.text,
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
                    final screenHeight = MediaQuery.of(context).size.height;
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isSmallScreen = screenHeight < 700;
                    final isNarrowScreen = screenWidth < 380;
                    final keyboardHeight = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 40.w,
                          right: 40.w,
                          top: 24.h,
                          bottom: keyboardHeight > 0
                              ? keyboardHeight + 20
                              : 24.h,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLogo(),
                              SizedBox(height: isSmallScreen ? 12.h : 20.h),
                              Text(
                                'Бүртгэл',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: isSmallScreen ? 22.sp : 28.sp,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),

                              SizedBox(height: isSmallScreen ? 14.h : 18.h),
                              // Овог input
                              _buildOvogField(isSmallScreen),
                              SizedBox(height: 14.h),
                              // Нэр input
                              _buildNerField(isSmallScreen),
                              SizedBox(height: 14.h),
                              // Phone number input
                              _buildPhoneNumberField(isSmallScreen),
                              // Secret code field (appears below phone after submission)
                              if (_isPhoneSubmitted) ...[
                                SizedBox(height: 14.h),
                                _buildSecretCodeField(isSmallScreen),
                              ],
                              SizedBox(height: isSmallScreen ? 12.h : 14.h),
                              if (ovogController.text.isNotEmpty &&
                                  nerController.text.isNotEmpty &&
                                  _phoneController.text.length == 8 &&
                                  !_isPhoneSubmitted)
                                _buildContinueButton(isSmallScreen),
                              if (_isPhoneSubmitted &&
                                  _pinControllers.every(
                                    (c) => c.text.isNotEmpty,
                                  ))
                                _buildContinueButton(isSmallScreen),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16.h,
                left: 16.w,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100.r),
                    child: OptimizedGlass(
                      borderRadius: BorderRadius.circular(16.r),
                      opacity: 0.12,
                      child: IconButton(
                        padding: EdgeInsets.only(left: 7.w),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20.sp,
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

  Widget _buildOvogField(bool isSmallScreen) {
    return Container(
      decoration: _boxShadowDecoration(),
      child: TextFormField(
        controller: ovogController,
        focusNode: ovogFocus,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(nerFocus);
        },
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: _inputDecoration("Овог", ovogController, isSmallScreen),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Овог оруулна уу' : null,
      ),
    );
  }

  Widget _buildNerField(bool isSmallScreen) {
    return Container(
      decoration: _boxShadowDecoration(),
      child: TextFormField(
        controller: nerController,
        focusNode: nerFocus,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(phoneFocus);
        },
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: _inputDecoration("Нэр", nerController, isSmallScreen),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Нэр оруулна уу' : null,
      ),
    );
  }

  Widget _buildPhoneNumberField(bool isSmallScreen) {
    return Center(
      child: Container(
        decoration: _boxShadowDecoration(),
        child: TextFormField(
          controller: _phoneController,
          focusNode: phoneFocus,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            "Утасны дугаар",
            _phoneController,
            isSmallScreen,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Утасны дугаар оруулна уу'
              : null,
          onChanged: (value) {
            // If phone number changes after submission, reset submission state
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
    );
  }

  Widget _buildSecretCodeField(bool isSmallScreen) {
    return Column(
      children: [
        // PIN Input boxes
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return _buildPinBox(index, isSmallScreen);
            }),
          ),
        ),
        SizedBox(height: 10.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _canResend ? _resendCode : null,
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

  Widget _buildPinBox(int index, bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 52.w : 60.w,
      height: isSmallScreen ? 60.h : 70.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 10.h),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            // If current field is empty and backspace is pressed
            if (_pinControllers[index].text.isEmpty && index > 0) {
              // Clear previous field and move focus there
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
            color: Colors.white,
            fontSize: isSmallScreen ? 20.sp : 24.sp,
            fontWeight: FontWeight.bold,
          ),
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          enableInteractiveSelection: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputGrayColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100.r),
              borderSide: BorderSide(color: AppColors.grayColor, width: 1.5.w),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {});
              return;
            }

            // Handle autofill - when multiple digits are pasted
            if (value.length > 1) {
              // Split the autofilled code into individual digits
              final digits = value.replaceAll(
                RegExp(r'\D'),
                '',
              ); // Remove non-digits

              // Clear all boxes first
              for (var controller in _pinControllers) {
                controller.clear();
              }

              // Fill each box with a digit
              for (int i = 0; i < digits.length && i < 4; i++) {
                _pinControllers[i].text = digits[i];
              }

              // Move focus to the last filled box
              final lastIndex = (digits.length - 1).clamp(0, 3);
              _pinFocusNodes[lastIndex].requestFocus();

              setState(() {});
              return;
            }

            // Normal single digit input - keep only the last character
            if (value.length > 1) {
              _pinControllers[index].text = value.substring(value.length - 1);
              _pinControllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _pinControllers[index].text.length),
              );
            }

            // Move to next box if there's a value
            if (_pinControllers[index].text.isNotEmpty && index < 3) {
              _pinFocusNodes[index + 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isSmallScreen) {
    bool isValid = !_isPhoneSubmitted
        ? _phoneController.text.length == 8
        : _pinControllers.every((c) => c.text.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 10.h),
            blurRadius: 8.r,
            spreadRadius: 0,
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
            padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.r),
            ),
            shadowColor: Colors.black.withOpacity(0.3),
            elevation: 8,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 18.h,
                  width: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.black,
                    ),
                  ),
                )
              : Text('Үргэлжлүүлэх', style: TextStyle(fontSize: 16.sp)),
        ),
      ),
    );
  }

  BoxDecoration _boxShadowDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(100.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: Offset(0, 10.h),
          blurRadius: 8.r,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    TextEditingController controller,
    bool isSmallScreen,
  ) {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white70, fontSize: 15.sp),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100.r),
        borderSide: BorderSide(color: AppColors.grayColor, width: 1.5.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100.r),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100.r),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5.w),
      ),
      errorStyle: TextStyle(
        color: Colors.redAccent,
        fontSize: isSmallScreen ? 11.sp : 13.sp,
      ),
    );
  }
}
