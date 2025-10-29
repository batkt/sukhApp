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
                                  ? 30
                                  : (isSmallScreen ? 40 : 50),
                              vertical: isSmallScreen ? 20 : 40,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppLogo(),
                                SizedBox(height: isSmallScreen ? 20 : 30),
                                Text(
                                  'Тавтай морил',
                                  style: TextStyle(
                                    color: AppColors.grayColor,
                                    fontSize: isSmallScreen ? 28 : 36,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 30),
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
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Утасны дугаар',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 20 : 25,
                                        vertical: isSmallScreen ? 14 : 16,
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
                                SizedBox(height: isSmallScreen ? 12 : 16),
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
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Нууц код',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 20 : 25,
                                        vertical: isSmallScreen ? 14 : 16,
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
                                SizedBox(height: isSmallScreen ? 6 : 8),
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
                                            scale: isSmallScreen ? 0.8 : 0.9,
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
                                          const SizedBox(width: 4),
                                          Text(
                                            'Намайг сана',
                                            style: TextStyle(
                                              color: AppColors.grayColor,
                                              fontSize: isSmallScreen ? 12 : 14,
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
                                          horizontal: isSmallScreen ? 6 : 8,
                                          vertical: isSmallScreen ? 2 : 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Нууц кодоо мартсан уу?',
                                        style: TextStyle(
                                          color: AppColors.grayColor,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
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
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: isSmallScreen ? 18 : 20,
                                              width: isSmallScreen ? 18 : 20,
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
                                                    ? 14
                                                    : 16,
                                              ),
                                            ),
                                    ),
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
                                          vertical: isSmallScreen ? 14 : 16,
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
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 40),
                                const Text(
                                  '© 2025. All rights are reserverd  ©',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 40),
                                const Text(
                                  'Powered by Zevtabs LLC',
                                  style: TextStyle(
                                    fontSize: 14,
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
