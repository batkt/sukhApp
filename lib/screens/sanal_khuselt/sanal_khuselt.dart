import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
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
  String selectedFileName = 'No file chosen';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Санал хүсэлт',
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: context.responsivePadding(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 20,
                          medium: 24,
                          large: 28,
                          tablet: 32,
                          veryNarrow: 16,
                        ),
                      ),
                      _buildCategorySelector(),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 20,
                          medium: 22,
                          large: 24,
                          tablet: 26,
                          veryNarrow: 16,
                        ),
                      ),
                      _buildGlassTextField(),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 20,
                          medium: 22,
                          large: 24,
                          tablet: 26,
                          veryNarrow: 16,
                        ),
                      ),
                      _buildGlassFilePicker(),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 28,
                          medium: 30,
                          large: 32,
                          tablet: 36,
                          veryNarrow: 20,
                        ),
                      ),
                      _buildGlassButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryOption('Санал хүсэлт')),
            SizedBox(
              width: context.responsiveSpacing(
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 10,
              ),
            ),
            Expanded(child: _buildCategoryOption('Гомдол')),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryOption(String category) {
    final bool isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          vertical: context.responsiveSpacing(
            small: 14,
            medium: 15,
            large: 16,
            tablet: 18,
            veryNarrow: 12,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFe6ff00)
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 40,
              medium: 45,
              large: 50,
              tablet: 50,
              veryNarrow: 35,
            ),
          ),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.black,
                size: context.responsiveFontSize(
                  small: 18,
                  medium: 19,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 16,
                ),
              ),
            if (isSelected)
              SizedBox(
                width: context.responsiveSpacing(
                  small: 6,
                  medium: 7,
                  large: 8,
                  tablet: 10,
                  veryNarrow: 5,
                ),
              ),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.black : context.textPrimaryColor,
                fontSize: context.responsiveFontSize(
                  small: 14,
                  medium: 15,
                  large: 16,
                  tablet: 17,
                  veryNarrow: 12,
                ),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            descriptionLabel,
            key: ValueKey(descriptionLabel),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: context.responsiveFontSize(
                small: 14,
                medium: 15,
                large: 16,
                tablet: 17,
                veryNarrow: 13,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: context.responsiveSpacing(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(
                small: 12,
                medium: 13,
                large: 14,
                tablet: 16,
                veryNarrow: 10,
              ),
            ),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 6,
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
              hintText: descriptionHint,
              hintStyle: TextStyle(
                color: context.textSecondaryColor,
                fontSize: context.responsiveFontSize(
                  small: 14,
                  medium: 15,
                  large: 16,
                  tablet: 17,
                  veryNarrow: 13,
                ),
              ),
              border: InputBorder.none,
              contentPadding: context.responsivePadding(
                small: 14,
                medium: 15,
                large: 16,
                tablet: 18,
                veryNarrow: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Зураг хавсаргах:',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: context.responsiveFontSize(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 17,
              veryNarrow: 13,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          height: context.responsiveSpacing(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              selectedFileName = 'example_image.jpg';
            });
          },
          child: Container(
            padding: context.responsivePadding(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 18,
              veryNarrow: 12,
            ),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 12,
                  medium: 13,
                  large: 14,
                  tablet: 16,
                  veryNarrow: 10,
                ),
              ),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: context.responsivePadding(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 8,
                        medium: 9,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 6,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.upload_file,
                    color: const Color(0xFFe6ff00),
                    size: context.responsiveFontSize(
                      small: 18,
                      medium: 19,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 16,
                    ),
                  ),
                ),
                SizedBox(
                  width: context.responsiveSpacing(
                    small: 14,
                    medium: 15,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    selectedFileName,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 13,
                        medium: 14,
                        large: 15,
                        tablet: 16,
                        veryNarrow: 12,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.attach_file,
                  color: const Color(0xFFe6ff00),
                  size: context.responsiveFontSize(
                    small: 18,
                    medium: 19,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 6),
            blurRadius: 6,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCAD2DB),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              vertical: context.responsiveSpacing(
                small: 14,
                medium: 15,
                large: 16,
                tablet: 18,
                veryNarrow: 12,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              buttonText,
              key: ValueKey(buttonText),
              style: TextStyle(
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
