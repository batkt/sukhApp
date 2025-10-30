import 'package:flutter/material.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class Newtrekhkhuudas extends StatefulWidget {
  const Newtrekhkhuudas({super.key});

  @override
  State<Newtrekhkhuudas> createState() => _NewtrekhkhuudasState();
}

class _NewtrekhkhuudasState extends State<Newtrekhkhuudas> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
  }

  Future<void> _loadSavedPhoneNumber() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    final rememberMe = await StorageService.isRememberMeEnabled();
    if (savedPhone != null && mounted) {
      setState(() {
        phoneController.text = savedPhone;
        _rememberMe = rememberMe;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Builder(
                        builder: (context) {
                          final screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isSmallScreen = screenHeight < 700;
                          final isNarrowScreen = screenWidth < 380;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrowScreen
                                  ? 24
                                  : (isSmallScreen ? 30 : 40),
                              vertical: isSmallScreen ? 12 : 24,
                            ),
                            child: Column(
                              children: [
                                const Spacer(),
                                const AppLogo(),
                                SizedBox(height: isSmallScreen ? 12 : 20),
                                Text(
                                  'Тавтай морил',
                                  style: TextStyle(
                                    color: AppColors.grayColor,
                                    fontSize: isSmallScreen ? 22 : 28,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 14 : 20),
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
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    autofocus: false,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Утасны дугаар',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 13 : 15,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 11 : 14,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.grayColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      suffixIcon:
                                          phoneController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () =>
                                                  phoneController.clear(),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 14),
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
                                    controller: passwordController,
                                    keyboardType: TextInputType.number,
                                    obscureText: !_isPasswordVisible,
                                    autofocus: false,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Нууц код',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 13 : 15,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 11 : 14,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.grayColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      suffixIcon:
                                          passwordController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible =
                                                      !_isPasswordVisible;
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.scale(
                                            scale: isSmallScreen ? 0.75 : 0.85,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              activeColor: AppColors.grayColor,
                                              checkColor: Colors.white,
                                              side: const BorderSide(
                                                color: AppColors.grayColor,
                                                width: 1.5,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  const VisualDensity(
                                                    horizontal: -4,
                                                    vertical: -4,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Намайг сана',
                                            style: TextStyle(
                                              color: AppColors.grayColor,
                                              fontSize: isSmallScreen ? 11 : 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.push('/nuutsUg');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 4 : 6,
                                          vertical: isSmallScreen ? 1 : 3,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Нууц кодоо мартсан уу?',
                                        style: TextStyle(
                                          color: AppColors.grayColor,
                                          fontSize: isSmallScreen ? 11 : 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 6),
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
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              String inputPhone =
                                                  phoneController.text.trim();
                                              String inputPassword =
                                                  passwordController.text
                                                      .trim();

                                              if (inputPhone.isEmpty ||
                                                  inputPassword.isEmpty) {
                                                showGlassSnackBar(
                                                  context,
                                                  message:
                                                      "Утасны дугаар болон нууц үгийг оруулна уу",
                                                  icon: Icons.error,
                                                  iconColor: Colors.red,
                                                );
                                                return;
                                              }

                                              setState(() {
                                                _isLoading = true;
                                              });

                                              try {
                                                await ApiService.loginUser(
                                                  utas: inputPhone,
                                                  nuutsUg: inputPassword,
                                                );

                                                if (mounted) {
                                                  // Save or clear phone number based on remember me checkbox
                                                  if (_rememberMe) {
                                                    await StorageService.savePhoneNumber(
                                                      inputPhone,
                                                    );
                                                  } else {
                                                    await StorageService.clearSavedPhoneNumber();
                                                  }

                                                  // Check if we should show onboarding
                                                  final taniltsuulgaKharakhEsekh =
                                                      await StorageService.getTaniltsuulgaKharakhEsekh();

                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                  showGlassSnackBar(
                                                    context,
                                                    message:
                                                        'Нэвтрэлт амжилттай',
                                                    icon: Icons.check_outlined,
                                                    iconColor: Colors.green,
                                                  );

                                                  // Navigate to onboarding if taniltsuulgaKharakhEsekh is true, otherwise go to home
                                                  if (taniltsuulgaKharakhEsekh) {
                                                    context.go('/ekhniikh');
                                                  } else {
                                                    context.go('/nuur');
                                                  }
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                  showGlassSnackBar(
                                                    context,
                                                    message:
                                                        "Утасны дугаар эсвэл нууц үг буруу байна",
                                                    icon: Icons.error,
                                                    iconColor: Colors.red,
                                                  );
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFCAD2DB,
                                        ),
                                        foregroundColor: Colors.black,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 11 : 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: isSmallScreen ? 16 : 18,
                                              width: isSmallScreen ? 16 : 18,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.black),
                                                  ),
                                            )
                                          : Text(
                                              'Нэвтрэх',
                                              style: TextStyle(
                                                fontSize: isSmallScreen
                                                    ? 13
                                                    : 15,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 10 : 16),
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
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(100),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(100),
                                      onTap: () {
                                        context.push('/burtguulekh_neg');
                                      },
                                      splashColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      highlightColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 11 : 14,
                                          horizontal: 20,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.inputGrayColor
                                              .withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          'Бүртгүүлэх',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 13 : 15,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '© 2025 Powered by Zevtabs LLC',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 13,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12),
                                Text(
                                  'Version 1.0',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 13,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
