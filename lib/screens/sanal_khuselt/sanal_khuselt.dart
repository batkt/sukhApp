import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      ),
      child: child,
    );
  }
}

class SanalKhuseltPage extends StatefulWidget {
  const SanalKhuseltPage({super.key});

  @override
  State<SanalKhuseltPage> createState() => _SanalKhuseltPageState();
}

class _SanalKhuseltPageState extends State<SanalKhuseltPage> {
  String selectedCategory = 'Санал хүсэлт';
  final TextEditingController descriptionController = TextEditingController();
  String selectedFileName = 'Файл сонгоогүй';

  final List<String> categories = ['Санал хүсэлт', 'Гомдол'];

  String get descriptionLabel {
    return selectedCategory == 'Санал хүсэлт' ? 'Тайлбар:' : 'Гомдлын тайлбар:';
  }

  String get descriptionHint {
    return selectedCategory == 'Санал хүсэлт'
        ? 'Санал хүсэлт...'
        : 'Гомдлоо бичнэ үү...';
  }

  String get buttonText {
    return selectedCategory == 'Санал хүсэлт'
        ? 'Хүсэлт илгээх'
        : 'Гомдол илгээх';
  }

  Widget _buildHeader() {
    final isDark = context.isDarkMode;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'Санал хүсэлт',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCategorySelector(),
                    SizedBox(height: 24.h),
                    _buildDescriptionField(),
                    SizedBox(height: 24.h),
                    _buildFilePicker(),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      children: [
        Expanded(child: _buildCategoryOption('Санал хүсэлт')),
        SizedBox(width: 12.w),
        Expanded(child: _buildCategoryOption('Гомдол')),
      ],
    );
  }

  Widget _buildCategoryOption(String category) {
    final bool isSelected = selectedCategory == category;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepGreen
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.deepGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? Colors.white : AppColors.deepGreen,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textPrimaryColor,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            descriptionLabel,
            style: TextStyle(
              color: context.textPrimaryColor.withOpacity(0.7),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 6,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              hintText: descriptionHint,
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.4),
                fontSize: 13.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Зураг хавсаргах',
            style: TextStyle(
              color: context.textPrimaryColor.withOpacity(0.7),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () {
            // File picker logic would go here
            setState(() {
              selectedFileName = 'сонгосон_зураг.jpg';
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    color: AppColors.deepGreen,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    selectedFileName,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.deepGreen,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Send request logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}
