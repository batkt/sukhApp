import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class Tokhirgoo extends StatefulWidget {
  const Tokhirgoo({super.key});

  @override
  State<Tokhirgoo> createState() => _TokhirgooState();
}

class _TokhirgooState extends State<Tokhirgoo>
    with SingleTickerProviderStateMixin {
  final _passwordFormKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureDeletePassword = true;
  bool _isChangingPassword = false;
  bool _isDeletingAccount = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final response = await ApiService.changePassword(
        odoogiinNuutsUg: _currentPasswordController.text,
        shineNuutsUg: _newPasswordController.text,
        davtahNuutsUg: _confirmPasswordController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Нууц код амжилттай солигдлоо',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _passwordFormKey.currentState?.reset();
        } else {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Нууц код солихад алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Нууц код солихад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<String?> _showPasswordInputDialog() async {
    _deletePasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
                ),
              ),
              title: Text(
                'Нууц үг оруулах',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsiveFontSize(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 18,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Бүртгэл устгахын тулд одоогийн нууц үгээ оруулна уу',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 17,
                        veryNarrow: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                  TextFormField(
                    controller: _deletePasswordController,
                    obscureText: _obscureDeletePassword,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Нууц үг',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFe6ff00),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureDeletePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureDeletePassword = !_obscureDeletePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),
                        borderSide: BorderSide(
                          color: const Color(0xFFe6ff00),
                          width: 2.w,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text(
                    'Цуцлах',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_deletePasswordController.text.isEmpty) {
                      return;
                    }
                    Navigator.of(
                      dialogContext,
                    ).pop(_deletePasswordController.text);
                  },
                  child: const Text(
                    'Устгах',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final router = GoRouter.of(context);

    // First confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
                veryNarrow: 12,
              ),
            ),
          ),
          title: const Text(
            'Бүртгэл устгах',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Та өөрийн бүртгэлтэй хаягийг устгах хүсэлтэй байна уу?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Үгүй',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Тийм',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    // Show password input dialog
    final password = await _showPasswordInputDialog();

    if (password == null || password.isEmpty) {
      return;
    }

    // Show loading state
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final response = await ApiService.deleteUser(nuutsUg: password);

      if (mounted) {
        if (response['success'] == true) {
          // Success - logout and navigate to login
          await StorageService.clearAuthData();
          showGlassSnackBar(
            context,
            message: 'Бүртгэл амжилттай устгагдлаа',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          // Wait a moment for the snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));
          router.go('/newtrekh');
        } else {
          // Error - show error message
          showGlassSnackBar(
            context,
            message: response['aldaa'] ?? 'Бүртгэл устгахад алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Бүртгэл устгахад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: context.responsivePadding(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(
                      width: context.responsiveSpacing(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 8,
                      ),
                    ),
                    Text(
                      'Тохиргоо',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: context.responsivePadding(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Нэвтрэх нууц код солих',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                        Form(
                          key: _passwordFormKey,
                          child: Column(
                            children: [
                              _buildPasswordField(
                                controller: _currentPasswordController,
                                label: 'Одоогийн нууц код',
                                obscureText: _obscureCurrentPassword,
                                onToggle: () {
                                  setState(() {
                                    _obscureCurrentPassword =
                                        !_obscureCurrentPassword;
                                  });
                                },
                              ),
                              SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                label: 'Шинэ нууц код',
                                obscureText: _obscureNewPassword,
                                onToggle: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                              SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Нууц код давтах',
                                obscureText: _obscureConfirmPassword,
                                onToggle: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              SizedBox(
                                height: context.responsiveSpacing(
                                  small: 24,
                                  medium: 28,
                                  large: 32,
                                  tablet: 36,
                                  veryNarrow: 18,
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: _isChangingPassword
                                      ? null
                                      : _handleChangePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFe6ff00),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isChangingPassword
                                      ? SizedBox(
                                          height: 20.h,
                                          width: 20.w,
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 2,
                                              ),
                                        )
                                      : Text(
                                          'Нууц код солих',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 32,
                            medium: 36,
                            large: 40,
                            tablet: 44,
                            veryNarrow: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
                  vertical: context.responsiveSpacing(
                    small: 10,
                    medium: 12,
                    large: 14,
                    tablet: 16,
                    veryNarrow: 8,
                  ),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: TextButton(
                      onPressed: _isDeletingAccount
                          ? null
                          : _handleDeleteAccount,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        foregroundColor: Colors.redAccent,
                        textStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isDeletingAccount
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 16.h,
                                  width: 16.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                SizedBox(
                                  width: context.responsiveSpacing(
                                    small: 8,
                                    medium: 10,
                                    large: 12,
                                    tablet: 14,
                                    veryNarrow: 6,
                                  ),
                                ),
                                Text(
                                  'Устгаж байна...',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text('Бүртгэл устгах'),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFe6ff00)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
          borderSide: BorderSide(color: const Color(0xFFe6ff00), width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
          borderSide: BorderSide(color: Colors.red, width: 2.w),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Энэ талбарыг бөглөнө үү';
        }
        if (value.length != 4) {
          return 'Нууц код 4 оронтой тоо байх ёстой';
        }
        if (label == 'Нууц код давтах' &&
            value != _newPasswordController.text) {
          return 'Нууц код хоорондоо таарахгүй байна';
        }
        return null;
      },
    );
  }
}
