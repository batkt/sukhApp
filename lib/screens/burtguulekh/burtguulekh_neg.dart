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

class Burtguulekh_Neg extends StatefulWidget {
  const Burtguulekh_Neg({super.key});

  @override
  State<Burtguulekh_Neg> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Neg> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerWalletUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final savedBairId = await StorageService.getWalletBairId();
        final savedDoorNo = await StorageService.getWalletDoorNo();
        final savedBairName = await StorageService.getWalletBairName();
        final savedSource = await StorageService.getWalletBairSource();
        final savedCustomerId = await StorageService.getWalletCustomerId();

        await ApiService.registerWalletUser(
          utas: _phoneController.text.trim(),
          bairId: savedSource == 'WALLET_API' ? savedBairId : null,
          doorNo: savedSource == 'WALLET_API' ? savedDoorNo : null,
          bairName: savedSource == 'WALLET_API' ? savedBairName : null,
          customerId: savedSource == 'WALLET_API' ? savedCustomerId : null,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRegistered = true;
          });

          showGlassSnackBar(
            context,
            message: 'Сөх системд амжилттай бүртгүүллээ!',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
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
                                      'Бүртгэл',
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
                                      'Бүртгүүлэх утсаа оруулна уу',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.5)
                                            : AppColors.lightTextSecondary
                                                  .withOpacity(0.7),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),

                                    SizedBox(height: 24.h),
                                    
                                    if (_isRegistered) ...[
                                      Container(
                                        padding: EdgeInsets.all(24.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(24.r),
                                          border: Border.all(
                                            color: AppColors.success.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.success,
                                              size: 48.sp,
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              'Амжилттай!',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              'Таны бүртгэл үүсгэгдлээ. Одоо нэвтэрнэ үү.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : Colors.black54,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 32.h),
                                      _buildButton(
                                        onTap: () => context.go('/newtrekh'),
                                        label: 'Нэвтрэх',
                                        isDark: isDark,
                                      ),
                                    ] else ...[
                                      _buildInputField(
                                        label: 'Утасны дугаар',
                                        hint: '8888****',
                                        controller: _phoneController,
                                        icon: Icons.phone_iphone_rounded,
                                        isDark: isDark,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Утасны дугаар оруулна уу';
                                          }
                                          if (value.length != 8) {
                                            return 'Утасны дугаар 8 оронтой байх ёстой';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 32.h),
                                      _buildButton(
                                        onTap: _isLoading ? null : _registerWalletUser,
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Footer matched with login screen
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
                            'Version 2.1.3',
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
              prefixIcon: Icon(
                icon,
                size: 20.sp,
                color: AppColors.deepGreen,
              ),
            ),
            validator: validator,
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
