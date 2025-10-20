import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/img/background_image.png'),
          fit: BoxFit.none,
          scale: 3,
        ),
      ),
      child: child,
    );
  }
}

class Tokhirgoo extends StatefulWidget {
  const Tokhirgoo({Key? key}) : super(key: key);

  @override
  State<Tokhirgoo> createState() => _TokhirgooState();
}

class _TokhirgooState extends State<Tokhirgoo>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
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
    _mailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          // Combine ovog and ner for the name field
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

          // Set email
          if (userData['mail'] != null) {
            _mailController.text = userData['mail'].toString();
          }

          // Set phone
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Тохиргоо',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
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
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFFe6ff00),
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
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Хэрэглэгчийн мэдээлэл',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _mailController,
                                      label: 'И-мэйл',
                                      icon: Icons.email_outlined,
                                      enabled: false,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
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
                              const SizedBox(height: 32),
                              const Text(
                                'Нэвтрэх нууц код солих',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Form(
                                key: _passwordFormKey,
                                child: Column(
                                  children: [
                                    _buildPasswordField(
                                      controller: _currentPasswordController,
                                      label: 'Одоогийн нууц код',
                                      obscureText: _obscureCurrentPassword,
                                      onToggle: () {
                                        setState(() {
                                          _obscureCurrentPassword =
                                              !_obscureCurrentPassword;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPasswordField(
                                      controller: _newPasswordController,
                                      label: 'Шинэ нууц код',
                                      obscureText: _obscureNewPassword,
                                      onToggle: () {
                                        setState(() {
                                          _obscureNewPassword =
                                              !_obscureNewPassword;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPasswordField(
                                      controller: _confirmPasswordController,
                                      label: 'Нууц код давтах',
                                      obscureText: _obscureConfirmPassword,
                                      onToggle: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_passwordFormKey.currentState!
                                              .validate()) {
                                            showGlassSnackBar(
                                              context,
                                              message:
                                                  'Нууц код амжилттай солигдлоо',
                                              icon: Icons.check_circle,
                                              iconColor: Colors.green,
                                            );
                                            _currentPasswordController.clear();
                                            _newPasswordController.clear();
                                            _confirmPasswordController.clear();
                                            _passwordFormKey.currentState
                                                ?.reset();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFe6ff00,
                                          ),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Нууц код солих',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile avatar skeleton
          Center(
            child: Container(
              width: 100,
              height: 100,
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
          const SizedBox(height: 32),
          // User info section title
          Container(
            height: 24,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Loading shimmer fields
          _buildSkeletonField(),
          const SizedBox(height: 16),
          _buildSkeletonField(),
          const SizedBox(height: 16),
          _buildSkeletonField(),
          const SizedBox(height: 32),
          // Password section title
          Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          _buildSkeletonField(),
          const SizedBox(height: 16),
          _buildSkeletonField(),
          const SizedBox(height: 16),
          _buildSkeletonField(),
          const SizedBox(height: 24),
          // Button skeleton
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonField() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: 80,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe6ff00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFe6ff00)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe6ff00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Энэ талбарыг бөглөнө үү';
        }
        if (value.length != 4) {
          return 'Нууц код 4 оронтой тоо байх ёстой';
        }
        if (label == 'Нууц код давтах' &&
            value != _newPasswordController.text) {
          return 'Нууц код хоорондоо таарахгүй байна';
        }
        return null;
      },
    );
  }
}
