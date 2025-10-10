import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/screens/newtrekhKhuudas.dart';

class Burtguulekh_Guraw extends StatefulWidget {
  const Burtguulekh_Guraw({super.key});

  @override
  State<Burtguulekh_Guraw> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Guraw> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneSubmitted = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _dugaarController = TextEditingController();
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _smsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _smsController.dispose();
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
    if (_formKey.currentState!.validate()) {
      if (!_isPhoneSubmitted) {
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
      } else {
        showGlassSnackBar(
          context,
          message: "Баталгаажуулах код зөв байна!",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Newtrekhkhuudas()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/img/main_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Positioned(
            top: 60,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final topBoxSize = constraints.maxWidth * 0.35;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 50,
                  right: 50,
                  top: 50,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 50,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: topBoxSize,
                          height: topBoxSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Бүртгэл',
                        style: TextStyle(
                          color: AppColors.grayColor,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '3/4',
                        style: TextStyle(
                          color: AppColors.grayColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 80),
                      if (!_isPhoneSubmitted)
                        _buildPhoneNumberField()
                      else
                        _buildSecretCodeField(),
                      const SizedBox(height: 16),
                      _buildContinueButton(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: _boxShadowDecoration(),
        child: TextFormField(
          controller: _phoneController,
          style: const TextStyle(color: AppColors.grayColor),
          decoration: _inputDecoration("Утасны дугаар", _dugaarController),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: (value) => value == null || value.trim().isEmpty
              ? '                            Утасны дугаар оруулна уу'
              : null,
        ),
      ),
    );
  }

  Widget _buildSecretCodeField() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Container(
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
            child: TextFormField(
              controller: _smsController,
              style: TextStyle(color: AppColors.grayColor),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 18,
                ),
                filled: true,
                fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                hintText: 'Баталгаажуулах код',
                hintStyle: const TextStyle(color: AppColors.grayColor),
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
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Баталгаажуулах код оруулна уу';
                }
                if (value.length != 4) return 'Код 4 оронтой байх ёстой';
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _canResend
                  ? () {
                      showGlassSnackBar(
                        context,
                        message: "Баталгаажуулах код дахин илгээлээ",
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      );
                      _startResendTimer();
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

  Widget _buildContinueButton() {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _validateAndSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCAD2DB),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: const Text('Үргэлжлүүлэх', style: TextStyle(fontSize: 16)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grayColor),
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
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () => controller.clear(),
            )
          : null,
    );
  }
}
