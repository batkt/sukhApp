import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_dorow.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/utils/page_transitions.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(child: child),
    );
  }
}

// ignore: camel_case_types
class Burtguulekh_Guraw extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Guraw({super.key, this.locationData});

  @override
  State<Burtguulekh_Guraw> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Guraw> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;

  final TextEditingController tootController = TextEditingController();
  final TextEditingController ovogController = TextEditingController();
  final TextEditingController nerController = TextEditingController();

  final FocusNode tootFocus = FocusNode();
  final FocusNode ovogFocus = FocusNode();
  final FocusNode nerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    tootController.addListener(() => setState(() {}));
    ovogController.addListener(() => setState(() {}));
    nerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tootController.dispose();
    ovogController.dispose();
    nerController.dispose();

    tootFocus.dispose();
    ovogFocus.dispose();
    nerFocus.dispose();

    super.dispose();
  }

  Future<void> _validateAndSubmit() async {
    // Force validation mode to show all errors immediately
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    if (!_formKey.currentState!.validate()) {
      // If invalid, show snackbar
      showGlassSnackBar(
        context,
        message: 'Бүх талбарыг бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.redAccent,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final allData = {
        ...?widget.locationData,
        'toot': tootController.text,
        'ovog': ovogController.text,
        'ner': nerController.text,
      };

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        PageTransitions.createRoute(
          Burtguulekh_Dorow(registrationData: allData),
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
        iconColor: Colors.redAccent,
      );
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white70, fontSize: 15.sp),
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
      errorStyle: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
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
                          left: 40.w,
                          right: 40.w,
                          top: 24.h,
                          bottom: keyboardHeight > 0
                              ? keyboardHeight + 20
                              : 24.h,
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLogo(),
                              SizedBox(height: 20.h),
                              Text(
                                'Бүртгэл',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 28.sp,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),
                              SizedBox(height: 18.h),

                              // Тоот input
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: AppColors.inputGrayColor.withOpacity(
                                    0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 10),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: tootController,
                                  focusNode: tootFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(ovogFocus);
                                  },
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h,
                                    ),
                                    hintText: 'Тоот',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.sp,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Тоот оруулна уу'
                                          : null,
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // Овог input
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: AppColors.inputGrayColor.withOpacity(
                                    0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 10),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: ovogController,
                                  focusNode: ovogFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(nerFocus);
                                  },
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h,
                                    ),
                                    hintText: 'Овог',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.sp,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Овог оруулна уу'
                                          : null,
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // Нэр input
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: AppColors.inputGrayColor.withOpacity(
                                    0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 10),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: nerController,
                                  focusNode: nerFocus,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h,
                                    ),
                                    hintText: 'Нэр',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.sp,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Нэр оруулна уу'
                                          : null,
                                ),
                              ),

                              // Continue button - Show only when all fields filled
                              if (tootController.text.isNotEmpty &&
                                  ovogController.text.isNotEmpty &&
                                  nerController.text.isNotEmpty) ...[
                                SizedBox(height: 14.h),
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
                                        backgroundColor: const Color(
                                          0xFFCAD2DB,
                                        ),
                                        foregroundColor: Colors.black,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14.h,
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
                                          ? SizedBox(
                                              height: 18.h,
                                              width: 18.w,
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
                                              'Үргэлжлүүлэх',
                                              style: TextStyle(fontSize: 15.sp),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
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
                            Navigator.pop(context);
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
}
