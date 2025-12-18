import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class GomdolSanalFormScreen extends StatefulWidget {
  const GomdolSanalFormScreen({super.key});

  @override
  State<GomdolSanalFormScreen> createState() => _GomdolSanalFormScreenState();
}

class _GomdolSanalFormScreenState extends State<GomdolSanalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'gomdol'; // 'gomdol' or 'sanal'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.submitGomdolSanal(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        turul: _selectedType,
      );

      if (mounted) {
        showGlassSnackBar(
          context,
          message: _selectedType == 'gomdol'
              ? 'Гомдол амжилттай илгээгдлээ'
              : 'Санал амжилттай илгээгдлээ',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          textColor: context.textPrimaryColor,
          opacity: 0.3,
          blur: 15,
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();

        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Алдаа гарлаа: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          textColor: context.textPrimaryColor,
          opacity: 0.3,
          blur: 15,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: _selectedType == 'gomdol' ? 'Гомдол илгээх' : 'Санал илгээх',
      ),
      body: Container(
        color: context.backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type selector
                        Text(
                          'Төрөл сонгох',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeButton(
                                'Гомдол',
                                'gomdol',
                                Icons.report_problem,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTypeButton(
                                'Санал',
                                'sanal',
                                Icons.lightbulb_outline,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // Title field
                        Text(
                          'Гарчиг',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Гарчиг оруулах',
                            hintStyle: TextStyle(
                              color: context.textSecondaryColor,
                            ),
                            filled: true,
                            fillColor: context.cardBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: AppColors.deepGreen,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Гарчиг оруулах шаардлагатай';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        // Message field
                        Text(
                          'Дэлгэрэнгүй',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _messageController,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16.sp,
                          ),
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Дэлгэрэнгүй мэдээлэл оруулах',
                            hintStyle: TextStyle(
                              color: context.textSecondaryColor,
                            ),
                            filled: true,
                            fillColor: context.cardBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: AppColors.deepGreen,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Дэлгэрэнгүй мэдээлэл оруулах шаардлагатай';
                            }
                            if (value.trim().length < 10) {
                              return 'Хамгийн багадаа 10 тэмдэгт оруулах шаардлагатай';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32.h),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              disabledBackgroundColor:
                                  context.textSecondaryColor,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Илгээх',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildTypeButton(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;
    final isGomdol = type == 'gomdol';
    final isDark = context.isDarkMode;

    // Colors for selected state
    final selectedColor = isGomdol ? Colors.orange : AppColors.secondaryAccent;

    // Colors for unselected state - theme-aware
    final unselectedBgColor = isDark
        ? context.textPrimaryColor.withOpacity(0.1)
        : context.surfaceColor;
    final unselectedBorderColor = isDark
        ? context.textPrimaryColor.withOpacity(0.3)
        : context.borderColor;
    final unselectedTextColor = isDark
        ? context.textPrimaryColor.withOpacity(0.7)
        : context.textSecondaryColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.2)
              : unselectedBgColor,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isSelected ? selectedColor : unselectedBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedTextColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedTextColor,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
