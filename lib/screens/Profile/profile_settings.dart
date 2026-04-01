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
import 'package:sukh_app/screens/settings/app_icon_selection_sheet.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

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
  final _emailController = TextEditingController();
  final _mashiniiDugaarController = TextEditingController();

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
  bool _isUpdatingPlate = false;
  bool _isPlateEditMode = false;

  // Biometric settings
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Address
  String? _currentAddress;
  bool _isLoadingAddress = false;
  int? _billingDay; // Day of month when billing/cycle resets

  // Organization membership
  String? _baiguullagiinId;
  String? _barilgiinId;

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
    _loadOrganizationInfo();
    _loadUserProfile();
    _checkBiometricStatus();
    _loadCurrentAddress();

    // Check for navigation actions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      if (state.uri.queryParameters['action'] == 'edit_email') {
        _showPersonalInfoModal(context);
      }
    });
  }

  Future<void> _loadOrganizationInfo() async {
    final baiguullagiinId = await StorageService.getBaiguullagiinId();
    final barilgiinId = await StorageService.getBarilgiinId();
    if (mounted) {
      setState(() {
        _baiguullagiinId = baiguullagiinId;
        _barilgiinId = barilgiinId;
      });
    }
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
    if (value) {
      // 1. Check if biometric is available
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Биометрийн баталгаажуулалт боломжгүй байна',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      // 2. Authenticate with biometric first to confirm identity
      final isAuthenticated = await BiometricService.authenticate();
      if (!isAuthenticated) {
        // User cancelled or failed biometric scan
        return;
      }

      // 3. Ask for numeric password to store for background login
      final password = await _showPasswordForBiometricDialog();
      if (password == null || password.isEmpty) {
        // User cancelled password entry
        return;
      }

      // 4. Save everything securely
      final storedPw = await StorageService.savePasswordForBiometric(password);
      final storedEnabled = await StorageService.setBiometricEnabled(true);

      if (storedPw && storedEnabled) {
        if (mounted) {
          setState(() {
            _biometricEnabled = true;
          });
          showGlassSnackBar(
            context,
            message: 'Биометрийн нэвтрэлт амжилттай идэвхэжлээ',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        }
      } else {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Тохиргоо хадгалахад алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } else {
      // Disabling biometric login
      await StorageService.clearSavedPasswordForBiometric();
      await StorageService.setBiometricEnabled(false);

      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
        showGlassSnackBar(
          context,
          message: 'Биометрийн нэвтрэлт идэвхгүй боллоо',
          icon: Icons.info,
          iconColor: Colors.orange,
        );
      }
    }
  }

  Future<String?> _showPasswordForBiometricDialog() async {
    _deletePasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(
                  color: AppColors.deepGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              title: Text(
                'Нууц код баталгаажуулах',
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Биометрээр нэвтрэх үед ашиглах 4 оронтой нууц кодоо оруулна уу.',
                    style: TextStyle(
                      color: context.textPrimaryColor.withOpacity(0.7),
                      fontSize: 12.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.deepGreen.withOpacity(0.2),
                      ),
                    ),
                    child: TextFormField(
                      controller: _deletePasswordController,
                      obscureText: _obscureDeletePassword,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '****',
                        hintStyle: TextStyle(
                          color: context.textSecondaryColor.withOpacity(0.2),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureDeletePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.deepGreen.withOpacity(0.5),
                          ),
                          onPressed: () => setState(
                            () => _obscureDeletePassword =
                                !_obscureDeletePassword,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Цуцлах',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 8.w),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_deletePasswordController.text.length == 4) {
                        Navigator.pop(
                          dialogContext,
                          _deletePasswordController.text,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                    ),
                    child: Text(
                      'Хадгалах',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> names = name.split(' ').where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return 'U';

    if (names.length >= 2) {
      return (names[0][0] + names[1][0]).toUpperCase();
    }
    return names[0][0].toUpperCase();
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
    _mashiniiDugaarController.dispose();
    _emailController.dispose();
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

          _nameController.text = userData['ner']?.toString() ?? '';

          if (userData['utas'] != null) {
            final utas = userData['utas'];
            if (utas is List && utas.isNotEmpty) {
              _phoneController.text = utas.first.toString();
            } else {
              _phoneController.text = utas.toString();
            }
          }
          _emailController.text = userData['mail']?.toString() ?? '';

          final plateRaw = userData['mashiniiDugaar'] ?? userData['dugaar'];
          if (plateRaw != null) {
            String plateText;
            if (plateRaw is List && plateRaw.isNotEmpty) {
              plateText = plateRaw.first.toString();
            } else {
              plateText = plateRaw.toString();
            }
            // Remove "БҮРТГЭЛГҮЙ" default value and set to empty
            if (plateText.trim().toUpperCase() == 'БҮРТГЭЛГҮЙ') {
              _mashiniiDugaarController.text = '';
            } else {
              _mashiniiDugaarController.text = plateText;
            }
          }

          // Fetch prioritized car plate from zochinSettings
          try {
            ApiService.fetchZochinSettings().then((response) {
              if (mounted && response != null) {
                // The settings can be at root or under data/result.mashin/orshinSuugchMashin
                final data = response['data'] ?? response['result'] ?? response;
                final orshinSuugchMashin = data['orshinSuugchMashin'];
                final mashin = data['mashin'] ?? data;

                // Prioritize orshinSuugchMashin for plate and metadata
                final plate = (orshinSuugchMashin != null)
                    ? (orshinSuugchMashin['mashiniiDugaar'] ??
                          orshinSuugchMashin['dugaar'])
                    : (mashin['mashiniiDugaar'] ?? mashin['dugaar']);

                if (plate != null) {
                  setState(() {
                    final newPlate = (plate is List && plate.isNotEmpty)
                        ? plate.first.toString()
                        : plate.toString();

                    // Remove "БҮРТГЭЛГҮЙ" default value and set to empty
                    if (newPlate.trim().toUpperCase() == 'БҮРТГЭЛГҮЙ') {
                      _mashiniiDugaarController.text = '';
                    } else {
                      _mashiniiDugaarController.text = newPlate;
                    }

                    if (_userData != null) {
                      _userData!['mashiniiDugaar'] =
                          _mashiniiDugaarController.text;

                      // Sync last update date (dugaarUurchilsunOgnoo)
                      final updateDate = (orshinSuugchMashin != null)
                          ? orshinSuugchMashin['dugaarUurchilsunOgnoo']
                          : (mashin['dugaarUurchilsunOgnoo'] ??
                                data['dugaarUurchilsunOgnoo']);

                      if (updateDate != null) {
                        _userData!['dugaarUurchilsunOgnoo'] = updateDate;
                      }
                    }
                  });
                }
              }
            });
          } catch (e) {
            debugPrint('Error fetching zochin settings: $e');
          }

          // Fetch billing day from cron data if available
          final barilgiinId = userData['barilgiinId']?.toString();
          if (barilgiinId != null && barilgiinId.isNotEmpty) {
            _fetchBillingCronInfo(barilgiinId);
          }

          _isLoading = false;
        });
        _loadOrganizationInfo(); // Sync IDs after profile load
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

  Future<void> _fetchBillingCronInfo(String barilgiinId) async {
    try {
      final cronData = await ApiService.fetchNekhemjlekhCron(
        barilgiinId: barilgiinId,
      );
      if (cronData['success'] == true && cronData['data'] != null) {
        final List dataList = cronData['data'] is List ? cronData['data'] : [];
        if (dataList.isNotEmpty) {
          final firstCron = dataList.first;
          if (firstCron['nekhemjlekhUusgekhOgnoo'] != null) {
            setState(() {
              _billingDay = int.tryParse(
                firstCron['nekhemjlekhUusgekhOgnoo'].toString(),
              );
              debugPrint('📅 [BILLING] Reset day set to: $_billingDay');
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [BILLING] Error fetching cron info: $e');
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

  Future<void> _handleChangePassword(
    void Function(void Function())? setModalState,
  ) async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    if (setModalState != null) {
      setModalState(() {
        _isChangingPassword = true;
      });
    } else {
      setState(() {
        _isChangingPassword = true;
      });
    }

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
        if (setModalState != null) {
          setModalState(() {
            _isChangingPassword = false;
          });
        } else {
          setState(() {
            _isChangingPassword = false;
          });
        }
      }
    }
  }

  bool _isPlateChangeAllowed() {
    if (_userData == null) return true;

    // If plate is empty/null, allow change regardless of date
    final plateNumber = _userData!['mashiniiDugaar'] ?? _userData!['dugaar'];
    if (plateNumber == null || plateNumber.toString().isEmpty) return true;

    final lastUpdate = _userData!['dugaarUurchilsunOgnoo'];
    if (lastUpdate == null) return true;

    try {
      final lastDate = DateTime.parse(lastUpdate.toString());
      final now = DateTime.now();

      if (_billingDay != null) {
        // Find the start date of the current billing cycle
        DateTime currentCycleStart;
        if (now.day >= _billingDay!) {
          currentCycleStart = DateTime(now.year, now.month, _billingDay!);
        } else {
          int prevMonth = now.month - 1;
          int prevYear = now.year;
          if (prevMonth == 0) {
            prevMonth = 12;
            prevYear--;
          }
          currentCycleStart = DateTime(prevYear, prevMonth, _billingDay!);
        }

        // Allowed if last update was before this cycle started
        return lastDate.isBefore(currentCycleStart);
      }

      // Default: Calendar month reset (1st of month)
      return lastDate.month != now.month || lastDate.year != now.year;
    } catch (e) {
      return true;
    }
  }

  Future<void> _handleUpdatePlateNumber() async {
    if (_mashiniiDugaarController.text.isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Машины дугаар оруулна уу',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    if (!_isPlateChangeAllowed()) {
      showGlassSnackBar(
        context,
        message: 'Та машины дугаараа сард 1 удаа солих боломжтой',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    setState(() {
      _isUpdatingPlate = true;
    });

    try {
      String? baiguullagiinId = await StorageService.getBaiguullagiinId();
      String? barilgiinId = await StorageService.getBarilgiinId();

      // Fallback to class variables or userData if storage is null
      baiguullagiinId ??= _baiguullagiinId;
      barilgiinId ??= _barilgiinId;

      if (baiguullagiinId == null && _userData != null) {
        baiguullagiinId = _userData!['baiguullagiinId']?.toString();
        barilgiinId ??= _userData!['barilgiinId']?.toString();

        // If still null, try to find it in the toots array
        if (baiguullagiinId == null &&
            _userData!['toots'] != null &&
            (_userData!['toots'] as List).isNotEmpty) {
          final firstToot = _userData!['toots'][0] as Map<String, dynamic>;
          baiguullagiinId = firstToot['baiguullagiinId']?.toString();
          barilgiinId ??= firstToot['barilgiinId']?.toString();
        }
      }

      if (baiguullagiinId == null) {
        throw Exception('Байгууллагын мэдээлэл олдсонгүй');
      }

      final response = await ApiService.zochinHadgalya(
        mashiniiDugaar: _mashiniiDugaarController.text,
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        ezemshigchiinUtas: _phoneController.text,
        orshinSuugchMedeelel: {'zochinTurul': 'Оршин суугч'},
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _isPlateEditMode = false;
            // Immediate UI update derived from the response
            final data = response['data'] ?? response;
            final osm = data['orshinSuugchMashin'];
            final mashin = data['mashin'];

            final plate = (osm != null)
                ? (osm['mashiniiDugaar'] ?? osm['dugaar'])
                : mashin?['dugaar'];
            if (plate != null && _userData != null) {
              final newPlate = plate.toString();

              // Remove "БҮРТГЭЛГҮЙ" default value and set to empty
              if (newPlate.trim().toUpperCase() == 'БҮРТГЭЛГҮЙ') {
                _mashiniiDugaarController.text = '';
              } else {
                _mashiniiDugaarController.text = newPlate;
              }

              _userData!['mashiniiDugaar'] = _mashiniiDugaarController.text;

              // Update metadata for restriction logic
              final updateDate =
                  osm?['dugaarUurchilsunOgnoo'] ??
                  mashin?['dugaarUurchilsunOgnoo'];
              if (updateDate != null) {
                _userData!['dugaarUurchilsunOgnoo'] = updateDate;
              }
            }
          });
          showGlassSnackBar(
            context,
            message: 'Машины дугаар амжилттай шинэчлэгдлээ',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          // Refresh background data to ensure everything is perfect
          _loadUserProfile();
        } else {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Remove technical prefix for cleaner display
        String error = e.toString().replaceFirst('Exception: ', '');
        showGlassSnackBar(
          context,
          message: error,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPlate = false;
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
              backgroundColor: context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
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
                  color: AppColors.deepGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              title: Text(
                'Нууц үг оруулах',
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Бүртгэл устгахын тулд одоогийн нууц үгээ оруулна уу',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
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
                      fontSize: 12.sp,
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
                      fontSize: 12,
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
          backgroundColor: context.isDarkMode
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w),
            side: BorderSide(
              color: AppColors.deepGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Бүртгэл устгах',
            style: TextStyle(
              color: AppColors.deepGreen,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Та өөрийн бүртгэлтэй хаягийг устгах хүсэлтэй байна уу?',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.sp),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Үгүй',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 12.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                'Тийм',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
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
          await SessionService.logout();
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
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? AppColors.deepGreen.withOpacity(0.7)
                : AppColors.deepGreen,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.deepGreen,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Theme.of(context).platform == TargetPlatform.iOS
              ? Image.asset(
                  'lib/assets/img/face-id.png',
                  width: 16.sp,
                  height: 16.sp,
                  color: isDark
                      ? AppColors.deepGreen.withOpacity(0.7)
                      : AppColors.deepGreen,
                )
              : Icon(
                  Icons.fingerprint_rounded,
                  color: isDark
                      ? AppColors.deepGreen.withOpacity(0.7)
                      : AppColors.deepGreen,
                  size: 16.sp,
                ),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.deepGreen,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
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
    bool isActive = false,
  }) {
    final isDark = context.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive
                ? null
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.deepGreen.withOpacity(0.2)),
              width: 1,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: AppColors.deepGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.deepGreen,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCarPlateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = context.isDarkMode;
          final isAllowed = _isPlateChangeAllowed();

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161618) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.deepGreen,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          'Миний машин',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Улсын дугаар',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (_mashiniiDugaarController.text.length < 4)
                        _buildModernTextField(
                          key: const ValueKey('plate_number'),
                          controller: _mashiniiDugaarController,
                          label: 'Дугаар (Жишээ: 1234УАА)',
                          icon: Icons.numbers_rounded,
                          hint: '0000AAA',
                          enabled: isAllowed,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(7),
                            PlateNumberFormatter(),
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        )
                      else
                        _buildModernTextField(
                          key: const ValueKey('plate_text'),
                          controller: _mashiniiDugaarController,
                          label: 'Дугаар (Жишээ: 1234УАА)',
                          icon: Icons.numbers_rounded,
                          hint: '0000AAA',
                          enabled: isAllowed,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(7),
                            PlateNumberFormatter(),
                          ],
                          keyboardType: TextInputType.text,
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                      if (!isAllowed) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: 18.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Та машины дугаараа сард 1 удаа солих боломжтой.',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isAllowed && !_isUpdatingPlate)
                              ? () async {
                                  // Validation
                                  final text = _mashiniiDugaarController.text
                                      .toUpperCase()
                                      .replaceAll(' ', '')
                                      .trim();
                                  if (text.length != 7) {
                                    showGlassSnackBar(
                                      context,
                                      message: 'Дугаар 7 тэмдэгт байх ёстой',
                                      icon: Icons.warning,
                                    );
                                    return;
                                  }
                                  // First 4 numbers
                                  final numbers = text.substring(0, 4);
                                  if (int.tryParse(numbers) == null) {
                                    showGlassSnackBar(
                                      context,
                                      message: 'Эхний 4 тэмдэгт тоо байх ёстой',
                                      icon: Icons.warning,
                                    );
                                    return;
                                  }
                                  // Last 3 letters
                                  final letters = text.substring(4);
                                  final letterRegex = RegExp(
                                    r'^[A-ZА-ЯЁӨҮ]{3}$',
                                  );
                                  if (!letterRegex.hasMatch(letters)) {
                                    showGlassSnackBar(
                                      context,
                                      message:
                                          'Сүүлийн 3 тэмдэгт үсэг байх ёстой',
                                      icon: Icons.warning,
                                    );
                                    return;
                                  }

                                  // Update the controller text with the CAPS version before API call
                                  _mashiniiDugaarController.text = text;

                                  Navigator.pop(context);
                                  await _handleUpdatePlateNumber();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isUpdatingPlate
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Хадгалах',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = context.isDarkMode;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.r),
              topRight: Radius.circular(28.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 14.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.deepGreen,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        'Хувийн мэдээлэл',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Info
                      _buildSubSectionTitle('Үндсэн мэдээлэл'),
                      SizedBox(height: 12.h),
                      _buildModernTextField(
                        controller: _nameController,
                        label: 'Нэр',
                        icon: Icons.person_outline_rounded,
                        enabled: true,
                        hint: 'Нэр оруулах',
                      ),
                      SizedBox(height: 16.h),
                      _buildModernTextField(
                        controller: _phoneController,
                        label: 'Утасны дугаар',
                        icon: Icons.phone_android_rounded,
                        enabled: true,
                        hint: 'Утасны дугаар хоосон байна',
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16.h),
                      _buildModernTextField(
                        controller: _emailController,
                        label: 'И-мэйл хаяг',
                        icon: Icons.alternate_email_rounded,
                        enabled: true,
                        hint: 'И-мэйл хаяг оруулах',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            if (_nameController.text.trim().isEmpty) {
                              showGlassSnackBar(
                                context,
                                message: 'Нэрээ оруулна уу',
                                icon: Icons.warning,
                              );
                              return;
                            }
                            if (_phoneController.text.trim().isEmpty) {
                              showGlassSnackBar(
                                context,
                                message: 'Утасны дугаараа оруулна уу',
                                icon: Icons.warning,
                              );
                              return;
                            }
                            if (_emailController.text.isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(_emailController.text)) {
                                showGlassSnackBar(
                                  context,
                                  message: 'Зөв и-мэйл хаяг оруулна уу',
                                  icon: Icons.error,
                                );
                                return;
                              }
                            }

                            try {
                              final response = await ApiService.updateUserProfile({
                                'ner': _nameController.text.trim(),
                                'mail': _emailController.text.trim(),
                                'utas': _phoneController.text.trim(),
                              });
                              if (response['success'] == true || response['_id'] != null) {
                                showGlassSnackBar(
                                  context,
                                  message: 'Мэдээлэл амжилттай хадгалагдлаа',
                                  icon: Icons.check_circle,
                                  iconColor: Colors.green,
                                );
                                _loadUserProfile(); // Reload to update state
                              }
                            } catch (e) {
                              showGlassSnackBar(
                                context,
                                message: 'Алдаа гарлаа: $e',
                                icon: Icons.error,
                              );
                            }
                          },
                          label: Text(
                            'Хадгалах',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.deepGreen,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            backgroundColor: AppColors.deepGreen.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),


                      SizedBox(height: 32.h),

                      // Section 2: Address & Property
                      Row(
                        children: [
                          _buildSubSectionTitle('Хаягийн мэдээлэл'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _handleUpdateAddress(),
                            icon: Icon(
                              Icons.edit_location_alt_rounded,
                              size: 14.sp,
                            ),
                            label: Text(
                              'Солих',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.deepGreen,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (_userData != null)
                        _buildUserDataGrid()
                      else
                        _buildAddressPlaceholder(context),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textSecondaryColor,
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAddressPlaceholder(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: () => _handleUpdateAddress(),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.deepGreen,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentAddress != null && _currentAddress!.isNotEmpty
                        ? _currentAddress!
                        : 'Хаяг бүртгэгдээгүй байна',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_currentAddress == null || _currentAddress!.isEmpty)
                    Text(
                      'Энд дарж хаягаа сонгоно уу',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? hint,
    VoidCallback? onTap,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Key? key,
  }) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.deepGreen, size: 14.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimaryColor.withOpacity(0.7),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextField(
            key: key ?? (keyboardType != null ? ValueKey(keyboardType) : null),
            autofocus: enabled,
            controller: controller,
            enabled: true,
            onTap: onTap,
            readOnly: !enabled || onTap != null,
            obscureText: isPassword,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.5),
                fontSize: 13.sp,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final isDark = modalContext.isDarkMode;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161618) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28.r),
                topRight: Radius.circular(28.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 14.h),
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.lock_person_rounded,
                            color: Colors.amber[700],
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            'Нууц үг солих',
                            style: TextStyle(
                              color: modalContext.textPrimaryColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernPasswordField(
                            controller: _currentPasswordController,
                            label: 'Одоогийн нууц үг',
                            hint: '••••',
                            obscureText: _obscureCurrentPassword,
                            onToggle: () => setModalState(
                              () => _obscureCurrentPassword =
                                  !_obscureCurrentPassword,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildModernPasswordField(
                            controller: _newPasswordController,
                            label: 'Шинэ нууц үг',
                            hint: '••••',
                            obscureText: _obscureNewPassword,
                            onToggle: () => setModalState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildModernPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Шинэ нууц үг давтах',
                            hint: '••••',
                            obscureText: _obscureConfirmPassword,
                            onToggle: () => setModalState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),

                          SizedBox(height: 32.h),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isChangingPassword
                                  ? null
                                  : () => _handleChangePassword(setModalState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepGreen,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.deepGreen.withOpacity(
                                  0.4,
                                ),
                              ),
                              child: _isChangingPassword
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Нууц үг хадгалах',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textPrimaryColor.withOpacity(0.7),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.3),
                letterSpacing: 4,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.deepGreen.withOpacity(0.7),
                  size: 20.sp,
                ),
                onPressed: onToggle,
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Нууц үг оруулна уу';
              if (val.length < 4) return '4 оронтой байх ёстой';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: isDark
              ? AppColors.deepGreen.withOpacity(0.2)
              : AppColors.deepGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
        fontSize: 13.sp,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.6)
              : AppColors.lightTextSecondary,
          fontSize: 12.sp,
        ),
        prefixIcon: Icon(icon, color: AppColors.deepGreen, size: 18.sp),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF8F8F8),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : AppColors.deepGreen.withOpacity(0.3),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.deepGreen.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 1.5.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(color: Colors.red, width: 1.5.w),
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
      keyboardType: TextInputType.text,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.6)
              : AppColors.lightTextSecondary,
          fontSize: 12.sp,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppColors.deepGreen,
          size: 18.sp,
        ),
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

    // Build list of data items - only bair, toot
    List<Map<String, dynamic>> dataItems = [];

    // Байр (Address)
    String? bairText;
    if (_userData!['bairniiNer'] != null &&
        _userData!['bairniiNer'].toString().isNotEmpty) {
      bairText = _userData!['bairniiNer'].toString();
    }

    // Always add Address row - explicit request to re-enable address selection if missing
    dataItems.add({
      'icon': Icons.location_on_outlined,
      'label': 'Байр',
      'value': (bairText != null && bairText.isNotEmpty)
          ? bairText
          : 'Хаяг сонгох',
      'action': (bairText == null || bairText.isEmpty)
          ? () {
              _handleUpdateAddress();
            }
          : null,
      'isLink': (bairText == null || bairText.isEmpty),
    });

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
        style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
      );
    }

    final isDark = context.isDarkMode;

    // Build list layout with icon next to text
    return Column(
      children: dataItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == dataItems.length - 1;
        final action = item['action'] as VoidCallback?;
        final isLink = item['isLink'] == true;

        return InkWell(
          onTap: action,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppColors.deepGreen,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item['value'] as String,
                        style: TextStyle(
                          color: isLink
                              ? AppColors.deepGreen
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          decoration: isLink ? TextDecoration.underline : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLink)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.deepGreen,
                    size: 20.sp,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? AppColors.deepGreen.withOpacity(0.15)
              : AppColors.deepGreen.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, color: AppColors.deepGreen, size: 14.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 11.sp,
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.deepGreen, size: 16.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 12.sp,
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
    String? title,
    IconData? icon,
    required List<Widget> children,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.deepGreen.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.deepGreen.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(icon, size: 16.sp, color: AppColors.deepGreen),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepGreen,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              (title != null && icon != null) ? 0 : 16.h,
              16.w,
              16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    String displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Хэрэглэгч';
    String initialSource = displayName;

    // Try to get both initials from userData if possible
    if (_userData != null) {
      final ovog = _userData!['ovog']?.toString() ?? '';
      final ner = _userData!['ner']?.toString() ?? '';
      if (ovog.isNotEmpty && ner.isNotEmpty) {
        initialSource = '$ovog $ner';
      }
    }

    final initials = _getInitials(initialSource);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.w),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _phoneController.text.isNotEmpty
                        ? _phoneController.text
                        : 'Утас тодорхойгүй',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = context.isDarkMode;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
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
              'Тохиргоо',
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color? iconColor,
    bool showBorder = true,
  }) {
    final isDark = context.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.deepGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.deepGreen,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white24 : Colors.black12,
                    size: 20.sp,
                  ),
            ],
          ),
        ),
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
                    fontSize: isLarge ? 15.sp : 12.sp,
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
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: AppBackground(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : FadeTransition(
                opacity: _fadeAnimation,
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
                            // 1. Account Info
                            _buildSection(
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.account_circle_outlined,
                                  title: 'Хувийн мэдээлэл',
                                  subtitle: 'Овог нэр, утас, хаягийн мэдээлэл',
                                  onTap: () => _showPersonalInfoModal(context),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.directions_car_filled_outlined,
                                  title: 'Миний машин',
                                  subtitle:
                                      _mashiniiDugaarController.text.isNotEmpty
                                      ? _mashiniiDugaarController.text
                                      : 'Дугаар тохируулах',
                                  showBorder: false,
                                  onTap: () {
                                    _showCarPlateModal(context);
                                  },
                                ),
                              ],
                            ),

                            // 2. Unified Settings (Security & App)
                            _buildSection(
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.lock_reset_rounded,
                                  title: 'Нууц код солих',
                                  subtitle: 'Нэвтрэх 4 оронтой код хадгалах',
                                  showBorder: !_biometricAvailable,
                                  onTap: () =>
                                      _showChangePasswordModal(context),
                                ),
                                if (_biometricAvailable)
                                  _buildSettingsTile(
                                    icon:
                                        Theme.of(context).platform ==
                                            TargetPlatform.iOS
                                        ? Icons.face_rounded
                                        : Icons.fingerprint_rounded,
                                    title:
                                        Theme.of(context).platform ==
                                            TargetPlatform.iOS
                                        ? 'Face ID'
                                        : 'Хурууны хээ',
                                    subtitle: _biometricEnabled
                                        ? 'Идэвхтэй'
                                        : 'Идэвхгүй',
                                    showBorder: false,
                                    trailing: Switch(
                                      value: _biometricEnabled,
                                      onChanged: (val) =>
                                          _handleBiometricToggle(val),
                                      activeColor: AppColors.deepGreen,
                                    ),
                                    onTap: () => _handleBiometricToggle(
                                      !_biometricEnabled,
                                    ),
                                  ),
                              ],
                            ),
                            // 4. Logout & Delete
                            _buildSection(
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.delete_forever_rounded,
                                  title: 'Бүртгэл устгах',
                                  subtitle:
                                      'Бүртгэл болон бүх мэдээллийг устгах',
                                  iconColor: Colors.redAccent,
                                  showBorder: false,
                                  onTap: _handleDeleteAccount,
                                ),
                              ],
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
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    String result = '';

    for (int i = 0; i < text.length && i < 7; i++) {
      final char = text[i];
      if (i < 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          result += char;
        }
      } else {
        // Last 3 characters must be Cyrillic letters
        if (RegExp(r'[А-ЯӨҮЁ]').hasMatch(char)) {
          result += char;
        }
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
