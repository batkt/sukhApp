import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/core/auth_config.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

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

class Burtguulekh_Khoyor extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Khoyor({super.key, this.locationData});

  @override
  State<Burtguulekh_Khoyor> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Khoyor> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;

  final TextEditingController tootController = TextEditingController();
  final TextEditingController ovogController = TextEditingController();
  final TextEditingController nerController = TextEditingController();
  final TextEditingController registerController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tootController.addListener(() => setState(() {}));
    ovogController.addListener(() => setState(() {}));
    nerController.addListener(() => setState(() {}));
    registerController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tootController.dispose();
    ovogController.dispose();
    nerController.dispose();
    registerController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSubmit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get baiguullagiinId from previous screen or AuthConfig
        final baiguullagiinId =
            widget.locationData?['baiguullagiinId'] ??
            AuthConfig.instance.baiguullagiinId;

        if (baiguullagiinId == null) {
          setState(() {
            _isLoading = false;
          });
          showGlassSnackBar(
            context,
            message: 'Байгууллагын мэдээлэл олдсонгүй',
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        final errorMessage = await ApiService.checkRegisterExists(
          register: registerController.text,
          baiguullagiinId: baiguullagiinId,
        );

        if (!mounted) return;

        if (errorMessage != null) {
          setState(() {
            _isLoading = false;
          });

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        final allData = {
          'duureg':
              widget.locationData?['duureg'] ?? AuthConfig.instance.duureg,
          'horoo':
              widget.locationData?['horoo'] ?? AuthConfig.instance.districtCode,
          'soh': widget.locationData?['soh'] ?? AuthConfig.instance.sohCode,
          'baiguullagiinId':
              widget.locationData?['baiguullagiinId'] ??
              AuthConfig.instance.baiguullagiinId,

          'toot': tootController.text,
          'ovog': ovogController.text,
          'ner': nerController.text,
          'register': registerController.text,
          'email': emailController.text,
        };

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Burtguulekh_Guraw(locationData: allData),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        showGlassSnackBar(
          context,
          message: 'Алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
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
                          autovalidateMode: _autovalidateMode,
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

                              const SizedBox(height: 20),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: tootController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Тоот',
                                    tootController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '                                      Тоот оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: ovogController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Овог',
                                    ovogController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '                                      Овог оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: nerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Нэр',
                                    nerController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '                                        Нэр оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: registerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Регистрийн дугаар',
                                    registerController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '             Регистрийн дугаар оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'И-Мэйл хаяг',
                                    emailController,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '                        И-Мэйл хаяг оруулна уу';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return '                                  Зөв И-Мэйл хаяг оруулна уу';
                                    }
                                    return null;
                                  },
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
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _validateAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCAD2DB),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                      elevation: 8,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.black,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Үргэлжлүүлэх',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                  ),
                                ),
                              ),
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
                            context.pop();
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
}
