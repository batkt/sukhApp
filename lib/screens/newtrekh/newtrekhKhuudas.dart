import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    bool isTablet = ScreenUtil().screenWidth > 700;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 300.w : double.infinity,
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28.w,
                            vertical: 12.h,
                          ),
                          child: Column(
                            children: [
                              const Spacer(),
                              const AppLogo(),
                              SizedBox(height: 12.h),
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 22.sp,
                                ),
                              ),
                              SizedBox(height: 14.h),
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
                                child: TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  autofocus: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Утасны дугаар',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.sp,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 11.h,
                                    ),
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
                                    suffixIcon: phoneController.text.isNotEmpty
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(8),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),
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
                                child: TextFormField(
                                  controller: passwordController,
                                  keyboardType: TextInputType.number,
                                  obscureText: !_isPasswordVisible,
                                  autofocus: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Нууц код',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.sp,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 11.h,
                                    ),
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),
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
                                          scale: 0.75,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            checkColor: Colors.white,
                                            side: const BorderSide(
                                              color: AppColors.grayColor,
                                              width: 1.5,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Flexible(
                                          child: Text(
                                            'Намайг сана',
                                            style: TextStyle(
                                              color: AppColors.grayColor,
                                              fontSize: isTablet ? 11 : 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () {
                                        context.push('/nuutsUg');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                          vertical: 1.h,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Нууц код сэргээх',
                                        style: TextStyle(
                                          color: AppColors.grayColor,
                                          fontSize: isTablet ? 11 : 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
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
                                            String inputPhone = phoneController
                                                .text
                                                .trim();
                                            String inputPassword =
                                                passwordController.text.trim();

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
                                            } else if (!RegExp(
                                              r'^\d+$',
                                            ).hasMatch(inputPhone)) {
                                              showGlassSnackBar(
                                                context,
                                                message:
                                                    "Зөвхөн тоо оруулна уу!",
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
                                                if (_rememberMe) {
                                                  await StorageService.savePhoneNumber(
                                                    inputPhone,
                                                  );
                                                } else {
                                                  await StorageService.clearSavedPhoneNumber();
                                                }

                                                final taniltsuulgaKharakhEsekh =
                                                    await StorageService.getTaniltsuulgaKharakhEsekh();

                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                showGlassSnackBar(
                                                  context,
                                                  message: 'Нэвтрэлт амжилттай',
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

                                                // Extract the error message from the exception
                                                String errorMessage = e
                                                    .toString();

                                                // Remove "Exception: " prefix if it exists
                                                if (errorMessage.startsWith(
                                                  'Exception: ',
                                                )) {
                                                  errorMessage = errorMessage
                                                      .substring(11);
                                                }

                                                // If it's still empty, use default
                                                if (errorMessage.isEmpty) {
                                                  errorMessage =
                                                      "Утасны дугаар эсвэл нууц үг буруу байна";
                                                }

                                                showGlassSnackBar(
                                                  context,
                                                  message: errorMessage,
                                                  icon: Icons.error,
                                                  iconColor: Colors.red,
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCAD2DB),
                                      foregroundColor: Colors.black,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11.h,
                                        horizontal: 16.w,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 16.h,
                                            width: 16.w,
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
                                            style: TextStyle(fontSize: 15.sp),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
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
                                    splashColor: Colors.white.withOpacity(0.2),
                                    highlightColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11.h,
                                        horizontal: 16.w,
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
                                          fontSize: 15.sp,
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
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Version 1.0',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
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
        ),
      ),
    );
  }
}
