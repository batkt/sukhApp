import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'dart:io';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings>
    with SingleTickerProviderStateMixin {
  // Profile controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Password controllers
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  // Password visibility
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureDeletePassword = true;

  // Loading states
  bool _isLoading = true;
  bool _isChangingPassword = false;
  bool _isDeletingAccount = false;

  // Biometric settings
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Address
  String? _currentAddress;
  bool _isLoadingAddress = false;

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
    _checkBiometricStatus();
    _loadCurrentAddress();
  }

  Future<void> _checkBiometricStatus() async {
    final isAvailable = await BiometricService.isAvailable();
    final isEnabled = await StorageService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    // Save to storage first
    final success = await StorageService.setBiometricEnabled(value);

    if (!success) {
      // If save failed, show error and don't update UI
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Тохиргоо хадгалахад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return;
    }

    // Verify it was saved
    final verifyEnabled = await StorageService.isBiometricEnabled();

    if (verifyEnabled != value) {
      // State mismatch - something went wrong
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Тохиргоо хадгалахад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return;
    }

    // Update UI after successful save and verification
    if (mounted) {
      setState(() {
        _biometricEnabled = value;
      });
    }

    if (!value) {
      // If disabling, clear saved biometric data
      await StorageService.clearSavedPasswordForBiometric();
    }

    if (mounted) {
      showGlassSnackBar(
        context,
        message: value
            ? 'Биометрийн баталгаажуулалт идэвхжлээ'
            : 'Биометрийн баталгаажуулалт идэвхгүй боллоо',
        icon: value ? Icons.check_circle : Icons.info,
        iconColor: value ? Colors.green : Colors.orange,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
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

  Future<void> _loadCurrentAddress() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final response = await ApiService.getUserProfile();
      
      if (response['success'] == true && response['result'] != null) {
        final userData = response['result'];
        String? addressText;
        
        if (userData['bairniiNer'] != null && userData['bairniiNer'].toString().isNotEmpty) {
          addressText = userData['bairniiNer'].toString();
          if (userData['walletDoorNo'] != null && userData['walletDoorNo'].toString().isNotEmpty) {
            addressText += ', ${userData['walletDoorNo']}';
          }
        } else {
          final bairId = await StorageService.getWalletBairId();
          final doorNo = await StorageService.getWalletDoorNo();
          if (bairId != null && doorNo != null) {
            addressText = 'Хаяг хадгалагдсан (Тоот: $doorNo)';
          }
        }

        if (mounted) {
          setState(() {
            _currentAddress = addressText;
            _isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _handleUpdateAddress() async {
    final result = await context.push('/address_selection');
    
    if (result == true && mounted) {
      await _loadCurrentAddress();
      showGlassSnackBar(
        context,
        message: 'Хаяг амжилттай шинэчлэгдлээ',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final response = await ApiService.changePassword(
        odoogiinNuutsUg: _currentPasswordController.text,
        shineNuutsUg: _newPasswordController.text,
        davtahNuutsUg: _confirmPasswordController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Нууц код амжилттай солигдлоо',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _passwordFormKey.currentState?.reset();
        } else {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Нууц код солихад алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Нууц код солихад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<String?> _showPasswordInputDialog() async {
    _deletePasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.w),
                side: BorderSide(
                  color: AppColors.goldPrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              title: Text(
                'Нууц үг оруулах',
                style: TextStyle(
                  color: AppColors.goldPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Бүртгэл устгахын тулд одоогийн нууц үгээ оруулна уу',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _deletePasswordController,
                    obscureText: _obscureDeletePassword,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Нууц үг',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.goldPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureDeletePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureDeletePassword = !_obscureDeletePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.w),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.w),
                        borderSide: BorderSide(
                          color: AppColors.goldPrimary,
                          width: 2.w,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: Text(
                    'Цуцлах',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_deletePasswordController.text.isEmpty) {
                      return;
                    }
                    Navigator.of(
                      dialogContext,
                    ).pop(_deletePasswordController.text);
                  },
                  child: const Text(
                    'Устгах',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final router = GoRouter.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w),
            side: BorderSide(
              color: AppColors.goldPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Бүртгэл устгах',
            style: TextStyle(
              color: AppColors.goldPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          content: Text(
            'Та өөрийн бүртгэлтэй хаягийг устгах хүсэлтэй байна уу?',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 16.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Үгүй',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 16.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Тийм',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final password = await _showPasswordInputDialog();

    if (password == null || password.isEmpty) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final response = await ApiService.deleteUser(nuutsUg: password);

      if (mounted) {
        if (response['success'] == true) {
          await StorageService.clearAuthData();
          showGlassSnackBar(
            context,
            message: 'Бүртгэл амжилттай устгагдлаа',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          await Future.delayed(const Duration(milliseconds: 500));
          router.go('/newtrekh');
        } else {
          showGlassSnackBar(
            context,
            message: response['aldaa'] ?? 'Бүртгэл устгахад алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Бүртгэл устгахад алдаа гарлаа',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(
                color: AppColors.goldPrimary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.goldPrimary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.goldPrimary.withOpacity(0.7),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppColors.goldPrimary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: child,
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
        prefixIcon: Icon(icon, color: AppColors.goldPrimary),
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
          borderSide: BorderSide(color: AppColors.goldPrimary, width: 2.w),
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
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.goldPrimary),
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
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: AppColors.goldPrimary, width: 2.w),
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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          _buildSkeletonField(),
          SizedBox(height: 16.h),
          _buildSkeletonField(),
        ],
      ),
    );
  }

  Widget _buildSkeletonField() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Container(
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.w),
                ),
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
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Хувийн мэдээлэл & Тохиргоо',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingSkeleton()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture Section
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100.w,
                                      height: 100.w,
                                      decoration: BoxDecoration(
                                        color: AppColors.goldPrimary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.goldPrimary,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 50.sp,
                                        color: AppColors.goldPrimary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.goldPrimary,
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
                                            color: AppColors.darkBackground,
                                            size: 20.sp,
                                          ),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40.h),

                              // Personal Information Section
                              _buildSectionHeader(
                                'Хувийн мэдээлэл',
                                Icons.person_outline,
                              ),
                              _buildSectionCard(
                                Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Нэр',
                                      icon: Icons.person_outline,
                                      enabled: false,
                                    ),
                                    SizedBox(height: 16.h),
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
                              SizedBox(height: 16.h),
                              _buildSectionCard(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.goldPrimary,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Хаяг',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    if (_isLoadingAddress)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.h),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 16.w,
                                              height: 16.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.goldPrimary,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(
                                              'Хаяг ачааллаж байна...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_currentAddress != null && _currentAddress!.isNotEmpty)
                                      Text(
                                        _currentAddress!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14.sp,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Хаяг тодорхойлогдоогүй',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 14.sp,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    SizedBox(height: 16.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _handleUpdateAddress,
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.goldPrimary,
                                          size: 18.sp,
                                        ),
                                        label: Text(
                                          'Хаяг шинэчлэх',
                                          style: TextStyle(
                                            color: AppColors.goldPrimary,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 12.h),
                                          side: BorderSide(
                                            color: AppColors.goldPrimary.withOpacity(0.5),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.w),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40.h),

                              // Divider
                              Container(
                                height: 1,
                                margin: EdgeInsets.symmetric(vertical: 8.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.goldPrimary.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40.h),

                              // Settings Section
                              _buildSectionHeader(
                                'Тохиргоо',
                                Icons.settings_outlined,
                              ),
                              SizedBox(height: 16.h),
                              _buildSubSectionHeader(
                                'Нэвтрэх нууц код солих',
                                Icons.lock_outline,
                              ),
                              SizedBox(height: 12.h),
                              _buildSectionCard(
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
                                      SizedBox(height: 16.h),
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
                                      SizedBox(height: 16.h),
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
                                      SizedBox(height: 24.h),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50.h,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.goldPrimary,
                                            borderRadius: BorderRadius.circular(
                                              12.w,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isChangingPassword
                                                  ? null
                                                  : _handleChangePassword,
                                              borderRadius:
                                                  BorderRadius.circular(12.w),
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: _isChangingPassword
                                                    ? SizedBox(
                                                        height: 20.h,
                                                        width: 20.w,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: AppColors
                                                                  .darkBackground,
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                    : Text(
                                                        'Нууц код солих',
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          letterSpacing: 0.8,
                                                          color: AppColors
                                                              .darkBackground,
                                                        ),
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
                              SizedBox(height: 24.h),

                              // Biometric Settings Section
                              if (_biometricAvailable) ...[
                                _buildSubSectionHeader(
                                  'Биометрийн баталгаажуулалт',
                                  Platform.isIOS
                                      ? Icons.face_rounded
                                      : Icons.fingerprint_rounded,
                                ),
                                SizedBox(height: 12.h),
                                _buildSectionCard(
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Биометрийн баталгаажуулалт',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              Platform.isIOS
                                                  ? 'Face ID ашиглан нэвтрэх'
                                                  : 'Хурууны хээ ашиглан нэвтрэх',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      GestureDetector(
                                        onTap: () => _handleBiometricToggle(
                                          !_biometricEnabled,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 56.w,
                                          height: 32.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            color: _biometricEnabled
                                                ? AppColors.grayColor
                                                : Colors.white.withOpacity(0.3),
                                          ),
                                          child: Stack(
                                            children: [
                                              AnimatedPositioned(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                curve: Curves.easeInOut,
                                                left: _biometricEnabled
                                                    ? 26.w
                                                    : 4.w,
                                                top: 4.h,
                                                child: Container(
                                                  width: 24.w,
                                                  height: 24.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24.h),
                              ],

                              // Delete Account Section
                              _buildSubSectionHeader(
                                'Бүртгэл устгах',
                                Icons.warning_amber_rounded,
                              ),
                              SizedBox(height: 12.h),
                              _buildSectionCard(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Бүртгэлээ устгаснаар бүх мэдээлэл алдагдах бөгөөд энэ үйлдлийг буцаах боломжгүй.',
                                      style: TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 13.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: _isDeletingAccount
                                            ? null
                                            : _handleDeleteAccount,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                          foregroundColor: Colors.redAccent,
                                          side: BorderSide(
                                            color: Colors.redAccent.withOpacity(
                                              0.5,
                                            ),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.w,
                                            ),
                                          ),
                                        ),
                                        child: _isDeletingAccount
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 16.h,
                                                    width: 16.h,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    'Устгаж байна...',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                'Бүртгэл устгах',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 32.h),
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
}
