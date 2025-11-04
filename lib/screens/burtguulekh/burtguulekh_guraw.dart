import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/core/auth_config.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_dorow.dart';
import 'package:sukh_app/widgets/app_logo.dart';

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
class Burtguulekh_Guraw extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Guraw({super.key, this.locationData});

  @override
  State<Burtguulekh_Guraw> createState() => _Burtguulekh_guraw_state();
}

// ignore: camel_case_types
class _Burtguulekh_guraw_state extends State<Burtguulekh_Guraw> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneSubmitted = false;
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
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
        // Clear all PIN boxes
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

              // Navigate to password page with all registration data
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      Burtguulekh_Dorow(
                        registrationData: {
                          ...?widget.locationData,
                          'utas': _phoneController.text,
                        },
                      ),
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        // Fade out the old page
                        final fadeOut = Tween<double>(begin: 1.0, end: 0.0)
                            .animate(
                              CurvedAnimation(
                                parent: secondaryAnimation,
                                curve: Curves.easeOut,
                              ),
                            );

                        // Fade in the new page
                        final fadeIn = Tween<double>(begin: 0.0, end: 1.0)
                            .animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeIn,
                              ),
                            );

                        return FadeTransition(
                          opacity: animation.status == AnimationStatus.reverse
                              ? fadeOut
                              : fadeIn,
                          child: child,
                        );
                      },
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
                          left: isNarrowScreen ? 24 : (isSmallScreen ? 30 : 40),
                          right: isNarrowScreen
                              ? 24
                              : (isSmallScreen ? 30 : 40),
                          top: isSmallScreen ? 12 : 24,
                          bottom: keyboardHeight > 0
                              ? keyboardHeight + 20
                              : (isSmallScreen ? 12 : 24),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLogo(),
                              SizedBox(height: isSmallScreen ? 12 : 20),
                              Text(
                                'Бүртгэл',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: isSmallScreen ? 22 : 28,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),

                              SizedBox(height: isSmallScreen ? 14 : 18),
                              if (!_isPhoneSubmitted)
                                _buildPhoneNumberField(isSmallScreen)
                              else
                                _buildSecretCodeField(isSmallScreen),
                              SizedBox(height: isSmallScreen ? 12 : 14),
                              if (_phoneController.text.length == 8 &&
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
                top: 16,
                left: 16,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField(bool isSmallScreen) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSmallScreen ? 280 : 320),
        child: Container(
          decoration: _boxShadowDecoration(),
          child: TextFormField(
            controller: _phoneController,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 13 : 15,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSecretCodeField(bool isSmallScreen) {
    return Column(
      children: [
        // Display phone number
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 13 : 16,
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
            children: [
              Text(
                _phoneController.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 14 : 18),
        // PIN Input boxes
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return _buildPinBox(index, isSmallScreen);
            }),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _canResend ? _resendCode : null,
              child: Text(
                _canResend ? 'Дахин илгээх' : 'Дахин илгээх ($_resendSeconds)',
                style: TextStyle(
                  color: _canResend ? Colors.blue : Colors.grey,
                  fontSize: isSmallScreen ? 12 : 14,
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
      width: isSmallScreen ? 52 : 60,
      height: isSmallScreen ? 60 : 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 8,
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
            fontSize: isSmallScreen ? 20 : 24,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.grayColor,
                width: 1.5,
              ),
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
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 8,
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
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 11 : 14,
              horizontal: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            shadowColor: Colors.black.withOpacity(0.3),
            elevation: 8,
          ),
          child: _isLoading
              ? SizedBox(
                  height: isSmallScreen ? 16 : 18,
                  width: isSmallScreen ? 16 : 18,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  'Үргэлжлүүлэх',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                ),
        ),
      ),
    );
  }

  BoxDecoration _boxShadowDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 10),
          blurRadius: 8,
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 11 : 14,
      ),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white70,
        fontSize: isSmallScreen ? 13 : 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.grayColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: TextStyle(
        color: Colors.redAccent,
        fontSize: isSmallScreen ? 11 : 13,
      ),
    );
  }
}
