import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';

class Newtrekhkhuudas extends StatefulWidget {
  const Newtrekhkhuudas({super.key});

  @override
  State<Newtrekhkhuudas> createState() => _NewtrekhkhuudasState();
}

class _NewtrekhkhuudasState extends State<Newtrekhkhuudas> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String dugaar = "99536945";
  String password = "1234";

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
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
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 154,
                      width: 154,
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
                    const SizedBox(height: 30),
                    Text(
                      'Тавтай морилно уу',
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 30),
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
                        decoration: InputDecoration(
                          hintText: 'Утасны дугаар',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          suffixIcon: phoneController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => phoneController.clear(),
                                )
                              : null,
                        ),
                        style: const TextStyle(color: Colors.white),
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
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Нууц үг',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          suffixIcon: passwordController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => passwordController.clear(),
                                )
                              : null,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.push('/forgot-password');
                        },
                        child: const Text(
                          'Нууц үгээ мартсан уу?',
                          style: TextStyle(
                            color: AppColors.grayColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          onPressed: () {
                            String inputPhone = phoneController.text.trim();
                            String inputPassword = passwordController.text
                                .trim();

                            if (inputPhone.isEmpty || inputPassword.isEmpty) {
                              showGlassSnackBar(
                                context,
                                message:
                                    "Утасны дугаар болон нууц үгийг оруулна уу",
                                icon: Icons.error,
                                iconColor: Colors.red,
                              );
                              return;
                            }

                            if (inputPhone == dugaar &&
                                inputPassword == password) {
                              context.go('/burtguulekh_neg');
                            } else {
                              showGlassSnackBar(
                                context,
                                message:
                                    "Утасны дугаар эсвэл нууц үг буруу байна",
                                icon: Icons.error,
                                iconColor: Colors.red,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCAD2DB),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Нэвтрэх',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Эсвэл',
                      style: TextStyle(color: AppColors.grayColor),
                    ),
                    const SizedBox(height: 20),
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
                            context.push('/ekhniikh');
                          },
                          splashColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.inputGrayColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Бүртгүүлэх',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'ZevTabs © 2025',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
