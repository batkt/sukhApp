import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
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
  final _picker = ImagePicker();
  String _selectedType = 'gomdol'; // 'gomdol' or 'sanal'
  File? _selectedImage;
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
        imageFile: _selectedImage,
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
        setState(() => _selectedImage = null);

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
                  padding: context.responsivePadding(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 14,
                  ),
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
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                            fontWeight: FontWeight.w600,
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeButton(
                                'Гомдол',
                                'gomdol',
                                Icons.report_problem,
                              ),
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
                            Expanded(
                              child: _buildTypeButton(
                                'Санал',
                                'sanal',
                                Icons.lightbulb_outline,
                              ),
                            ),
                          ],
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
                        // Title field
                        Text(
                          'Гарчиг',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                            fontWeight: FontWeight.w600,
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
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Гарчиг оруулах',
                            hintStyle: TextStyle(
                              color: context.textSecondaryColor,
                            ),
                            filled: true,
                            fillColor: context.cardBackgroundColor,
                            border: OutlineInputBorder(
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
                                color: context.borderColor,
                              ),
                            ),
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
                                color: context.borderColor,
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
                                color: AppColors.deepGreen,
                                width: 2,
                              ),
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
                              borderSide: BorderSide(color: Colors.red),
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
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 24,
                            medium: 28,
                            large: 32,
                            tablet: 36,
                            veryNarrow: 18,
                          ),
                        ),
                        // Message field
                        Text(
                          'Дэлгэрэнгүй',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                            fontWeight: FontWeight.w600,
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
                        TextFormField(
                          controller: _messageController,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 17,
                              veryNarrow: 13,
                            ),
                          ),
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'Дэлгэрэнгүй мэдээлэл оруулах',
                            hintStyle: TextStyle(
                              color: context.textSecondaryColor,
                            ),
                            filled: true,
                            fillColor: context.cardBackgroundColor,
                            border: OutlineInputBorder(
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
                                color: context.borderColor,
                              ),
                            ),
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
                                color: context.borderColor,
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
                                color: AppColors.deepGreen,
                                width: 2,
                              ),
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
                              borderSide: BorderSide(color: Colors.red),
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
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 24,
                            medium: 28,
                            large: 32,
                            tablet: 36,
                            veryNarrow: 18,
                          ),
                        ),
                        // Image attachment
                        _buildImageSection(),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 32,
                            medium: 36,
                            large: 40,
                            tablet: 44,
                            veryNarrow: 24,
                          ),
                        ),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsiveSpacing(
                                  small: 16,
                                  medium: 18,
                                  large: 20,
                                  tablet: 22,
                                  veryNarrow: 12,
                                ),
                              ),
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
                                      fontSize: context.responsiveFontSize(
                                        small: 14,
                                        medium: 15,
                                        large: 16,
                                        tablet: 17,
                                        veryNarrow: 13,
                                      ),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (x != null && mounted) {
        setState(() => _selectedImage = File(x.path));
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Зураг сонгоход алдаа гарлаа: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          textColor: context.textPrimaryColor,
          opacity: 0.3,
          blur: 15,
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsiveBorderRadius(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 14,
          )),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: context.responsivePadding(
            small: 20,
            medium: 24,
            large: 28,
            tablet: 32,
            veryNarrow: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Зураг сонгох',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: context.responsiveFontSize(
                    small: 16,
                    medium: 17,
                    large: 18,
                    tablet: 19,
                    veryNarrow: 15,
                  ),
                  fontWeight: FontWeight.w600,
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
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.deepGreen),
                title: Text(
                  'Зургийн сан',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.deepGreen),
                title: Text(
                  'Камер',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Зураг хавсаргах',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: context.responsiveFontSize(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 17,
              veryNarrow: 13,
            ),
            fontWeight: FontWeight.w600,
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
        if (_selectedImage != null) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 12,
                    medium: 14,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 10,
                  ),
                ),
                child: Image.file(
                  _selectedImage!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => setState(() => _selectedImage = null),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(Icons.close, color: Colors.white, size: 20.w),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: context.responsiveSpacing(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            ),
          ),
        ],
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: context.responsiveSpacing(
                small: 14,
                medium: 16,
                large: 18,
                tablet: 20,
                veryNarrow: 12,
              ),
              horizontal: context.responsiveSpacing(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
                veryNarrow: 14,
              ),
            ),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
              ),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: context.textSecondaryColor,
                  size: context.responsiveFontSize(
                    small: 22,
                    medium: 24,
                    large: 26,
                    tablet: 28,
                    veryNarrow: 20,
                  ),
                ),
                SizedBox(
                  width: context.responsiveSpacing(
                    small: 12,
                    medium: 14,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 10,
                  ),
                ),
                Text(
                  _selectedImage != null
                      ? 'Өөр зураг сонгох'
                      : 'Зураг нэмэх (заавал биш)',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                      veryNarrow: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        padding: EdgeInsets.symmetric(
          vertical: context.responsiveSpacing(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 14,
          ),
          horizontal: context.responsiveSpacing(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 14,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.2)
              : unselectedBgColor,
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          )),
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
              size: context.responsiveFontSize(
                small: 18,
                medium: 20,
                large: 22,
                tablet: 24,
                veryNarrow: 16,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedTextColor,
                fontSize: context.responsiveFontSize(
                  small: 13,
                  medium: 14,
                  large: 15,
                  tablet: 16,
                  veryNarrow: 12,
                ),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
