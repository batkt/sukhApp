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
  // Address controllers (used when baiguullagiinId is not available)
  final TextEditingController _duuregController = TextEditingController();
  final TextEditingController _horooController = TextEditingController();
  final TextEditingController _bairController = TextEditingController();
  final TextEditingController _ortsController = TextEditingController();
  final TextEditingController _tootController = TextEditingController();

  // Hidden fields (auto-filled, not displayed)
  String? _baiguullagiinId;
  int _tsahilgaaniiZaalt = 200; // Default value
  static const String _defaultDavkhar = '1';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 1: Хэрэглэгчийн мэдээлэл
  // Step 2: Хаягийн мэдээлэл (only when NO-ORG)
  int _currentStep = 1;

  // Address dropdown data (Wallet Address API)
  bool _isLoadingAddressData = false;
  List<Map<String, dynamic>> _walletCities = [];
  List<Map<String, dynamic>> _walletDistricts = [];
  List<Map<String, dynamic>> _walletKhoroos = [];
  List<Map<String, dynamic>> _walletBuildings = [];

  String? _selectedCityId; // hidden (auto-selected: ULAANBAATAR)
  String? _selectedDistrictId; // duureg
  String? _selectedKhorooId; // horoo
  String? _selectedBuildingId; // bair

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

  // Step 2 should be shown ONLY for true NO-ORG (mobile) signups.
  // If user has baiguullagiinId (web-created user), NEVER go to step 2,
  // even if forceNoOrg was accidentally passed as true.
  bool get _needsAddressStep {
    final routeOrgId = (widget.baiguullagiinId ?? '').trim();
    final hasRouteOrgId =
        routeOrgId.isNotEmpty && routeOrgId.toLowerCase() != 'null';
    final hasOrg = _hasBaiguullagiinId || hasRouteOrgId;
    return widget.forceNoOrg == true && !hasOrg;
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
    _duuregController.dispose();
    _horooController.dispose();
    _bairController.dispose();
    _ortsController.dispose();
    _tootController.dispose();
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

    // If this is NO-ORG signup, require full address as well
    if (_needsAddressStep) {
      final hasAddress =
          _duuregController.text.trim().isNotEmpty &&
          _horooController.text.trim().isNotEmpty &&
          _bairController.text.trim().isNotEmpty &&
          _ortsController.text.trim().isNotEmpty &&
          _tootController.text.trim().isNotEmpty;
      return hasBasicFields && hasAddress;
    }

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
      if (!_needsAddressStep) {
        final id = (_baiguullagiinId ?? widget.baiguullagiinId ?? '').trim();
        if (id.isEmpty || id.toLowerCase() == 'null') {
          throw Exception('Байгууллагын мэдээлэл олдсонгүй');
        }
        registrationData['baiguullagiinId'] = id;
        registrationData['tsahilgaaniiZaalt'] = _tsahilgaaniiZaalt;
      } else {
        // User WITHOUT baiguullagiinId – require and send full address
        registrationData.addAll({
          'duureg': _duuregController.text.trim(),
          'horoo': _horooController.text.trim(),
          'bairniiNer': _bairController.text.trim(),
          'orts': _ortsController.text.trim(),
          // NOTE: Davkhar field removed from UI; send a safe default so backend won't reject.
          'davkhar': _defaultDavkhar,
          'toot': _tootController.text.trim(),
        });
      }

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

        // Navigate to login with smooth transition
        if (mounted) {
          context.go('/newtrekh');
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

    // Step 1: validate user info first
    if (_currentStep == 1) {
      // Log ONLY when user clicks "Дараах" / "Бүртгүүлэх" on Step 1
      debugPrint(
        '🧭 [SIGNUP][STEP1_CLICK] '
        'forceNoOrg=${widget.forceNoOrg}, '
        'route.baiguullagiinId=${widget.baiguullagiinId}, '
        '_baiguullagiinId=$_baiguullagiinId, '
        '_hasBaiguullagiinId=$_hasBaiguullagiinId, '
        '_needsAddressStep=$_needsAddressStep',
      );

      if (!_formKey.currentState!.validate() || !_validateUserInfoOnly()) {
        showGlassSnackBar(
          context,
          message: 'Хэрэглэгчийн мэдээллээ зөв бөглөнө үү',
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      // If NO-ORG, go to step 2 (address). If ORG, submit immediately.
      if (_needsAddressStep) {
        setState(() {
          _currentStep = 2;
        });
        await _ensureWalletAddressDataLoaded();
        return;
      }

      await _handleRegistration();
      return;
    }

    // Step 2: submit full form (includes address)
    await _handleRegistration();
  }

  String _pickString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) return v.toString();
    }
    return '';
  }

  String _getCityId(Map<String, dynamic> m) =>
      _pickString(m, ['cityId', 'id', '_id']);
  String _getDistrictId(Map<String, dynamic> m) =>
      _pickString(m, ['districtId', 'id', '_id']);
  String _getKhorooId(Map<String, dynamic> m) =>
      _pickString(m, ['khorooId', 'id', '_id']);
  String _getBuildingId(Map<String, dynamic> m) =>
      _pickString(m, ['bairId', 'buildingId', 'id', '_id']);

  String _getName(Map<String, dynamic> m) => _pickString(m, [
    'name',
    'districtName',
    'khorooName',
    'bairNer',
    'cityName',
  ]);

  Future<void> _ensureWalletAddressDataLoaded() async {
    if (_walletDistricts.isNotEmpty || _isLoadingAddressData) return;

    setState(() {
      _isLoadingAddressData = true;
    });

    try {
      _walletCities = await ApiService.getWalletCities();

      // Auto-select ULAANBAATAR if present
      Map<String, dynamic>? ulaan;
      for (final c in _walletCities) {
        final name = _getName(c).toUpperCase();
        if (name.contains('УЛААНБААТАР') || name.contains('ULAANBAATAR')) {
          ulaan = c;
          break;
        }
      }
      final city =
          ulaan ?? (_walletCities.isNotEmpty ? _walletCities.first : null);
      _selectedCityId = city != null ? _getCityId(city) : null;

      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
        _walletDistricts = await ApiService.getWalletDistricts(
          _selectedCityId!,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Хаягийн мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddressData = false;
        });
      }
    }
  }

  Future<void> _onSelectDuureg(String? districtId) async {
    if (districtId == null || districtId.isEmpty) return;

    setState(() {
      _selectedDistrictId = districtId;
      _selectedKhorooId = null;
      _selectedBuildingId = null;
      _walletKhoroos = [];
      _walletBuildings = [];
      _horooController.text = '';
      _bairController.text = '';
    });

    final district = _walletDistricts.firstWhere(
      (d) => _getDistrictId(d) == districtId,
      orElse: () => <String, dynamic>{},
    );
    _duuregController.text = _getName(district);

    setState(() {
      _isLoadingAddressData = true;
    });
    try {
      _walletKhoroos = await ApiService.getWalletKhoroos(districtId);
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Хороо татахад алдаа гарлаа: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddressData = false;
        });
      }
    }
  }

  Future<void> _onSelectHoroo(String? khorooId) async {
    if (khorooId == null || khorooId.isEmpty) return;

    setState(() {
      _selectedKhorooId = khorooId;
      _selectedBuildingId = null;
      _walletBuildings = [];
      _bairController.text = '';
    });

    final khoroo = _walletKhoroos.firstWhere(
      (h) => _getKhorooId(h) == khorooId,
      orElse: () => <String, dynamic>{},
    );
    _horooController.text = _getName(khoroo);

    setState(() {
      _isLoadingAddressData = true;
    });
    try {
      _walletBuildings = await ApiService.getWalletBuildings(khorooId);
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Байр татахад алдаа гарлаа: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddressData = false;
        });
      }
    }
  }

  void _onSelectBair(String? buildingId) {
    if (buildingId == null || buildingId.isEmpty) return;
    setState(() {
      _selectedBuildingId = buildingId;
    });

    final building = _walletBuildings.firstWhere(
      (b) => _getBuildingId(b) == buildingId,
      orElse: () => <String, dynamic>{},
    );
    _bairController.text = _getName(building);
  }

  Future<String?> _showPickerBottomSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) getId,
    required String Function(Map<String, dynamic>) getLabel,
    required String? selectedId,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = items.where((m) {
              final name = getLabel(m).toLowerCase();
              return query.isEmpty || name.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 12.w, 8.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: context.titleStyle(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: TextStyle(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Хайх...',
                        hintStyle: TextStyle(color: context.textSecondaryColor),
                        filled: true,
                        fillColor: context.accentBackgroundColor,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.textSecondaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Мэдээлэл олдсонгүй',
                              style: context.descriptionStyle(
                                color: context.textSecondaryColor,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.only(bottom: 20.h),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: context.borderColor),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final id = getId(item);
                              final label = getLabel(item);
                              final isSelected = selectedId == id;

                              return ListTile(
                                onTap: () => Navigator.of(context).pop(id),
                                title: Text(
                                  label,
                                  style: context.descriptionStyle(
                                    color: context.textPrimaryColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.deepGreen,
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickerField({
    required String hintText,
    required String title,
    required String displayText,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) getId,
    required String Function(Map<String, dynamic>) getLabel,
    required Future<void> Function(String?) onSelected,
    required String? Function(String?) validator,
    bool enabled = true,
    bool loading = false,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final isDark = context.isDarkMode;
        final hasValue = displayText.trim().isNotEmpty;
        final showText = hasValue ? displayText : hintText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: state.hasError ? 6.h : 16.h),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: (!enabled || loading)
                      ? null
                      : () async {
                          final picked = await _showPickerBottomSheet(
                            title: title,
                            items: items,
                            getId: getId,
                            getLabel: getLabel,
                            selectedId: value,
                          );
                          if (picked == null) return;
                          state.didChange(picked);
                          await onSelected(picked);
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.secondaryAccent.withOpacity(0.3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: state.hasError
                            ? Colors.red
                            : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.lightInputGray),
                        width: state.hasError ? 1.5 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            showText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: (!enabled)
                                  ? (isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : AppColors.lightTextSecondary
                                              .withOpacity(0.6))
                                  : (hasValue
                                        ? (isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary)
                                        : (isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : AppColors.lightTextSecondary
                                                    .withOpacity(0.6))),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (loading)
                          SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGreen,
                            ),
                          )
                        else
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : AppColors.lightTextSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: EdgeInsets.only(left: 12.w, bottom: 10.h),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
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

  Widget _buildAddressContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Хаягийн мэдээлэл',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        _buildPickerField(
          hintText: 'Дүүрэг *',
          title: 'Дүүрэг сонгох',
          displayText: _duuregController.text,
          value: _selectedDistrictId,
          items: _walletDistricts,
          getId: _getDistrictId,
          getLabel: _getName,
          loading: _isLoadingAddressData,
          onSelected: (v) async => _onSelectDuureg(v),
          validator: (_) {
            if (_currentStep == 2 && _needsAddressStep) {
              if (_selectedDistrictId == null || _selectedDistrictId!.isEmpty) {
                return 'Дүүрэг сонгоно уу';
              }
            }
            return null;
          },
          enabled: true,
        ),
        _buildPickerField(
          hintText: 'Хороо *',
          title: 'Хороо сонгох',
          displayText: _horooController.text,
          value: _selectedKhorooId,
          items: _walletKhoroos,
          getId: _getKhorooId,
          getLabel: _getName,
          loading: _isLoadingAddressData,
          onSelected: (v) async => _onSelectHoroo(v),
          validator: (_) {
            if (_currentStep == 2 && _needsAddressStep) {
              if (_selectedKhorooId == null || _selectedKhorooId!.isEmpty) {
                return 'Хороо сонгоно уу';
              }
            }
            return null;
          },
          enabled:
              _selectedDistrictId != null && _selectedDistrictId!.isNotEmpty,
        ),
        _buildPickerField(
          hintText: 'Байрны нэр *',
          title: 'Байр сонгох',
          displayText: _bairController.text,
          value: _selectedBuildingId,
          items: _walletBuildings,
          getId: _getBuildingId,
          getLabel: _getName,
          loading: _isLoadingAddressData,
          onSelected: (v) async {
            _onSelectBair(v);
          },
          validator: (_) {
            if (_currentStep == 2 && _needsAddressStep) {
              if (_selectedBuildingId == null || _selectedBuildingId!.isEmpty) {
                return 'Байр сонгоно уу';
              }
            }
            return null;
          },
          enabled: _selectedKhorooId != null && _selectedKhorooId!.isNotEmpty,
        ),
        _buildTextField(
          controller: _ortsController,
          hintText: 'Орц *',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Орц оруулна уу';
            }
            return null;
          },
        ),
        _buildTextField(
          controller: _tootController,
          hintText: 'Тоот *',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Тоот оруулна уу';
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

                    // Step 2 only AFTER step 1 is completed (NO-ORG users)
                    if (_currentStep == 2 && _needsAddressStep) ...[
                      _buildAddressContent(),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _currentStep = 1;
                                });
                              },
                        child: Text(
                          'Буцах',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
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
                                (_currentStep == 1 && _needsAddressStep)
                                    ? 'Дараах'
                                    : 'Бүртгүүлэх',
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
