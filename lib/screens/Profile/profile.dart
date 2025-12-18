import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;

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
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getUserProfile();

      if (response['success'] == true && response['result'] != null) {
        final userData = response['result'];

        setState(() {
          String fullName = '';
          if (userData['ovog'] != null &&
              userData['ovog'].toString().isNotEmpty) {
            fullName = userData['ovog'];
          }
          if (userData['ner'] != null &&
              userData['ner'].toString().isNotEmpty) {
            if (fullName.isNotEmpty) {
              fullName += ' ${userData['ner']}';
            } else {
              fullName = userData['ner'];
            }
          }
          _nameController.text = fullName;

          if (userData['utas'] != null) {
            _phoneController.text = userData['utas'].toString();
          }

          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();

      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Хэрэглэгчийн мэдээлэл татахад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
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
                  tablet: 24,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: context.responsiveIconSize(
                          small: 28,
                          medium: 30,
                          large: 32,
                          tablet: 34,
                        ),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(
                      width: context.responsiveSpacing(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                      ),
                    ),
                    Text(
                      'Хувийн мэдээлэл',
                      style: context.largeTitleStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingSkeleton()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: context.responsivePadding(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: context.responsiveSpacing(
                                        small: 100,
                                        medium: 110,
                                        large: 120,
                                        tablet: 130,
                                      ),
                                      height: context.responsiveSpacing(
                                        small: 100,
                                        medium: 110,
                                        large: 120,
                                        tablet: 130,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFe6ff00,
                                        ).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFe6ff00),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: context.responsiveIconSize(
                                          small: 50,
                                          medium: 55,
                                          large: 60,
                                          tablet: 65,
                                        ),
                                        color: const Color(0xFFe6ff00),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFe6ff00),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.camera_alt,
                                            color: Colors.black,
                                            size: context.responsiveIconSize(
                                              small: 20,
                                              medium: 22,
                                              large: 24,
                                              tablet: 26,
                                            ),
                                          ),
                                          onPressed: () {},
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
                                ),
                              ),
                              Text(
                                'Хэрэглэгчийн мэдээлэл',
                                style: context.titleStyle(
                                  color: Colors.white,
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
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Нэр',
                                      icon: Icons.person_outline,
                                      enabled: false,
                                    ),
                                    SizedBox(
                                      height: context.responsiveSpacing(
                                        small: 16,
                                        medium: 18,
                                        large: 20,
                                        tablet: 22,
                                      ),
                                    ),
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Утас',
                                      icon: Icons.phone_outlined,
                                      enabled: false,
                                      keyboardType: TextInputType.phone,
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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: context.responsivePadding(
        small: 16,
        medium: 18,
        large: 20,
        tablet: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile avatar skeleton
          Center(
            child: Container(
              width: context.responsiveSpacing(
                small: 100,
                medium: 110,
                large: 120,
                tablet: 130,
              ),
              height: context.responsiveSpacing(
                small: 100,
                medium: 110,
                large: 120,
                tablet: 130,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFe6ff00),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          SizedBox(
            height: context.responsiveSpacing(
              small: 32,
              medium: 36,
              large: 40,
              tablet: 44,
            ),
          ),
          // User info section title
          Container(
            height: context.responsiveSpacing(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
            ),
            width: context.responsiveSpacing(
              small: 180,
              medium: 200,
              large: 220,
              tablet: 240,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
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
          // Loading shimmer fields
          _buildSkeletonField(),
          SizedBox(
            height: context.responsiveSpacing(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
            ),
          ),
          _buildSkeletonField(),
        ],
      ),
    );
  }

  Widget _buildSkeletonField() {
    return Container(
      height: context.responsiveSpacing(
        small: 60,
        medium: 65,
        large: 70,
        tablet: 75,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
          ),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: context.responsivePadding(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 22,
        ),
        child: Row(
          children: [
            Container(
              width: context.responsiveSpacing(
                small: 24,
                medium: 26,
                large: 28,
                tablet: 30,
              ),
              height: context.responsiveSpacing(
                small: 24,
                medium: 26,
                large: 28,
                tablet: 30,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(
              width: context.responsiveSpacing(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: context.responsiveSpacing(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                    ),
                    width: context.responsiveSpacing(
                      small: 80,
                      medium: 90,
                      large: 100,
                      tablet: 110,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.white : Colors.white60),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFFe6ff00)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: const Color(0xFFe6ff00), width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: Colors.red, width: 2.w),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Энэ талбарыг бөглөнө үү';
        }
        return null;
      },
    );
  }
}
