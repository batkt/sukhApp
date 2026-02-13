import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.getGradientColors(isDark),
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: child,
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
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  Future<void> _registerWalletUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get saved address info if available (for Wallet API addresses)
        final savedBairId = await StorageService.getWalletBairId();
        final savedDoorNo = await StorageService.getWalletDoorNo();
        final savedBairName = await StorageService.getWalletBairName();
        final savedSource = await StorageService.getWalletBairSource();

        await ApiService.registerWalletUser(
          utas: _phoneController.text.trim(),
          mail: _emailController.text.trim(),
          bairId: savedSource == 'WALLET_API' ? savedBairId : null,
          doorNo: savedSource == 'WALLET_API' ? savedDoorNo : null,
          bairName: savedSource == 'WALLET_API' ? savedBairName : null,
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
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.isDarkMode 
            ? const Color(0xFF000000) 
            : const Color(0xFFFFFFFF),
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
                            padding: context
                                .responsiveHorizontalPadding(
                                  small: 28,
                                  medium: 32,
                                  large: 36,
                                  tablet: 40,
                                )
                                .copyWith(
                                  top: context.responsiveSpacing(
                                    small: 24,
                                    medium: 28,
                                    large: 32,
                                    tablet: 36,
                                  ),
                                  bottom: context.responsiveSpacing(
                                    small: 24,
                                    medium: 28,
                                    large: 32,
                                    tablet: 36,
                                  ),
                                ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppLogo(),
                                  SizedBox(
                                    height: context.responsiveSpacing(
                                      small: 20,
                                      medium: 24,
                                      large: 28,
                                      tablet: 32,
                                    ),
                                  ),
                                  Text(
                                    'Бүртгэл',
                                    style: context.largeTitleStyle(
                                      color: AppColors.grayColor,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                  SizedBox(
                                    height: context.responsiveSpacing(
                                      small: 24,
                                      medium: 28,
                                      large: 32,
                                      tablet: 36,
                                    ),
                                  ),
                                  if (_isRegistered) ...[
                                    Container(
                                      padding: context.responsivePadding(
                                        small: 20,
                                        medium: 22,
                                        large: 24,
                                        tablet: 26,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          context.responsiveBorderRadius(
                                            small: 16,
                                            medium: 18,
                                            large: 20,
                                            tablet: 22,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: AppColors.success.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: context.responsiveIconSize(
                                              small: 48,
                                              medium: 52,
                                              large: 56,
                                              tablet: 60,
                                            ),
                                          ),
                                          SizedBox(
                                            height: context.responsiveSpacing(
                                              small: 16,
                                              medium: 18,
                                              large: 20,
                                              tablet: 22,
                                            ),
                                          ),
                                          Text(
                                            'Амжилттай бүртгүүллээ!',
                                            textAlign: TextAlign.center,
                                            style: context.titleStyle(
                                              color: AppColors.success,
                                            ),
                                          ),
                                          SizedBox(
                                            height: context.responsiveSpacing(
                                              small: 12,
                                              medium: 14,
                                              large: 16,
                                              tablet: 18,
                                            ),
                                          ),
                                          Text(
                                            'Одоо утасны дугаараараа нэвтэрч болно.',
                                            textAlign: TextAlign.center,
                                            style: context.descriptionStyle(
                                              color: AppColors.grayColor
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: context.responsiveSpacing(
                                        small: 24,
                                        medium: 28,
                                        large: 32,
                                        tablet: 36,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.pop();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: context.responsiveSpacing(
                                            small: 14,
                                            medium: 16,
                                            large: 18,
                                            tablet: 20,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCAD2DB),
                                          borderRadius: BorderRadius.circular(
                                            context.responsiveBorderRadius(
                                              small: 12,
                                              medium: 14,
                                              large: 16,
                                              tablet: 18,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              offset: const Offset(0, 4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Нэвтрэх',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: context.responsiveFontSize(
                                              small: 15,
                                              medium: 16,
                                              large: 17,
                                              tablet: 18,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            offset: const Offset(0, 4),
                                            blurRadius: 12,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Утасны дугаар',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputGrayColor
                                              .withOpacity(0.3),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 16.h,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.grayColor
                                                  .withOpacity(0.8),
                                              width: 2,
                                            ),
                                          ),
                                          suffixIcon:
                                              _phoneController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 20.sp,
                                                  ),
                                                  onPressed: () =>
                                                      _phoneController.clear(),
                                                )
                                              : null,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(8),
                                        ],
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Утасны дугаар оруулна уу';
                                          }
                                          if (value.length != 8) {
                                            return 'Утасны дугаар 8 оронтой байх ёстой';
                                          }
                                          if (!RegExp(
                                            r'^\d+$',
                                          ).hasMatch(value)) {
                                            return 'Зөвхөн тоо оруулна уу';
                                          }
                                          return null;
                                        },
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
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            offset: const Offset(0, 4),
                                            blurRadius: 12,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.2,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Имэйл хаяг',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputGrayColor
                                              .withOpacity(0.3),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 16.h,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.grayColor
                                                  .withOpacity(0.8),
                                              width: 2,
                                            ),
                                          ),
                                          suffixIcon:
                                              _emailController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 20.sp,
                                                  ),
                                                  onPressed: () =>
                                                      _emailController.clear(),
                                                )
                                              : null,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Имэйл хаяг оруулна уу';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value.trim())) {
                                            return 'Зөв имэйл хаяг оруулна уу';
                                          }
                                          return null;
                                        },
                                      ),
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
                                    GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : _registerWalletUser,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCAD2DB),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              offset: const Offset(0, 4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: _isLoading
                                            ? Center(
                                                child: SizedBox(
                                                  height: 20.h,
                                                  width: 20.w,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.black),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                'Бүртгүүлэх',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: context.responsiveSpacing(
                                        small: 12,
                                        medium: 14,
                                        large: 16,
                                        tablet: 18,
                                        veryNarrow: 10,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.pop();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 11.5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          border: Border.all(
                                            color: AppColors.grayColor
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Text(
                                          'Буцах',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.grayColor,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
