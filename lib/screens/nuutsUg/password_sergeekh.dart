import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/img/background_image.png'),
          fit: BoxFit.none,
          scale: 3,
        ),
      ),
      child: child,
    );
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

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

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

  void _validateAndSubmit() {
    if (!_isPhoneSubmitted) {
      // Submit phone number
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
        _isPhoneSubmitted = true;
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
    } else if (!_isPinVerified) {
      // Verify PIN
      String pin = _pinControllers.map((c) => c.text).join();
      if (pin.length == 4) {
        setState(() {
          _isPinVerified = true;
        });
        showGlassSnackBar(
          context,
          message: "Баталгаажуулалт амжилттай!",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } else {
      // Reset password
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

      showGlassSnackBar(
        context,
        message: "Нууц код амжилттай солигдлоо!",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      // Navigate back to login or home
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 40,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  'Нууц код сэргээх',
                                  style: TextStyle(
                                    color: AppColors.grayColor,
                                    fontSize: 36,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _getStepText(),
                                  style: const TextStyle(
                                    color: AppColors.grayColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (!_isPhoneSubmitted)
                                  _buildPhoneNumberField()
                                else if (!_isPinVerified)
                                  _buildSecretCodeField()
                                else
                                  _buildPasswordFields(),
                                const SizedBox(height: 16),
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

  String _getStepText() {
    if (!_isPhoneSubmitted) {
      return '1/3';
    } else if (!_isPinVerified) {
      return '2/3';
    } else {
      return '3/3';
    }
  }

  bool _shouldShowContinueButton() {
    if (!_isPhoneSubmitted) {
      return _phoneController.text.isNotEmpty;
    } else if (!_isPinVerified) {
      return _pinControllers.every((c) => c.text.isNotEmpty);
    } else {
      return _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;
    }
  }

  bool _isButtonValid() {
    if (!_isPhoneSubmitted) {
      return _phoneController.text.length == 8;
    } else if (!_isPinVerified) {
      return _pinControllers.every((c) => c.text.isNotEmpty);
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
        style: const TextStyle(color: Colors.white),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        decoration: InputDecoration(
          hintText: 'Утасны дугаар',
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 16,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return _buildPinBox(index);
          }),
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
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _pinFocusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
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
          if (value.isNotEmpty && index < 3) {
            _pinFocusNodes[index + 1].requestFocus();
          }
          setState(() {});
        },
        onTap: () {
          // Select all text when tapped
          _pinControllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _pinControllers[index].text.length,
          );
        },
      ),
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
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'Шинэ нууц код (4 орон)',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppColors.inputGrayColor.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 16,
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
        const SizedBox(height: 16),
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
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'Нууц код давтах',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppColors.inputGrayColor.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 16,
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
      isValid = _pinControllers.every((c) => c.text.isNotEmpty);
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
          onPressed: isValid ? _validateAndSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCAD2DB),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text('Үргэлжлүүлэх', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
