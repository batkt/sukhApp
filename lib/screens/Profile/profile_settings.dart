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
import 'package:sukh_app/utils/format_util.dart';
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

  /// Бүртгэлтэй машины дугаарууд.
  ///
  /// Өмнө нь зөвхөн `_mashiniiDugaarController` (нэг дугаар) байсан тул
  /// оршин суугч 2-3 машин бүртгэсэн ч аппад нэг нь харагддаг, шинээр
  /// нэмэх слот ч гарч ирдэггүй байв.
  List<String> _mashinuud = [];

  /// Нэг оршин суугч дээр бүртгэж болох машины дээд тоо.
  /// Вебийн «Нэмэлт тохиргоо → Машины бүртгэлийн хязгаар»-аас тохируулна.
  int _mashiniiKhyazgaar = 1;

  /// Шинэ машин нэмэх сул слот байгаа эсэх.
  bool get _sulSlotBaina => _mashinuud.length < _mashiniiKhyazgaar;

  // Biometric settings
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Chatbot assistant
  bool _chatbotEnabled = true;

  // Address
  String? _currentAddress;
  bool _isLoadingAddress = false;
  int? _billingDay; // Day of month when billing/cycle resets

  // Organization membership
  String? _baiguullagiinId;
  String? _barilgiinId;

  // Гэр бүлийн гишүүн эсэх (тийм бол данс нь үндсэн эзэмшигчийнх)
  bool _gishuunEsekh = false;

  /// Байрын удирдлага гэр бүлийн гишүүн урихыг зөвшөөрсөн эсэх.
  ///
  /// Вебийн «Нэмэлт тохиргоо → Гэр бүлийн гишүүн урих» чекээс тохируулагдаж,
  /// профайлын хариунд `gerBuliinGishuunEsekh` талбараар ирнэ. Тохируулаагүй
  /// (хуучин сервер) бол зөвшөөрсөн гэж үзнэ.
  bool _gerBuliinGishuunZovshoorson = true;
  String? _undsenEzemshigchNer;

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
    _checkChatbotStatus();
    _loadCurrentAddress();
    _gerBuliinTuluvAchaalya();

    // Check for navigation actions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      if (state.uri.queryParameters['action'] == 'edit_email') {
        context.push('/personal_info');
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

  Future<void> _checkChatbotStatus() async {
    final isEnabled = await StorageService.isChatbotEnabled();
    if (mounted) {
      setState(() {
        _chatbotEnabled = isEnabled;
      });
    }
  }

  Future<void> _handleChatbotToggle(bool value) async {
    setState(() {
      _chatbotEnabled = value;
    });
    await StorageService.setChatbotEnabled(value);
    if (mounted) {
      showGlassSnackBar(
        context,
        message: value
            ? 'Туслах чатбот идэвхэжлээ'
            : 'Туслах чатбот идэвхгүй боллоо',
        icon: value ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
      );
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

  /// Серверийн хариунаас машины ЖАГСААЛТ + хязгаарыг уншина.
  ///
  /// Backend нь `/tokenoorOrshinSuugchAvya` болон `/zochinSettings`
  /// хоёулангаас `mashinuud` (бүх дугаар) ба `mashiniiKhyazgaar`-ыг
  /// буцаадаг. Хуучин серверийн хариу дээр `mashinuud` байхгүй байж болох
  /// тул нэг дугаарын талбаруудаас нөхнө.
  void _mashinuudUnshiya(dynamic source) {
    if (source is! Map) return;

    final jagsaalt = <String>[];
    final raw = source['mashinuud'];

    if (raw is List) {
      for (final item in raw) {
        final dugaar = _parsePlateFromAny(item);
        if (dugaar != null && !jagsaalt.contains(dugaar)) {
          jagsaalt.add(dugaar);
        }
      }
    }

    if (jagsaalt.isEmpty) {
      final neg = _parsePlateFromAny(source);
      if (neg != null) jagsaalt.add(neg);
    }

    if (jagsaalt.isNotEmpty) {
      _mashinuud = jagsaalt;
    }

    final khyazgaar =
        source['mashiniiKhyazgaar'] ?? source['orshinSuugchMashiniiLimit'];
    final toon = int.tryParse(khyazgaar?.toString() ?? '');
    if (toon != null && toon > 0) {
      _mashiniiKhyazgaar = toon;
    }
  }

  String? _parsePlateFromAny(dynamic source) {
    if (source == null) return null;
    if (source is String) {
      final s = source.trim().toUpperCase();
      return (s.isEmpty ||
              s == 'БҮРТГЭЛГҮЙ' ||
              s == 'NULL' ||
              s == 'UNDEFINED' ||
              s == '-')
          ? null
          : s;
    }
    if (source is List) {
      for (final item in source) {
        final p = _parsePlateFromAny(item);
        if (p != null) return p;
      }
      return null;
    }
    if (source is Map) {
      // Direct field candidates
      final directCandidates = [
        source['mashiniiDugaar'],
        source['dugaar'],
        source['mashinDugaar'],
        source['carNumber'],
        source['plateNumber'],
        source['urisanMashiniiDugaar'],
      ];
      for (final c in directCandidates) {
        final p = _parsePlateFromAny(c);
        if (p != null) return p;
      }

      // Nested object candidates
      final nestedCandidates = [
        source['mashinuud'],
        source['orshinSuugchMashin'],
        source['mashin'],
        source['data'],
        source['result'],
      ];
      for (final n in nestedCandidates) {
        final p = _parsePlateFromAny(n);
        if (p != null) return p;
      }
    }
    return null;
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getUserProfile();

      if (response['success'] == true && response['result'] != null) {
        final userData = response['result'];

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

        // Extract initial plate from userData using multi-field fallback
        final initialPlate = _parsePlateFromAny(userData);
        if (initialPlate != null) {
          _mashiniiDugaarController.text = initialPlate;
        } else {
          _mashiniiDugaarController.text = '';
        }

        _mashinuud = [];
        _mashinuudUnshiya(userData);

        final gishuuniiTokhirgoo = userData['gerBuliinGishuunEsekh'];
        _gerBuliinGishuunZovshoorson = gishuuniiTokhirgoo == null
            ? true
            : gishuuniiTokhirgoo != false;

        // Fetch prioritized car plate from zochinSettings
        try {
          final settingsRes = await ApiService.fetchZochinSettings();
          if (settingsRes != null) {
            final sData =
                settingsRes['data'] ?? settingsRes['result'] ?? settingsRes;
            final settingsPlate = _parsePlateFromAny(sData);
            if (settingsPlate != null && settingsPlate.isNotEmpty) {
              _mashiniiDugaarController.text = settingsPlate;
              if (_userData != null) {
                _userData!['mashiniiDugaar'] = settingsPlate;
                _userData!['dugaar'] = settingsPlate;
              }
            }

            // `/zochinSettings` нь машины жагсаалт, хязгаарыг хамгийн
            // шинэлэг байдлаар буцаадаг тул профайлын дээрх утгыг дарна.
            _mashinuudUnshiya(sData);

            final orshinSuugchMashin =
                sData is Map ? sData['orshinSuugchMashin'] : null;
            final mashin = sData is Map ? (sData['mashin'] ?? sData) : null;
            final updateDate = (orshinSuugchMashin != null &&
                    orshinSuugchMashin is Map)
                ? orshinSuugchMashin['dugaarUurchilsunOgnoo']
                : (mashin != null && mashin is Map
                        ? mashin['dugaarUurchilsunOgnoo']
                        : null) ??
                    (sData is Map ? sData['dugaarUurchilsunOgnoo'] : null);

            if (updateDate != null && _userData != null) {
              _userData!['dugaarUurchilsunOgnoo'] = updateDate;
            }
          }
        } catch (e) {
          debugPrint('Error fetching zochin settings: $e');
        }

        // Fetch billing day from cron data if available
        final barilgiinId = userData['barilgiinId']?.toString();
        if (barilgiinId != null && barilgiinId.isNotEmpty) {
          _fetchBillingCronInfo(barilgiinId);
        }

        setState(() {
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

  Future<void> _handleRemoveToot(Map<String, dynamic> tootData) async {
    final residentId = _userData?['_id'];
    final baiguullagiinId = tootData['baiguullagiinId'];
    final barilgiinId = tootData['barilgiinId'];
    final toot = tootData['toot'];

    if (residentId == null || baiguullagiinId == null || toot == null) {
      showGlassSnackBar(
        context,
        message: 'Мэдээлэл дутуу байна',
        icon: Icons.error,
      );
      return;
    }

    final isDark = context.isDarkMode;

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Бүртгэл цуцлах',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$toot тоот бүртгэлийг цуцлахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Үгүй',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Тийм, цуцлах',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.removeToot(
        residentId: residentId.toString(),
        baiguullagiinId: baiguullagiinId.toString(),
        barilgiinId: barilgiinId?.toString(),
        toot: toot.toString(),
      );

      showGlassSnackBar(
        context,
        message: 'Бүртгэл амжилттай цуцлагдлаа',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      await _loadUserProfile();
    } catch (e) {
      showGlassSnackBar(
        context,
        message: 'Алдаа гарлаа: $e',
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  int _getPlateChangeRemainingDays() {
    if (_userData == null) return 0;

    // If plate is empty/null or "БҮРТГЭЛГҮЙ", allow change regardless of date (remaining days = 0)
    final plateNumber = _userData!['mashiniiDugaar'] ?? _userData!['dugaar'];
    if (plateNumber == null ||
        plateNumber.toString().isEmpty ||
        plateNumber.toString().toUpperCase() == 'БҮРТГЭЛГҮЙ') {
      return 0;
    }

    final lastUpdate = _userData!['dugaarUurchilsunOgnoo'];
    if (lastUpdate == null) return 0;

    try {
      final lastDate = DateTime.parse(lastUpdate.toString());
      final now = DateTime.now();

      // Strict 30-day difference check
      final difference = now.difference(lastDate);
      final daysPassed = difference.inDays;
      final remaining = 30 - daysPassed;

      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  bool _isPlateChangeAllowed() {
    return _getPlateChangeRemainingDays() <= 0;
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

    // Сул слот байгаа бол энэ нь дугаар СОЛИХ биш, ШИНЭ машин НЭМЭХ үйлдэл —
    // 30 хоногийн хязгаарлалт хамаарахгүй (backend ч ижил дүрмээр шалгадаг).
    final remainingDays = _getPlateChangeRemainingDays();
    if (!_sulSlotBaina && remainingDays > 0) {
      showGlassSnackBar(
        context,
        message: 'Машины дугаарыг 30 хоногт 1 удаа өөрчлөх боломжтой. Дахин өөрчлөхөд $remainingDays хоног үлдсэн байна.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    if (_mashinuud.length >= _mashiniiKhyazgaar && _mashiniiKhyazgaar > 1) {
      showGlassSnackBar(
        context,
        message:
            'Та хамгийн олон $_mashiniiKhyazgaar машин бүртгэх боломжтой. Хязгаар дүүрсэн байна.',
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
    // Олон машин зөвшөөрөгдсөн бөгөөд сул слот байвал оролт нь ШИНЭ дугаар
    // нэмэхэд зориулагдана — байгаа дугаараар нь бөглөвөл хэрэглэгч засаж
    // байна гэж андуурч, хуучин машиныг дарж нэрлэнэ.
    if (_mashiniiKhyazgaar > 1 && _sulSlotBaina) {
      _mashiniiDugaarController.text = '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = context.isDarkMode;

          /// Шинэ машин НЭМЭХ горим (хязгаар 2+ бөгөөд сул слот байна).
          final nemekhEsekh = _mashiniiKhyazgaar > 1 && _sulSlotBaina;

          /// Хязгаар дүүрсэн — шинээр нэмэх боломжгүй.
          final duurenEsekh = _mashiniiKhyazgaar > 1 && !_sulSlotBaina;

          // Шинэ машин нэмэхэд «30 хоногт 1 удаа солино» хамаарахгүй.
          final isAllowed =
              duurenEsekh ? false : (nemekhEsekh || _isPlateChangeAllowed());
          final remainingDays = _getPlateChangeRemainingDays();

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
                          _mashiniiKhyazgaar > 1
                              ? 'Миний машин (${_mashinuud.length}/$_mashiniiKhyazgaar)'
                              : 'Миний машин',
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
                      // Бүртгэлтэй бүх машин. Хязгаар 1 үед хуучин дэлгэц
                      // хэвээр — жагсаалт нь зөвхөн олон машинтай үед л
                      // нэмэлт мэдээлэл болно.
                      if (_mashiniiKhyazgaar > 1 && _mashinuud.isNotEmpty) ...[
                        Text(
                          'Бүртгэлтэй машин',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ..._mashinuud.map(
                          (dugaar) => Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car_filled_rounded,
                                  color: AppColors.deepGreen,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    dugaar,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                      Text(
                        nemekhEsekh ? 'Шинэ машины улсын дугаар' : 'Улсын дугаар',
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
                                  duurenEsekh
                                      ? 'Та хамгийн олон $_mashiniiKhyazgaar машин бүртгэсэн байна. Шинээр нэмэхийн тулд байрын удирдлагад хандана уу.'
                                      : 'Машины дугаарыг 30 хоногт 1 удаа өөрчлөх боломжтой. Дахин өөрчлөхөд $remainingDays хоног үлдсэн байна.',
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
                                  nemekhEsekh ? 'Нэмэх' : 'Хадгалах',
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
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        final isKeyboardOpen = bottomInset > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: isKeyboardOpen ? screenHeight * 0.9 : screenHeight * 0.7,
          padding: EdgeInsets.only(bottom: bottomInset),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Address Info (moved to top per user request)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          ],
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Section 2: Basic Info
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSubSectionTitle('Үндсэн мэдээлэл'),
                            SizedBox(height: 12.h),
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
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
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
                                      _loadUserProfile();
                                    }
                                  } catch (e) {
                                    showGlassSnackBar(
                                      context,
                                      message: 'Алдаа гарлаа: $e',
                                      icon: Icons.error,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.deepGreen,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Хадгалах',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

    // Build list of data items
    List<Map<String, dynamic>> dataItems = [];

    // Check for multiple toots (units)
    final List toots =
        (_userData!['toots'] != null && _userData!['toots'] is List)
            ? List.from(_userData!['toots'])
            : [];

    if (toots.isNotEmpty) {
      // Group toots by building to avoid repeating building name if multiple toots in same building
      // Or just list them all as separate unit entries
      for (var t in toots) {
        final bName = t['bairniiNer'] ?? t['baiguullagiinNer'] ?? 'Тодорхойгүй';
        final tNo = t['toot'] ?? '???';

        dataItems.add({
          'icon': Icons.home_rounded,
          'label': '$bName',
          'value': '$tNo тоот',
          'action': toots.length > 1
              ? () {
                  _handleRemoveToot(Map<String, dynamic>.from(t));
                }
              : null,
          'isRemovable': toots.length > 1,
        });
      }
    } else {
      // Fallback to top-level fields if toots array is empty
      String? bairText;
      if (_userData!['bairniiNer'] != null &&
          _userData!['bairniiNer'].toString().isNotEmpty) {
        bairText = _userData!['bairniiNer'].toString();
      }

      final hasAddress = bairText != null && bairText.isNotEmpty;
      dataItems.add({
        'icon': Icons.location_on_outlined,
        'label': 'Байр',
        'value': hasAddress ? bairText! : 'Хаяг сонгох',
        'action': !hasAddress
            ? () {
                _handleUpdateAddress();
              }
            : null,
        'isLink': !hasAddress,
      });

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
    }

    if (dataItems.isEmpty) {
      return Text(
        'Мэдээлэл олдсонгүй',
        style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
      );
    }

    final isDark = context.isDarkMode;

    return Column(
      children: dataItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == dataItems.length - 1;
        final action = item['action'] as VoidCallback?;
        final isLink = item['isLink'] == true;
        final isRemovable = item['isRemovable'] == true;

        return Container(
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
                  color: isRemovable
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.deepGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: isRemovable ? Colors.red[400] : AppColors.deepGreen,
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
              if (isRemovable)
                IconButton(
                  onPressed: action,
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red[400],
                    size: 20.sp,
                  ),
                  tooltip: 'Цуцлах',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.r,
                ),
            ],
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
    String rawName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Хэрэглэгч';
    String initialSource = rawName;

    // Try to get both initials from userData if possible
    if (_userData != null) {
      final ovog = _userData!['ovog']?.toString() ?? '';
      final ner = _userData!['ner']?.toString() ?? '';
      if (ovog.isNotEmpty && ner.isNotEmpty) {
        initialSource = '$ovog $ner';
      }
    }

    final initials = _getInitials(initialSource);
    final displayName = formatDisplayName(rawName);

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

  /// Гэр бүлийн гишүүний төлөвийг локал хадгалснаас уншина.
  /// Нэвтрэх үед сервер эдгээрийг хариунд нь оруулж ирдэг.
  Future<void> _gerBuliinTuluvAchaalya() async {
    final gishuunEsekh = await StorageService.isGishuun();
    final ner = gishuunEsekh
        ? await StorageService.getUndsenEzemshigchNer()
        : null;

    if (!mounted) return;
    setState(() {
      _gishuunEsekh = gishuunEsekh;
      _undsenEzemshigchNer = ner;
    });
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
                                  subtitle: 'Утас, хаягийн мэдээлэл',
                                  onTap: () async {
                                    await context.push('/personal_info');
                                    _loadUserProfile();
                                    _loadCurrentAddress();
                                  },
                                ),
                                _buildSettingsTile(
                                  icon: Icons.directions_car_filled_outlined,
                                  title: _mashiniiKhyazgaar > 1
                                      ? 'Миний машин (${_mashinuud.length}/$_mashiniiKhyazgaar)'
                                      : 'Миний машин',
                                  subtitle: _mashinuud.isNotEmpty
                                      ? _mashinuud.join(', ')
                                      : (_mashiniiDugaarController
                                                .text
                                                .isNotEmpty
                                            ? _mashiniiDugaarController.text
                                            : 'Дугаар тохируулах'),
                                  onTap: () {
                                    _showCarPlateModal(context);
                                  },
                                ),
                                // Байрын удирдлага урихыг хаасан бол мөрийг
                                // харуулахгүй. Гэхдээ хэрэглэгч ӨӨРӨӨ гишүүн
                                // бол хэвээр харагдана — тэр нь өөрийн
                                // гишүүнчлэлийн мэдээллийг харах хэсэг.
                                if (_gerBuliinGishuunZovshoorson ||
                                    _gishuunEsekh)
                                  _buildSettingsTile(
                                    icon: Icons.family_restroom_rounded,
                                    title: 'Гэр бүлийн гишүүн',
                                    subtitle: _gishuunEsekh
                                        ? (_undsenEzemshigchNer != null &&
                                                  _undsenEzemshigchNer!
                                                      .isNotEmpty
                                              ? '$_undsenEzemshigchNer-ийн байр'
                                              : 'Гишүүнчлэлийн мэдээлэл')
                                        : 'Гэр бүлийнхээ гишүүдийг нэмэх',
                                    showBorder: false,
                                    onTap: () async {
                                      await context.push('/ger-bul');
                                      _gerBuliinTuluvAchaalya();
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
                                  subtitle: 'Нэвтрэх 4 оронтой код солих',
                                  showBorder: true,
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
                                    showBorder: true,
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
                                _buildSettingsTile(
                                  icon: Icons.support_agent_rounded,
                                  title: 'Туслах чатбот',
                                  subtitle: _chatbotEnabled
                                      ? 'Нүүр хуудсанд харагдаж байна'
                                      : 'Нүүр хуудсанд нуугдсан',
                                  showBorder: false,
                                  trailing: Switch(
                                    value: _chatbotEnabled,
                                    onChanged: (val) =>
                                        _handleChatbotToggle(val),
                                    activeColor: AppColors.deepGreen,
                                  ),
                                  onTap: () => _handleChatbotToggle(
                                    !_chatbotEnabled,
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
  static const Map<String, String> _latinToCyrillic = {
    'A': 'А',
    'B': 'Б',
    'C': 'С',
    'D': 'Д',
    'E': 'Е',
    'F': 'Ф',
    'G': 'Г',
    'H': 'Н',
    'I': 'И',
    'J': 'Ж',
    'K': 'К',
    'L': 'Л',
    'M': 'М',
    'N': 'Н',
    'O': 'О',
    'P': 'Р',
    'Q': 'Ө',
    'R': 'Р',
    'S': 'С',
    'T': 'Т',
    'U': 'У',
    'V': 'В',
    'W': 'В',
    'X': 'Х',
    'Y': 'Ү',
    'Z': 'З',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    String result = '';

    for (int i = 0; i < text.length && i < 7; i++) {
      String char = text[i];
      if (i < 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          result += char;
        }
      } else {
        // Last 3 characters: map Latin equivalent to Mongolian Cyrillic if typed on English keyboard
        if (_latinToCyrillic.containsKey(char)) {
          char = _latinToCyrillic[char]!;
        }
        // Must be Mongolian Cyrillic letter (А-Я, Ө, Ү, Ё)
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
