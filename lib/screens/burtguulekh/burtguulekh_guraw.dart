import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Modern minimal background with subtle gradient
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8FAFB),
      ),
      child: Stack(
        children: [
          // Subtle decorative circles for visual interest
          Positioned(
            top: -100.h,
            right: -80.w,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.deepGreen.withOpacity(0.15),
                          AppColors.deepGreen.withOpacity(0.0),
                        ]
                      : [
                          AppColors.deepGreen.withOpacity(0.08),
                          AppColors.deepGreen.withOpacity(0.0),
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120.h,
            left: -100.w,
            child: Container(
              width: 320.w,
              height: 320.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.deepGreenAccent.withOpacity(0.1),
                          AppColors.deepGreenAccent.withOpacity(0.0),
                        ]
                      : [
                          AppColors.deepGreenAccent.withOpacity(0.06),
                          AppColors.deepGreenAccent.withOpacity(0.0),
                        ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class Burtguulekh_Guraw extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const Burtguulekh_Guraw({super.key, this.registrationData});

  @override
  State<Burtguulekh_Guraw> createState() => _BurtguulekhGurawState();
}

class _BurtguulekhGurawState extends State<Burtguulekh_Guraw> {
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

        final savedSource = await StorageService.getWalletBairSource();
        final savedBaiguullagiinId =
            await StorageService.getWalletBairBaiguullagiinId();
        final savedBarilgiinId =
            await StorageService.getWalletBairBarilgiinId();
        final savedBairId = await StorageService.getWalletBairId();
        final savedDoorNo = await StorageService.getWalletDoorNo();
        final savedBairName = await StorageService.getWalletBairName();

        final source = widget.registrationData?['source'] ?? savedSource;
        final isOwnOrg = source == 'OWN_ORG';

        final finalBaiguullagiinId = isOwnOrg && savedBaiguullagiinId != null
            ? savedBaiguullagiinId
            : baiguullagiinId;
        final finalBarilgiinId = isOwnOrg
            ? (widget.registrationData?['barilgiinId'] ?? savedBarilgiinId)
            : null;
        final finalBairId = widget.registrationData?['bairId'] ?? savedBairId;
        final finalDoorNo = widget.registrationData?['doorNo'] ?? savedDoorNo;
        final finalBairName = widget.registrationData?['bairName'] ?? savedBairName;

        final registrationPayload = {
          'utas': widget.registrationData?['utas'] ?? '',
          'nuutsUg': _passwordController.text,
          'bairniiNer': widget.registrationData?['bairniiNer'] ?? '',
          'davkhar': widget.registrationData?['davkhar'] ?? '',
          'toot': widget.registrationData?['toot'] ?? '',
          'baiguullagiinId': finalBaiguullagiinId,
          'duureg': widget.registrationData?['duureg'] ?? '',
          'horoo': widget.registrationData?['horoo'] ?? '',
          'soh': widget.registrationData?['soh'] ?? '',
          'register': widget.registrationData?['register'] ?? '',
        };

        if (isOwnOrg && finalBairId != null && finalBarilgiinId != null) {
          registrationPayload['bairId'] = finalBairId;
          registrationPayload['barilgiinId'] = finalBarilgiinId;
          registrationPayload['baiguullagiinId'] = finalBaiguullagiinId;

          if (widget.registrationData?['davkhar'] != null) {
            registrationPayload['davkhar'] =
                widget.registrationData?['davkhar'];
          }
          if (widget.registrationData?['orts'] != null) {
            registrationPayload['orts'] = widget.registrationData?['orts'];
          }
        } else if (finalBairId != null) {
          registrationPayload['bairId'] = finalBairId;
          if (finalBairName != null && finalBairName.isNotEmpty) {
            registrationPayload['bairName'] = finalBairName;
          }
        }

        if (finalDoorNo != null) {
          registrationPayload['doorNo'] = finalDoorNo;
        }

        final response = await ApiService.registerUser(registrationPayload);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

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
          backgroundColor: context.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Анхааруулга',
                style: TextStyle(
                  color: context.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 20.sp,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: context.isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: TextStyle(
              color: context.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Хаах',
                style: TextStyle(color: AppColors.deepGreen, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ScreenUtil().screenWidth > 700;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8FAFB),
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 420.w : double.infinity,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 16.h),
                                    
                                    // Logo matched with login screen
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 130.w,
                                          height: 130.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100.w,
                                          height: 100.w,
                                          child: const SelectableLogoImage(
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Title matched with login screen
                                    Text(
                                      'Нууц код тохируулах',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Аппликейшнд нэвтрэх 4 оронтой нууц кодоо оруулна уу.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.5)
                                            : AppColors.lightTextSecondary
                                                  .withOpacity(0.7),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),

                                    SizedBox(height: 40.h),
                                    
                                    _buildPasswordField(isDark),
                                    SizedBox(height: 20.h),
                                    _buildConfirmPasswordField(isDark),
                                    
                                    SizedBox(height: 48.h),
                                    _buildButton(
                                      onTap: (_passwordController.text.length == 4 &&
                                              _confirmPasswordController.text == _passwordController.text &&
                                              !_isLoading)
                                          ? _validateAndSubmit
                                          : null,
                                      label: 'Бүртгүүлэх',
                                      isLoading: _isLoading,
                                      isDark: isDark,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTransparentButton(
                                      onTap: () => context.pop(),
                                      label: 'Буцах',
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Column(
                        children: [
                          Text(
                            '© 2026 Powered by Zevtabs LLC',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isDark
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.3),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Version 2.0.1',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Нууц код (4 оронтой)',
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.lightTextSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '****',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
              counterText: '',
              prefixIcon: Icon(
                Icons.lock_rounded,
                size: 20.sp,
                color: AppColors.deepGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.deepGreen.withOpacity(0.6),
                  size: 20.sp,
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
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Нууц код давтах',
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.lightTextSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '****',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
              counterText: '',
              prefixIcon: Icon(
                Icons.lock_rounded,
                size: 20.sp,
                color: AppColors.deepGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.deepGreen.withOpacity(0.6),
                  size: 20.sp,
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
              if (value != _passwordController.text) {
                return 'Нууц код таарахгүй байна';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback? onTap,
    required String label,
    bool isLoading = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: (onTap == null || isLoading)
                ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.5)]
                : [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            if (onTap != null && !isLoading)
              BoxShadow(
                color: AppColors.deepGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  height: 20.r,
                  width: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTransparentButton({
    required VoidCallback onTap,
    required String label,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
