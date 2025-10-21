import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/core/auth_config.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_dorow.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/img/background_image.png'),
            fit: BoxFit.none,
            scale: 3,
          ),
        ),
        child: child,
      ),
    );
  }
}

class Burtguulekh_Guraw extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Guraw({super.key, this.locationData});

  @override
  State<Burtguulekh_Guraw> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Guraw> {
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

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isPhoneSubmitted) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Get dynamic baiguullagiinId from AuthConfig
          final baiguullagiinId = await AuthConfig.instance.initialize(
            duureg: widget.locationData?['duureg'],
            districtCode: widget.locationData?['horoo'],
            sohCode: widget.locationData?['soh'],
          );

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

          // Check if phone number already exists before sending verification code
          final phoneExistsResult = await ApiService.checkPhoneExists(
            utas: _phoneController.text,
            baiguullagiinId: baiguullagiinId,
          );

          if (!mounted) return;

          if (phoneExistsResult != null) {
            // Phone already exists, show error and don't send verification code
            setState(() {
              _isLoading = false;
            });
            showGlassSnackBar(
              context,
              message:
                  phoneExistsResult['message'] ??
                  'Энэ утасны дугаар аль хэдийн бүртгэлтэй байна',
              icon: Icons.error,
              iconColor: Colors.red,
            );
            return;
          }

          // Phone is available, send verification code
          await ApiService.verifyPhoneNumber(
            baiguullagiinId: baiguullagiinId,
            utas: _phoneController.text,
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
            showGlassSnackBar(
              context,
              message: "Алдаа гарлаа: $e",
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
            // Use baiguullagiinId from AuthConfig (already initialized)
            final baiguullagiinId = AuthConfig.instance.baiguullagiinId;

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
                MaterialPageRoute(
                  builder: (context) => Burtguulekh_Dorow(
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
              // Clear PIN fields on error
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
                    final keyboardHeight = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 50,
                          right: 50,
                          top: 40,
                          bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 40,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 80,
                                  maxHeight: 154,
                                  minWidth: 154,
                                  maxWidth: 154,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'Бүртгэл',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 36,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),

                              const SizedBox(height: 20),
                              if (!_isPhoneSubmitted)
                                _buildPhoneNumberField()
                              else
                                _buildSecretCodeField(),
                              const SizedBox(height: 16),
                              if (_phoneController.text.length == 8 &&
                                  !_isPhoneSubmitted)
                                _buildContinueButton(),
                              if (_isPhoneSubmitted &&
                                  _pinControllers.every(
                                    (c) => c.text.isNotEmpty,
                                  ))
                                _buildContinueButton(),
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

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: _boxShadowDecoration(),
      child: TextFormField(
        controller: _phoneController,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration("Утасны дугаар", _phoneController),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        validator: (value) => value == null || value.trim().isEmpty
            ? '                            Утасны дугаар оруулна уу'
            : null,
      ),
    );
  }

  Widget _buildSecretCodeField() {
    return Column(
      children: [
        // Display phone number
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
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
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // PIN Input boxes
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return _buildPinBox(index);
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _canResend
                  ? () {
                      // Clear all PIN boxes
                      for (var controller in _pinControllers) {
                        controller.clear();
                      }
                      showGlassSnackBar(
                        context,
                        message: "Баталгаажуулах код дахин илгээлээ",
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      );
                      _startResendTimer();
                      _pinFocusNodes[0].requestFocus();
                    }
                  : null,
              child: Text(
                _canResend ? 'Дахин илгээх' : 'Дахин илгээх ($_resendSeconds)',
                style: TextStyle(
                  color: _canResend ? Colors.blue : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinBox(int index) {
    return Container(
      width: 60,
      height: 70,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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

  Widget _buildContinueButton() {
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            shadowColor: Colors.black.withOpacity(0.3),
            elevation: 8,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text('Үргэлжлүүлэх', style: TextStyle(fontSize: 14)),
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
  ) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
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
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
    );
  }
}
