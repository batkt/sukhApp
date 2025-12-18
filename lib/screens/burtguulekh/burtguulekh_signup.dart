import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.getGradientColors(isDark),
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class BurtguulekhSignup extends StatefulWidget {
  /// If true, this screen must behave as "NO baiguullagiinId" signup,
  /// even if some old orgId exists in storage from a previous session.
  final bool forceNoOrg;

  /// When completing profile for WEB-created users, pass their orgId explicitly.
  final String? baiguullagiinId;

  /// Optional prefill
  final String? prefillPhone;
  final String? prefillEmail;

  const BurtguulekhSignup({
    super.key,
    this.forceNoOrg = false,
    this.baiguullagiinId,
    this.prefillPhone,
    this.prefillEmail,
  });

  @override
  State<BurtguulekhSignup> createState() => _BurtguulekhSignupState();
}

class _BurtguulekhSignupState extends State<BurtguulekhSignup> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nerController = TextEditingController();
  final TextEditingController _ovogController = TextEditingController();

  // Hidden fields (auto-filled, not displayed)
  String? _baiguullagiinId;
  int _tsahilgaaniiZaalt = 200; // Default value
  static const String _defaultDavkhar = '1';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  @override
  void initState() {
    super.initState();

    // Prefill fields if provided
    if (widget.prefillPhone != null && widget.prefillPhone!.trim().isNotEmpty) {
      _phoneController.text = widget.prefillPhone!.trim();
    }
    if (widget.prefillEmail != null && widget.prefillEmail!.trim().isNotEmpty) {
      _emailController.text = widget.prefillEmail!.trim();
    }

    // If caller forces no-org flow, ignore any stored ids
    if (widget.forceNoOrg) {
      _baiguullagiinId = null;
      debugPrint('🧾 [SIGNUP] forceNoOrg=true -> using NO-ORG signup flow');
      return;
    }

    // If caller provided an orgId (WEB-created user), use it
    final providedId = (widget.baiguullagiinId ?? '').trim();
    if (providedId.isNotEmpty && providedId.toLowerCase() != 'null') {
      _baiguullagiinId = providedId;
      debugPrint(
        '🧾 [SIGNUP] baiguullagiinId provided via route -> ORG flow (id=$providedId)',
      );
      return;
    }

    // Otherwise, attempt to load (wallet flow or other)
    _loadAutoFillData();
  }

  Future<void> _loadAutoFillData() async {
    // Load baiguullagiinId from storage or from AuthConfig
    final savedBaiguullagiinId =
        await StorageService.getWalletBairBaiguullagiinId();

    // IMPORTANT:
    // For "no baiguullagiinId" signup users, we must NOT force-fill baiguullagiinId
    // from AuthConfig (it can contain a previously selected org and would hide/skip
    // the required address fields).
    //
    // Only use explicit values that were saved for this flow.
    // Only trust wallet-selected org id for this signup screen.
    // Do NOT fall back to generic saved baiguullagiinId (it can be stale from a previous session).
    final rawBaiguullagiinId = savedBaiguullagiinId;

    final normalizedBaiguullagiinId = (rawBaiguullagiinId ?? '').trim();
    final baiguullagiinId =
        normalizedBaiguullagiinId.isEmpty ||
            normalizedBaiguullagiinId.toLowerCase() == 'null'
        ? null
        : normalizedBaiguullagiinId;

    if (mounted) {
      setState(() {
        _baiguullagiinId = baiguullagiinId;
      });
    }

    // Debug logs: which signup flow will be used
    debugPrint(
      '🧾 [SIGNUP] raw baiguullagiinId="$rawBaiguullagiinId" -> normalized="$normalizedBaiguullagiinId" -> stored="${_baiguullagiinId ?? 'null'}"',
    );
    debugPrint(
      _hasBaiguullagiinId
          ? '🧾 [SIGNUP] ✅ User HAS baiguullagiinId -> ORG signup flow'
          : '🧾 [SIGNUP] ⚠️ User has NO baiguullagiinId -> ADDRESS-required signup flow',
    );
  }

  bool get _hasBaiguullagiinId {
    final id = (_baiguullagiinId ?? '').trim();
    return id.isNotEmpty && id.toLowerCase() != 'null';
  }


  bool _validateUserInfoOnly() {
    return _phoneController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text.trim()) &&
        _ovogController.text.trim().isNotEmpty &&
        _nerController.text.trim().isNotEmpty &&
        _passwordController.text.trim().length == 4 &&
        _confirmPasswordController.text.trim().length == 4 &&
        _passwordController.text.trim() ==
            _confirmPasswordController.text.trim();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _nerController.dispose();
    _ovogController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final hasBasicFields =
        _phoneController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text.trim()) &&
        _ovogController.text.trim().isNotEmpty &&
        _nerController.text.trim().isNotEmpty &&
        _passwordController.text.trim().length == 4 &&
        _confirmPasswordController.text.trim().length == 4 &&
        _passwordController.text.trim() ==
            _confirmPasswordController.text.trim();

    return hasBasicFields;
  }

  Future<void> _handleRegistration() async {
    debugPrint(
      _hasBaiguullagiinId
          ? '🧾 [SIGNUP] Submitting with ORG flow (baiguullagiinId=${(_baiguullagiinId ?? '').trim()})'
          : '🧾 [SIGNUP] Submitting with NO-ORG flow (address required)',
    );
    // Validate form
    if (!_validateForm()) {
      showGlassSnackBar(
        context,
        message: 'Бүх шаардлагатай талбаруудыг бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // Validate the form itself to ensure all TextFormFields are valid
    if (!_formKey.currentState!.validate()) {
      showGlassSnackBar(
        context,
        message: 'Бүх шаардлагатай талбаруудыг зөв бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showGlassSnackBar(
        context,
        message: 'Нууц код хоорондоо таарахгүй байна',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final registrationData = <String, dynamic>{
        'utas': _phoneController.text.trim(),
        'nuutsUg': _passwordController.text.trim(),
        'ner': _nerController.text.trim(),
        'ovog': _ovogController.text.trim(),
        'mail': _emailController.text.trim(),
      };

      // ORG signup: must include baiguullagiinId
      final id = (_baiguullagiinId ?? widget.baiguullagiinId ?? '').trim();
      if (id.isNotEmpty && id.toLowerCase() != 'null') {
        registrationData['baiguullagiinId'] = id;
        registrationData['tsahilgaaniiZaalt'] = _tsahilgaaniiZaalt;
      }
      // Note: Address will be selected separately after registration

      print('🔍 [REGISTRATION] Registration data: $registrationData');

      final response = await ApiService.registerUser(registrationData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success'] == false) {
          final errorMessage =
              response['message'] ??
              response['aldaa'] ??
              'Бүртгэл үүсгэхэд алдаа гарлаа';

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        // Show success with animation
        showGlassSnackBar(
          context,
          message: 'Бүртгэл амжилттай үүслээ!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        // Add loading animation before redirect
        await Future.delayed(const Duration(milliseconds: 800));

        // If user doesn't have baiguullagiinId, navigate to address selection
        // Otherwise, navigate to login
        if (mounted) {
          final hasOrgId = (_baiguullagiinId ?? widget.baiguullagiinId ?? '').trim().isNotEmpty;
          if (!hasOrgId) {
            // Navigate to address selection screen for users without organization
            context.go('/address_selection');
          } else {
            // Navigate to login for users with organization
            context.go('/newtrekh');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        if (errorMessage.isEmpty) {
          errorMessage = 'Бүртгэл үүсгэхэд алдаа гарлаа';
        }

        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate() || !_validateUserInfoOnly()) {
      showGlassSnackBar(
        context,
        message: 'Хэрэглэгчийн мэдээллээ зөв бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    await _handleRegistration();
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    bool enabled = true,
  }) {
    return Builder(
      builder: (context) {
        final isDark = context.isDarkMode;
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            enabled: enabled,
            readOnly: !enabled,
            style: TextStyle(
              color: enabled
                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                  : (isDark
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.lightTextSecondary.withOpacity(0.6)),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.lightTextSecondary.withOpacity(0.6),
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.secondaryAccent.withOpacity(0.3)
                  : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.lightInputGray,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.grayColor.withOpacity(0.8)
                      : AppColors.deepGreen,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: suffixIcon,
              counterText: '',
            ),
            validator: validator,
          ),
        );
      },
    );
  }

  Widget _buildUserInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Хэрэглэгчийн мэдээлэл',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20.h),
        // Phone
        _buildTextField(
          controller: _phoneController,
          hintText: 'Утасны дугаар *',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Утасны дугаар оруулна уу';
            }
            if (value.length != 8) {
              return 'Утасны дугаар 8 оронтой байх ёстой';
            }
            return null;
          },
        ),
        // Email
        _buildTextField(
          controller: _emailController,
          hintText: 'Имэйл хаяг *',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Имэйл хаяг оруулна уу';
            }
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(value.trim())) {
              return 'Зөв имэйл хаяг оруулна уу';
            }
            return null;
          },
        ),
        // Last Name (Ovog)
        _buildTextField(
          controller: _ovogController,
          hintText: 'Овог *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Овог оруулна уу';
            }
            return null;
          },
        ),
        // First Name (Ner)
        _buildTextField(
          controller: _nerController,
          hintText: 'Нэр *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Нэр оруулна уу';
            }
            return null;
          },
        ),
        // Password
        _buildTextField(
          controller: _passwordController,
          hintText: 'Нууц код *',
          keyboardType: TextInputType.number,
          obscureText: _obscurePassword,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: context.isDarkMode
                  ? Colors.grey.withOpacity(0.7)
                  : AppColors.lightTextSecondary,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Нууц код оруулна уу';
            }
            if (value.length != 4) {
              return 'Нууц код 4 оронтой байх ёстой';
            }
            return null;
          },
        ),
        // Confirm Password
        _buildTextField(
          controller: _confirmPasswordController,
          hintText: 'Нууц код давтах *',
          keyboardType: TextInputType.number,
          obscureText: _obscureConfirmPassword,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: context.isDarkMode
                  ? Colors.grey.withOpacity(0.7)
                  : AppColors.lightTextSecondary,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Нууц кодыг давтаж оруулна уу';
            }
            return null;
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: context.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Бүртгэл үүсгэх',
            style: TextStyle(
              color: context.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18.sp,
            ),
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: context
                    .responsiveHorizontalPadding(
                      small: 28,
                      medium: 32,
                      large: 36,
                      tablet: 40,
                    )
                    .copyWith(
                      top: context.responsiveSpacing(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 24,
                      ),
                      bottom: context.responsiveSpacing(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 24,
                      ),
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User information form
                    _buildUserInfoContent(),
                    SizedBox(height: 16.h),

                    // Action button
                    GestureDetector(
                      onTap: _onPrimaryAction,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: _isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                'Бүртгүүлэх',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
