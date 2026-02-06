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
    _mashiniiDugaarController.dispose();
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
            final utas = userData['utas'];
            if (utas is List && utas.isNotEmpty) {
              _phoneController.text = utas.first.toString();
            } else {
              _phoneController.text = utas.toString();
            }
          }

          final plateRaw = userData['mashiniiDugaar'] ?? userData['dugaar'];
          if (plateRaw != null) {
            if (plateRaw is List && plateRaw.isNotEmpty) {
              _mashiniiDugaarController.text = plateRaw.first.toString();
            } else {
              _mashiniiDugaarController.text = plateRaw.toString();
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
                    ? (orshinSuugchMashin['mashiniiDugaar'] ?? orshinSuugchMashin['dugaar'])
                    : (mashin['mashiniiDugaar'] ?? mashin['dugaar']);
                
                if (plate != null) {
                  setState(() {
                    final newPlate = (plate is List && plate.isNotEmpty)
                        ? plate.first.toString()
                        : plate.toString();
                    
                    _mashiniiDugaarController.text = newPlate;
                    if (_userData != null) {
                      _userData!['mashiniiDugaar'] = newPlate;
                      
                      // Sync last update date (dugaarUurchilsunOgnoo)
                      final updateDate = (orshinSuugchMashin != null)
                          ? orshinSuugchMashin['dugaarUurchilsunOgnoo']
                          : (mashin['dugaarUurchilsunOgnoo'] ?? data['dugaarUurchilsunOgnoo']);
                          
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
      final cronData = await ApiService.fetchNekhemjlekhCron(barilgiinId: barilgiinId);
      if (cronData['success'] == true && cronData['data'] != null) {
        final List dataList = cronData['data'] is List ? cronData['data'] : [];
        if (dataList.isNotEmpty) {
          final firstCron = dataList.first;
          if (firstCron['nekhemjlekhUusgekhOgnoo'] != null) {
            setState(() {
              _billingDay = int.tryParse(firstCron['nekhemjlekhUusgekhOgnoo'].toString());
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
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();
      
      if (baiguullagiinId == null) {
        throw Exception('Байгууллагын мэдээлэл олдсонгүй');
      }

      final response = await ApiService.zochinHadgalya(
        mashiniiDugaar: _mashiniiDugaarController.text,
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        ezemshigchiinUtas: _phoneController.text,
        orshinSuugchMedeelel: {
          'zochinTurul': 'Оршин суугч',
        },
      ); 
      
      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _isPlateEditMode = false;
            // Immediate UI update derived from the response
            final data = response['data'] ?? response;
            final osm = data['orshinSuugchMashin'];
            final mashin = data['mashin'];
            
            final plate = (osm != null) ? (osm['mashiniiDugaar'] ?? osm['dugaar']) : mashin?['dugaar'];
            if (plate != null && _userData != null) {
              final newPlate = plate.toString();
              _mashiniiDugaarController.text = newPlate;
              _userData!['mashiniiDugaar'] = newPlate;
              
              // Update metadata for restriction logic
              final updateDate = osm?['dugaarUurchilsunOgnoo'] ?? mashin?['dugaarUurchilsunOgnoo'];
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
            'Та өөрийн бүртгэлтэй хаягийг устгах хүсэлтэй байна у|?',
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

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = context.isDarkMode;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.deepGreen.withOpacity(0.3)
                  : AppColors.deepGreen.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
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
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Хаяг',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
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
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_currentAddress != null &&
                        _currentAddress!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _currentAddress!,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Хаяг тодорхойлогдоогүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
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
                          size: 14.sp,
                        ),
                        label: Text(
                          'Хаяг шинэчлэх',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
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
      );
      },
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
            height: MediaQuery.of(modalContext).size.height * 0.55,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.deepGreen.withOpacity(0.3)
                    : AppColors.deepGreen.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: modalContext.borderColor,
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
                            color: modalContext.textPrimaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: modalContext.textPrimaryColor,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
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
                          _buildPasswordFieldForModal(
                            controller: _currentPasswordController,
                            label: 'Хуучин нууц үг',
                            obscureText: _obscureCurrentPassword,
                            onToggle: () {
                              setModalState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
                              });
                            },
                            context: context,
                          ),
                          SizedBox(height: 8.h),
                          _buildPasswordFieldForModal(
                            controller: _newPasswordController,
                            label: 'Шинэ нууц үг',
                            obscureText: _obscureNewPassword,
                            onToggle: () {
                              setModalState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            context: context,
                          ),
                          SizedBox(height: 16.h),
                          _buildPasswordFieldForModal(
                            controller: _confirmPasswordController,
                            label: 'Шинэ нууц үг давтах',
                            obscureText: _obscureConfirmPassword,
                            onToggle: () {
                              setModalState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            context: context,
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
                                        Navigator.pop(modalContext);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepGreen,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isChangingPassword
                                  ? SizedBox(
                                      height: 16.h,
                                      width: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Хадгалах',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
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
          );
        },
      ),
    );
  }

  Widget _buildPasswordFieldForModal({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required BuildContext context,
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
          fontSize: 11.sp,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.deepGreen, size: 18.sp),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : AppColors.lightTextSecondary,
            size: 18.sp,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8F8F8),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : AppColors.deepGreen.withOpacity(0.3),
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
        if (label == 'Шинэ нууц үг давтах' &&
            value != _newPasswordController.text) {
          return 'Нууц код хоорондоо таарахгүй байна';
        }
        return null;
      },
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
        fillColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8F8F8),
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
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.deepGreen, size: 18.sp),
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

    // Машины дугаар
    final plateNumber = _userData!['mashiniiDugaar'] ?? _userData!['dugaar'];
    if (plateNumber != null && plateNumber.toString().isNotEmpty) {
      dataItems.add({
        'icon': Icons.directions_car_filled_outlined,
        'label': 'Машины дугаар',
        'value': plateNumber.toString(),
      });
    }

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
      'value': (bairText != null && bairText.isNotEmpty) ? bairText : 'Хаяг сонгох',
      'action': (bairText == null || bairText.isEmpty) ? () { _handleUpdateAddress(); } : null,
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
                          color: isLink ? AppColors.deepGreen : (isDark ? Colors.white : Colors.black87),
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
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey[600],
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
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.deepGreen.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
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
                                      label: 'Нууц үг солих',
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
                                      
                                      // Миний машин Section - only show if user has baiguullagiinId or barilgiinId
                                      if (_baiguullagiinId != null && _baiguullagiinId!.isNotEmpty ||
                                          _barilgiinId != null && _barilgiinId!.isNotEmpty)
                                        _buildSection(
                                        title: 'Миний машин',
                                        icon: Icons.directions_car_filled_outlined,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: context.isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F8F8),
                                              borderRadius: BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: context.isDarkMode ? Colors.white.withOpacity(0.1) : AppColors.deepGreen.withOpacity(0.1),
                                              ),
                                            ),
                                            padding: EdgeInsets.all(16.w),
                                            child: Column(
                                              children: [
                                                _buildTextField(
                                                  controller: _mashiniiDugaarController,
                                                  label: 'Машины дугаар',
                                                  icon: Icons.numbers_rounded,
                                                  enabled: _isPlateEditMode && _isPlateChangeAllowed(),
                                                ),
                                                if (!_isPlateChangeAllowed())
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 12.h),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.info_outline, size: 14.sp, color: Colors.blue[400]),
                                                        SizedBox(width: 6.w),
                                                        Text(
                                                          'Сард нэг удаа солих боломжтой',
                                                          style: TextStyle(
                                                            color: Colors.blue[400],
                                                            fontSize: 11.sp,
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                SizedBox(height: 20.h),
                                                if (!_isPlateEditMode)
                                                  _buildActionButton(
                                                    context,
                                                    icon: Icons.edit_outlined,
                                                    label: 'Дугаар засах',
                                                    onTap: () {
                                                      if (_isPlateChangeAllowed()) {
                                                        setState(() {
                                                          _isPlateEditMode = true;
                                                        });
                                                      } else {
                                                        showGlassSnackBar(
                                                          context,
                                                          message: 'Сард 1 удаа солих боломжтой',
                                                          icon: Icons.lock_clock_outlined,
                                                          iconColor: Colors.orange,
                                                        );
                                                      }
                                                    },
                                                    isActive: _isPlateChangeAllowed(),
                                                  )
                                                else
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _isPlateEditMode = false;
                                                              // Restore original value
                                                              final plateNumber = _userData?['mashiniiDugaar'] ?? _userData?['dugaar'];
                                                              if (plateNumber != null) {
                                                                _mashiniiDugaarController.text = plateNumber.toString();
                                                              }
                                                            });
                                                          },
                                                          style: OutlinedButton.styleFrom(
                                                            padding: EdgeInsets.symmetric(vertical: 14.h),
                                                            side: BorderSide(color: AppColors.deepGreen),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                                          ),
                                                          child: Text('Цуцлах', style: TextStyle(color: AppColors.deepGreen)),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12.w),
                                                      Expanded(
                                                        flex: 2,
                                                        child: GestureDetector(
                                                          onTap: _isUpdatingPlate 
                                                            ? null 
                                                            : _handleUpdatePlateNumber,
                                                          child: AnimatedContainer(
                                                            duration: const Duration(milliseconds: 200),
                                                            padding: EdgeInsets.symmetric(vertical: 14.h),
                                                            decoration: BoxDecoration(
                                                              gradient: _isUpdatingPlate
                                                                ? null
                                                                : LinearGradient(
                                                                    colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                                                                    begin: Alignment.topLeft,
                                                                    end: Alignment.bottomRight,
                                                                  ),
                                                              color: _isUpdatingPlate ? Colors.grey.withOpacity(0.3) : null,
                                                              borderRadius: BorderRadius.circular(12.r),
                                                              boxShadow: _isUpdatingPlate
                                                                ? []
                                                                : [
                                                                    BoxShadow(
                                                                      color: AppColors.deepGreen.withOpacity(0.3),
                                                                      blurRadius: 8,
                                                                      offset: const Offset(0, 4),
                                                                    ),
                                                                  ],
                                                            ),
                                                            child: Center(
                                                              child: _isUpdatingPlate 
                                                                ? SizedBox(
                                                                    width: 18.w, 
                                                                    height: 18.w, 
                                                                    child: const CircularProgressIndicator(
                                                                      strokeWidth: 2, 
                                                                      color: Colors.white
                                                                    )
                                                                  )
                                                                : Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.save_outlined, size: 18.sp, color: Colors.white),
                                                                      SizedBox(width: 8.w),
                                                                      Text(
                                                                        'Хадгалах',
                                                                        style: TextStyle(
                                                                          color: Colors.white,
                                                                          fontSize: 14.sp,
                                                                          fontWeight: FontWeight.bold,
                                                                          letterSpacing: 0.2,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                                                        fontSize: 13.sp,
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
                                                        fontSize: 11.sp,
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
                                                  width: 48.w,
                                                  height: 28.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14.r,
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
                                                            ? 24.w
                                                            : 4.w,
                                                        top: 4.h,
                                                        child: Container(
                                                          width: 20.w,
                                                          height: 20.w,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors
                                                                .white,
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
                                                            size: 12.sp,
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
                                      _buildBiometricSectionHeader(
                                        'Биометрийн баталгаажуулалт',
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
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    Theme.of(context).platform == TargetPlatform.iOS
                                                        ? 'Face ID ашиглан нэвтрэх'
                                                        : 'Хурууны хээ ашиглан нэвтрэх',
                                                    style: TextStyle(
                                                      color: context
                                                          .textSecondaryColor,
                                                      fontSize: 11.sp,
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
                                                width: 48.w,
                                                height: 28.h,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        14.r,
                                                      ),
                                                  color: _biometricEnabled
                                                      ? AppColors.deepGreen
                                                      : Colors.grey
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
                                                          ? 24.w
                                                          : 4.w,
                                                      top: 4.h,
                                                      child: Container(
                                                        width: 20.w,
                                                        height: 20.w,
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

                                    // App Icon Selection Section (iOS only)
                                    if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                                      _buildSubSectionHeader(
                                        'Апп дүрс',
                                        Icons.palette_outlined,
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildSectionCard(
                                        GestureDetector(
                                          onTap: () => showAppIconSelectionSheet(context),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10.w),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(10.r),
                                                ),
                                                child: Icon(
                                                  Icons.home_rounded,
                                                  color: Colors.white,
                                                  size: 18.sp,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Апп дүрс солих',
                                                      style: TextStyle(
                                                        color: context.textPrimaryColor,
                                                        fontSize: 13.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      'Өөрт тохирох өнгө сонгох',
                                                      style: TextStyle(
                                                        color: context.textSecondaryColor,
                                                        fontSize: 11.sp,
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
                                              color: context.textSecondaryColor,
                                              fontSize: 11.sp,
                                              height: 1.5,
                                            ),
                                          ),
                                          SizedBox(height: 12.h),
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
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      'Бүртгэл устгах',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: context.surfaceColor,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                              title: Text('Гарах', style: TextStyle(color: context.textPrimaryColor)),
                                              content: Text('Та системээс гарахдаа итгэлтэй байна уу?', style: TextStyle(color: context.textSecondaryColor)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text('Үгүй', style: TextStyle(color: context.textSecondaryColor)),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Тийм', style: TextStyle(color: Colors.redAccent)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true && mounted) {
                                            await SessionService.logout();
                                            if (mounted) {
                                              context.go('/newtrekh');
                                            }
                                          }
                                        },
                                        icon: Icon(Icons.logout_rounded, size: 20.sp),
                                        label: Text(
                                          'Системээс гарах',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 14.h),
                                          foregroundColor: Colors.redAccent,
                                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                        ),
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
