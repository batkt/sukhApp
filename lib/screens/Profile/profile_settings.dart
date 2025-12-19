import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/services/theme_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:provider/provider.dart';
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

  // User data
  Map<String, dynamic>? _userData;

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
          _userData = userData;

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

        if (userData['bairniiNer'] != null &&
            userData['bairniiNer'].toString().isNotEmpty) {
          addressText = userData['bairniiNer'].toString();
          if (userData['walletDoorNo'] != null &&
              userData['walletDoorNo'].toString().isNotEmpty) {
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
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
                ),
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
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Нууц үг',
                      labelStyle: TextStyle(
                        color: context.isDarkMode
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.lightTextSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.deepGreen,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureDeletePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.lightTextSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureDeletePassword = !_obscureDeletePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
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
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.deepGreen.withOpacity(0.2),
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
              color: AppColors.deepGreen,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          content: Text(
            'Та өөрийн бүртгэлтэй хаягийг устгах хүсэлтэй байна уу?',
            style: TextStyle(
              color: context.textSecondaryColor,
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
                  color: context.textSecondaryColor,
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
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 22,
          veryNarrow: 12,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(
          small: 4,
          medium: 6,
          large: 8,
          tablet: 10,
          veryNarrow: 3,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 8,
                  medium: 10,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 6,
                ),
              ),
              border: Border.all(
                color: AppColors.goldPrimary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.goldPrimary,
              size: context.responsiveIconSize(
                small: 20,
                medium: 22,
                large: 24,
                tablet: 26,
                veryNarrow: 18,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimaryColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(
          small: 4,
          medium: 6,
          large: 8,
          tablet: 10,
          veryNarrow: 3,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? AppColors.deepGreen.withOpacity(0.7)
                : AppColors.deepGreen,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.deepGreen,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isActive ? AppColors.deepGreen : context.surfaceColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isActive ? AppColors.deepGreen : context.borderColor,
              width: isActive ? 0 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : context.textSecondaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.deepGreen,
                    fontSize: 14.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Хувийн мэдээлэл',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(height: 24.h),
                    // Additional User Information in Grid Layout
                    if (_userData != null) ...[_buildUserDataGrid()],
                    // Address Section
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.deepGreen,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Хаяг',
                          style: TextStyle(
                            color: context.textPrimaryColor,
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
                                color: AppColors.deepGreen,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Хаяг ачааллаж байна...',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_currentAddress != null &&
                        _currentAddress!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _currentAddress!,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Хаяг тодорхойлогдоогүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleUpdateAddress();
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.deepGreen,
                          size: 18.sp,
                        ),
                        label: Text(
                          'Хаяг шинэчлэх',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(
                            color: AppColors.deepGreen.withOpacity(0.5),
                            width: 1,
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
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Нууц үг солих',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: 'Хуучин нууц үг',
                        obscureText: _obscureCurrentPassword,
                        onToggle: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'Шинэ нууц үг',
                        obscureText: _obscureNewPassword,
                        onToggle: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Шинэ нууц үг',
                        obscureText: _obscureConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () async {
                                  await _handleChangePassword();
                                  if (mounted &&
                                      _passwordFormKey.currentState!
                                          .validate()) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isChangingPassword
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Хадгалах',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: isDark
              ? AppColors.deepGreen.withOpacity(0.15)
              : AppColors.deepGreen.withOpacity(0.2),
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
    final isDark = context.isDarkMode;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        color: enabled ? context.textPrimaryColor : context.textSecondaryColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.6)
              : AppColors.lightTextSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.deepGreen),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.deepGreen.withOpacity(0.2),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.lightInputGray,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 2.w),
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
    final isDark = context.isDarkMode;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      style: TextStyle(color: context.textPrimaryColor),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.6)
              : AppColors.lightTextSecondary,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.deepGreen),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : AppColors.lightTextSecondary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.deepGreen.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 2.w),
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
    final isDark = context.isDarkMode;
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
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.lightSurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
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

  Widget _buildUserDataGrid() {
    if (_userData == null) return const SizedBox.shrink();

    // Build list of data items - only ovog, ner, utas, bair, toot
    List<Map<String, dynamic>> dataItems = [];

    // Овог
    if (_userData!['ovog'] != null &&
        _userData!['ovog'].toString().isNotEmpty) {
      dataItems.add({
        'icon': Icons.person_outline,
        'label': 'Овог',
        'value': _userData!['ovog'].toString(),
      });
    }

    // Нэр
    if (_userData!['ner'] != null && _userData!['ner'].toString().isNotEmpty) {
      dataItems.add({
        'icon': Icons.badge_outlined,
        'label': 'Нэр',
        'value': _userData!['ner'].toString(),
      });
    }

    // Утас
    if (_userData!['utas'] != null &&
        _userData!['utas'].toString().isNotEmpty) {
      dataItems.add({
        'icon': Icons.phone_outlined,
        'label': 'Утас',
        'value': _userData!['utas'].toString(),
      });
    }

    // Байр (Address)
    String? bairText;
    if (_userData!['bairniiNer'] != null &&
        _userData!['bairniiNer'].toString().isNotEmpty) {
      bairText = _userData!['bairniiNer'].toString();
    }
    if (bairText != null && bairText.isNotEmpty) {
      dataItems.add({
        'icon': Icons.location_on_outlined,
        'label': 'Байр',
        'value': bairText,
      });
    }

    // Тоот (Door number)
    String? tootText;
    if (_userData!['walletDoorNo'] != null &&
        _userData!['walletDoorNo'].toString().isNotEmpty) {
      tootText = _userData!['walletDoorNo'].toString();
    }
    if (tootText != null && tootText.isNotEmpty) {
      dataItems.add({
        'icon': Icons.home_outlined,
        'label': 'Тоот',
        'value': tootText,
      });
    }

    if (dataItems.isEmpty) {
      return Text(
        'Мэдээлэл олдсонгүй',
        style: TextStyle(color: context.textSecondaryColor, fontSize: 14.sp),
      );
    }

    // Build grid with 2 columns, optimized to fit without scrolling
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.25, // Adjusted to fit better
      ),
      itemCount: dataItems.length,
      itemBuilder: (context, index) {
        final item = dataItems[index];
        return _buildGridInfoCard(
          icon: item['icon'] as IconData,
          label: item['label'] as String,
          value: item['value'] as String,
        );
      },
    );
  }

  Widget _buildGridInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.deepGreen, size: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.deepGreen, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.cardBackgroundColor
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.surfaceElevatedColor
                  : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(11.w),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.deepGreen.withOpacity(0.3)
                        : AppColors.lightAccentBackground,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(icon, size: 20.sp, color: AppColors.deepGreen),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.surfaceElevatedColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11.r),
        border: context.isDarkMode
            ? Border.all(color: context.borderColor, width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppColors.deepGreen.withOpacity(0.15)
                  : AppColors.lightAccentBackground,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.deepGreen),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 18.sp : 14.sp,
                    fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? context.textPrimaryColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonField() {
    final isDark = context.isDarkMode;
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : AppColors.deepGreen.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.lightSurface,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Container(
                height: 12.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.lightSurface,
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
      appBar: buildStandardAppBar(context, title: 'Хувийн мэдээлэл засах'),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingSkeleton()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Tab Buttons
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 20.h,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      context,
                                      icon: Icons.person_outline,
                                      label: 'Хувийн мэдээлэл',
                                      onTap: () =>
                                          _showPersonalInfoModal(context),
                                      isActive: true,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: _buildActionButton(
                                      context,
                                      icon: Icons.lock_outline,
                                      label: '• Нууц үг солих',
                                      onTap: () =>
                                          _showChangePasswordModal(context),
                                      isActive: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rest of settings
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 20.h),

                                    // Хувийн Мэдээлэл Section with Grid Layout
                                    if (_userData != null) ...[
                                      _buildSection(
                                        title: 'Хувийн Мэдээлэл',
                                        icon: Icons.person_outline_rounded,
                                        children: [_buildUserDataGrid()],
                                      ),
                                      SizedBox(height: 20.h),
                                    ],
                                    // Theme Settings Section
                                    _buildSubSectionHeader(
                                      'Theme',
                                      Icons.brightness_6,
                                    ),
                                    SizedBox(height: 12.h),
                                    _buildSectionCard(
                                      Consumer<ThemeService>(
                                        builder: (context, themeService, _) {
                                          final isDark =
                                              themeService.isDarkMode;
                                          final theme = Theme.of(context);
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isDark
                                                          ? 'Dark Mode'
                                                          : 'Light Mode',
                                                      style: TextStyle(
                                                        color:
                                                            theme.brightness ==
                                                                Brightness.dark
                                                            ? const Color.fromARGB(
                                                                255,
                                                                148,
                                                                241,
                                                                156,
                                                              )
                                                            : AppColors
                                                                  .deepGreen,
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      isDark
                                                          ? 'Dark Mode идэвхтэй'
                                                          : 'Light Mode идэвхтэй',
                                                      style: TextStyle(
                                                        color:
                                                            theme.brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                                  .withOpacity(
                                                                    0.7,
                                                                  )
                                                            : AppColors
                                                                  .lightTextSecondary,
                                                        fontSize: 13.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 16.w),
                                              GestureDetector(
                                                onTap: () =>
                                                    themeService.toggleTheme(),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  width: 56.w,
                                                  height: 32.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16.r,
                                                        ),
                                                    color: isDark
                                                        ? AppColors.deepGreen
                                                        : Colors.grey
                                                              .withOpacity(0.3),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      AnimatedPositioned(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 200,
                                                            ),
                                                        curve: Curves.easeInOut,
                                                        left: isDark
                                                            ? 26.w
                                                            : 4.w,
                                                        top: 4.h,
                                                        child: Container(
                                                          width: 24.w,
                                                          height: 24.w,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors
                                                                .white, // Toggle switch circle - always white
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Icon(
                                                            isDark
                                                                ? Icons
                                                                      .dark_mode
                                                                : Icons
                                                                      .light_mode,
                                                            size: 14.sp,
                                                            color: isDark
                                                                ? AppColors
                                                                      .deepGreen
                                                                : Colors.orange,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
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
                                                      color: context
                                                          .textPrimaryColor,
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    Platform.isIOS
                                                        ? 'Face ID ашиглан нэвтрэх'
                                                        : 'Хурууны хээ ашиглан нэвтрэх',
                                                    style: TextStyle(
                                                      color: context
                                                          .textSecondaryColor,
                                                      fontSize: 13.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 16.w),
                                            GestureDetector(
                                              onTap: () =>
                                                  _handleBiometricToggle(
                                                    !_biometricEnabled,
                                                  ),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                width: 56.w,
                                                height: 32.h,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  color: _biometricEnabled
                                                      ? AppColors.grayColor
                                                      : Colors.white
                                                            .withOpacity(0.3),
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
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              offset:
                                                                  const Offset(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Бүртгэлээ устгаснаар бүх мэдээлэл устах бөгөөд энэ үйлдлийг буцаах боломжгүй.',
                                            style: TextStyle(
                                              color:
                                                  AppColors.darkTextSecondary,
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
                                                foregroundColor:
                                                    Colors.redAccent,
                                                side: BorderSide(
                                                  color: Colors.redAccent
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.w,
                                                      ),
                                                ),
                                              ),
                                              child: _isDeletingAccount
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          height: 16.h,
                                                          width: 16.h,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Colors
                                                                    .redAccent,
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
                                                        fontWeight:
                                                            FontWeight.w500,
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
}
