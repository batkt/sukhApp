import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:go_router/go_router.dart';
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

class Burtguulekh_Guraw extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const Burtguulekh_Guraw({super.key, this.registrationData});

  @override
  State<Burtguulekh_Guraw> createState() => _BurtguulekhDorowState();
}

class _BurtguulekhDorowState extends State<Burtguulekh_Guraw> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        showGlassSnackBar(
          context,
          message: 'Нууц үг таарахгүй байна',
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Get baiguullagiinId from registrationData passed from previous screen
        final baiguullagiinId = widget.registrationData?['baiguullagiinId'];

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

        // Check if user has saved OWN_ORG address in storage
        final savedSource = await StorageService.getWalletBairSource();
        final savedBaiguullagiinId =
            await StorageService.getWalletBairBaiguullagiinId();
        final savedBarilgiinId =
            await StorageService.getWalletBairBarilgiinId();
        final savedBairId = await StorageService.getWalletBairId();
        final savedDoorNo = await StorageService.getWalletDoorNo();

        // Determine if this is OWN_ORG bair (from storage or registrationData)
        final source = widget.registrationData?['source'] ?? savedSource;
        final isOwnOrg = source == 'OWN_ORG';

        // Use OWN_ORG IDs from storage if available, otherwise from registrationData
        final finalBaiguullagiinId = isOwnOrg && savedBaiguullagiinId != null
            ? savedBaiguullagiinId
            : baiguullagiinId;
        final finalBarilgiinId = isOwnOrg
            ? (widget.registrationData?['barilgiinId'] ?? savedBarilgiinId)
            : null;
        final finalBairId = widget.registrationData?['bairId'] ?? savedBairId;
        final finalDoorNo = widget.registrationData?['doorNo'] ?? savedDoorNo;

        final registrationPayload = {
          'utas': widget.registrationData?['utas'] ?? '',
          'nuutsUg': _passwordController.text,
          'bairniiNer': widget.registrationData?['bairniiNer'] ?? '',
          'davkhar': widget.registrationData?['davkhar'] ?? '',
          'toot': widget.registrationData?['toot'] ?? '',
          'ovog': widget.registrationData?['ovog'] ?? '',
          'ner': widget.registrationData?['ner'] ?? '',
          'baiguullagiinId': finalBaiguullagiinId,
          'duureg': widget.registrationData?['duureg'] ?? '',
          'horoo': widget.registrationData?['horoo'] ?? '',
          'soh': widget.registrationData?['soh'] ?? '',
          'register': widget.registrationData?['register'] ?? '',
        };

        // Add OWN_ORG specific fields if this is OWN_ORG bair
        if (isOwnOrg && finalBairId != null && finalBarilgiinId != null) {
          registrationPayload['bairId'] = finalBairId;
          registrationPayload['barilgiinId'] = finalBarilgiinId;
          registrationPayload['baiguullagiinId'] = finalBaiguullagiinId;

          // Optional but recommended for validation
          if (widget.registrationData?['davkhar'] != null) {
            registrationPayload['davkhar'] =
                widget.registrationData?['davkhar'];
          }
          if (widget.registrationData?['orts'] != null) {
            registrationPayload['orts'] = widget.registrationData?['orts'];
          }
        } else if (finalBairId != null) {
          // Wallet API bair - just include bairId
          registrationPayload['bairId'] = finalBairId;
        }

        if (finalDoorNo != null) {
          registrationPayload['doorNo'] = finalDoorNo;
        }

        final response = await ApiService.registerUser(registrationPayload);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Check if registration failed
          if (response['success'] == false && response['aldaa'] != null) {
            _showErrorModal(response['aldaa']);
            return;
          }

          showGlassSnackBar(
            context,
            message: 'Бүртгэл амжилттай үүслээ!',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          // Navigate to login page
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go("/newtrekh");
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Extract error message from Exception
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _showErrorModal(String errorMessage) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Анхааруулга',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Хаах',
                style: TextStyle(color: Color(0xFFCAD2DB), fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
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
                              const AppLogo(),
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
                              _buildPasswordField(),
                              const SizedBox(height: 16),
                              _buildConfirmPasswordField(),
                              const SizedBox(height: 16),
                              if (_passwordController.text.isNotEmpty &&
                                  _confirmPasswordController.text.isNotEmpty)
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

  Widget _buildPasswordField() {
    return Container(
      decoration: _boxShadowDecoration(),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: _inputDecoration(
          "Нууц код",
          _passwordController,
          counterText: '',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Нууц код оруулна уу';
          }
          if (value.length != 4) {
            return 'Нууц код 4 оронтой байх ёстой';
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Зөвхөн тоо оруулна уу';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: _boxShadowDecoration(),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp, // 👈 use .sp for responsive font size
        ),
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: _inputDecoration(
          "Нууц код давтах",
          _confirmPasswordController,
          counterText: '',
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Нууц код давтан оруулна уу';
          }
          if (value.length != 4) {
            return 'Нууц код 4 оронтой байх ёстой';
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Зөвхөн тоо оруулна уу';
          }
          if (value != _passwordController.text) {
            return 'Нууц код таарахгүй байна';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildContinueButton() {
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
          onPressed: _isLoading ? null : _validateAndSubmit,
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
              : Text('Бүртгүүлэх', style: TextStyle(fontSize: 14.sp)),
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
    TextEditingController controller, {
    Widget? suffixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      suffixIcon: suffixIcon,
      counterText: counterText,
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
