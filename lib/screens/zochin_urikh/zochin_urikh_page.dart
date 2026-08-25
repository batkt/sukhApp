import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';

import 'package:intl/intl.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/utils/logger.dart';

class ZochinUrikhPage extends StatefulWidget {
  const ZochinUrikhPage({super.key});

  @override
  State<ZochinUrikhPage> createState() => _ZochinUrikhPageState();
}

class _ZochinUrikhPageState extends State<ZochinUrikhPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mashiniiDugaarController = TextEditingController();
  final _ezemshigchiinUtasController = TextEditingController();
  final FocusNode _plateFocusNode = FocusNode();
  TextInputType _plateKeyboardType = TextInputType.number;
  
  bool _isLoading = false;
  
  // Lists for different statuses
  List<Map<String, dynamic>> _pendingGuests = [];
  List<Map<String, dynamic>> _activeGuests = [];
  List<Map<String, dynamic>> _exitedGuests = [];
  
  late TabController _tabController;
  bool _isLoadingHistory = true;
  String? _userPhoneNumber;
  Map<String, dynamic>? _quotaStatus;
  bool _isLoadingQuota = true;
  String? _quotaError;
  bool _hasQuota = true;

  /// Байгууллага "Нэхэмжлэх дээр нэмэх"-ийг зөвшөөрсөн эсэх.
  /// Унтраалттай бол зочин өөрөө төлнө - сонголт харуулахгүй.
  bool get _nekhemjlekhBolomjtoi =>
      _quotaStatus?['nekhemjlekhEsekh'] == true;

  /// Түрээсийн зогсоолын төлбөрийг хэн даах: "zochin" | "ezen".
  /// Гэрээгүй бол сервер өөрөө "zochin" болгож буулгана.
  String _tulburiinTurul = 'zochin';

  /// Машины дугаар -> түрээсийн зогсоолын сүүлийн хөдөлгөөн.
  /// /zochin/zogsool/tuukh-аас ачаална - үнэгүй минут, орсон/гарсан цаг.
  final Map<String, Map<String, dynamic>> _zogsooliinTuukh = {};

  /// Дэлгэрэнгүй нээгдсэн урилгын id (зөвхөн нэг нь нээлттэй байна)
  String? _delgerengiiUrilgiinId;

  /// Урилгын id -> түрээсээс шууд асуусан одоогийн байдал
  final Map<String, Map<String, dynamic>> _urilgiinTuluv = {};

  /// Яг одоо татагдаж буй урилгууд
  final Set<String> _tuluvAchaalj = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mashiniiDugaarController.addListener(_onPlateTextChanged);
    _loadUserPhone();
    _loadTulburiinTurul();
    _loadInvitedGuests();
    _loadQuotaStatus();
    _loadZogsooliinTuukh();
    _setupSocketListener();
  }

  void _onPlateTextChanged() {
    final text = _mashiniiDugaarController.text;
    final targetType = text.length < 4 ? TextInputType.number : TextInputType.text;
    if (_plateKeyboardType != targetType) {
      setState(() {
        _plateKeyboardType = targetType;
      });
      if (_plateFocusNode.hasFocus) {
        _plateFocusNode.unfocus();
        Future.microtask(() {
          if (mounted) _plateFocusNode.requestFocus();
        });
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  void _setupSocketListener() {
    SocketService.instance.setNotificationCallback(_handleSocketMessage);
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    // Reload list on any relevant notification
    // Optimize this later if we know specific event types for car updates
    AppLogger.log('🔔 Socket message received in ZochinUrikhPage, reloading list...');

    // Түрээсийн зогсоолын webhook -> ZOCHIN_ORSON / ZOCHIN_GARSAN
    final turul = data['type']?.toString();
    if (turul == 'ZOCHIN_ORSON' || turul == 'ZOCHIN_GARSAN') {
      _loadZogsooliinTuukh();

      // Нээлттэй дэлгэрэнгүй хуучирсан тул хүчингүй болгоод дахин татна
      final neelttei = _delgerengiiUrilgiinId;
      _urilgiinTuluv.clear();
      if (neelttei != null) _loadUrilgiinTuluv(neelttei);

      if (mounted) {
        final medegdel = data['message']?.toString();
        if (medegdel != null && medegdel.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(medegdel),
              backgroundColor: turul == 'ZOCHIN_ORSON'
                  ? const Color(0xFF3B82F6)
                  : AppColors.deepGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }

    _loadInvitedGuests(showLoading: false);
    _loadQuotaStatus();
  }

  /// Сүүлд сонгосон төлбөрийн төрлийг сэргээнэ. Хадгалаагүй бол "zochin".
  Future<void> _loadTulburiinTurul() async {
    final khadgalsan = await StorageService.getZochinTulburiinTurul();
    if (khadgalsan != null && mounted && khadgalsan != _tulburiinTurul) {
      setState(() => _tulburiinTurul = khadgalsan);
    }
  }

  /// Урилгын түрээсийн зогсоол дээрх одоогийн байдлыг татах. Түрээс рүү
  /// шууд дамждаг тул удаан байж болно - зөвхөн дэлгэрэнгүй нээхэд дуудна.
  Future<void> _loadUrilgiinTuluv(String urilgiinId) async {
    if (_tuluvAchaalj.contains(urilgiinId)) return;

    setState(() => _tuluvAchaalj.add(urilgiinId));
    try {
      final khariu = await ApiService.fetchZochinUrilgiinTuluv(urilgiinId);
      final data = (khariu != null && khariu['data'] is Map)
          ? Map<String, dynamic>.from(khariu['data'] as Map)
          : null;

      if (mounted) {
        setState(() {
          _tuluvAchaalj.remove(urilgiinId);
          if (data != null) {
            _urilgiinTuluv[urilgiinId] = data;
          } else {
            _urilgiinTuluv.remove(urilgiinId);
          }
        });
      }
    } catch (e) {
      AppLogger.log('[ZOCHIN-ZOGSOOL] Урилгын төлөв татахад алдаа: $e');
      if (mounted) {
        setState(() => _tuluvAchaalj.remove(urilgiinId));
      }
    }
  }

  /// Дэлгэрэнгүйг нээх/хаах. Нээх бүрт шинэчилж татна - үнэгүй минут
  /// байнга өөрчлөгддөг тул хуучин утга харуулах нь төөрөгдүүлнэ.
  void _urilgiinTuluvSolikh(String urilgiinId) {
    if (_delgerengiiUrilgiinId == urilgiinId) {
      setState(() => _delgerengiiUrilgiinId = null);
      return;
    }
    setState(() => _delgerengiiUrilgiinId = urilgiinId);
    _loadUrilgiinTuluv(urilgiinId);
  }

  /// Түрээсийн зогсоолын хөдөлгөөнийг татаж, машины дугаараар индекслэнэ.
  /// Интеграц асаагүй бол хоосон ирнэ - хуудас хэвийн ажиллана.
  Future<void> _loadZogsooliinTuukh() async {
    try {
      final khariu = await ApiService.fetchZochinZogsoolTuukh();
      final jagsaalt = khariu['jagsaalt'];
      if (jagsaalt is! List) return;

      final shine = <String, Map<String, dynamic>>{};
      // Сервер createdAt буурахаар эрэмбэлдэг тул эхний тохиолдол нь хамгийн сүүлийнх
      for (final mur in jagsaalt) {
        if (mur is! Map) continue;
        final dugaar = (mur['mashiniiDugaar'] ?? '').toString().trim().toUpperCase();
        if (dugaar.isEmpty || shine.containsKey(dugaar)) continue;
        shine[dugaar] = Map<String, dynamic>.from(mur);
      }

      if (mounted) {
        setState(() {
          _zogsooliinTuukh
            ..clear()
            ..addAll(shine);
        });
      }
    } catch (e) {
      AppLogger.log('[ZOCHIN-ZOGSOOL] Хөдөлгөөн ачаалахад алдаа: $e');
    }
  }

  Future<void> _loadQuotaStatus() async {
    try {
      if (mounted) setState(() {
        _isLoadingQuota = true;
        _quotaError = null;
      });
      
      final status = await ApiService.fetchZochinQuotaStatus();
      
      if (mounted) {
        setState(() {
          // Handle various response formats (flat or wrapped in 'data'/'result')
          Map<String, dynamic> data;
          if (status['total'] != null) {
            data = status;
          } else if (status['data'] != null && status['data'] is Map) {
            data = Map<String, dynamic>.from(status['data']);
          } else if (status['result'] != null && status['result'] is Map) {
            data = Map<String, dynamic>.from(status['result']);
          } else {
            data = status;
          }
          
          // Map potential different key names for robustness 
          _quotaStatus = {
            'total': data['total'] ?? data['zochinErkhiinToo'] ?? 0,
            'used': data['used'] ?? data['ashiglasanToo'] ?? 0,
            'remaining': data['remaining'] ?? data['uldsenToo'] ?? 0,
            'period': data['period'] ?? 'saraar',
            'freeMinutesPerGuest': data['freeMinutesPerGuest'] ?? data['zochinTusBurUneguiMinut'] ?? 0,
            'hasRight': data['hasRight'] ?? data['zochinUrikhEsekh'] ?? true,
            // Тохируулаагүй бол УНТРААЛТТАЙ - сервер ч мөн адил шийддэг тул
            // энд true болговол "Би даана" харагдаад сервер дээр буцаагдана
            'nekhemjlekhEsekh': data['nekhemjlekhEsekh'] == true,
          };
          
          // Check success flag and primary permission flag
          final hasRight = _quotaStatus!['hasRight'] as bool;
          if (status['success'] == false || !hasRight) {
            _hasQuota = false;
          } else {
            // If they have the right:
            // they can invite if they have remaining count,
            // OR if it's unlimited (total == 0),
            // OR if every guest has free minutes (freeMinutes > 0)
            final remaining = _quotaStatus!['remaining'] as int;
            final total = _quotaStatus!['total'] as int;
            
            // Limit is allowed if unlimited (total == 0) OR if remaining quota is greater than 0
            _hasQuota = (total == 0) || (remaining > 0);
          }
          
          _isLoadingQuota = false;
        });
      }
    } catch (e) {
      AppLogger.log('❌ [QUOTA] Error loading quota status: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuota = false;
          _hasQuota = true; // Fallback to allow attempt if we can't check
          _quotaError = e.toString();
        });
      }
    }
  }

  Future<void> _loadUserPhone() async {
    final phone = await StorageService.getSavedPhoneNumber();
    if (mounted && phone != null) {
      setState(() {
        _userPhoneNumber = phone;
        _ezemshigchiinUtasController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    SocketService.instance.removeNotificationCallback(_handleSocketMessage);
    _mashiniiDugaarController.removeListener(_onPlateTextChanged);
    _plateFocusNode.dispose();
    _tabController.dispose();
    _mashiniiDugaarController.dispose();
    _ezemshigchiinUtasController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitedGuests({bool showLoading = true}) async {
    try {
      if (showLoading) setState(() => _isLoadingHistory = true);
      
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final userId = await StorageService.getUserId();
      
      if (baiguullagiinId != null && userId != null) {
        final response = await ApiService.fetchZochinTuukh(
          baiguullagiinId: baiguullagiinId,
          ezenId: userId,
        );
        
        if (mounted) {
          final ezenList = response['ezenList'] as List? ?? [];
          final jagsaalt = response['jagsaalt'] as List? ?? [];
          
          setState(() {
            // Access nested 'urisanMashin' for jagsaalt items safely
            final historyItems = List<Map<String, dynamic>>.from(jagsaalt);
            
            // "Идэвхтэй" (Active) - tuluv 1 or inside parking
            _activeGuests = historyItems.where((item) {
              final um = item['urisanMashin'];
              final umTuluv = um != null ? (um['tuluv'] ?? 0) : 0;
              final itemTuluv = item['tuluv'] ?? 0;
              return umTuluv == 1 || itemTuluv == 1;
            }).toList();

            // "Гарсан" (Exited) - tuluv 2 or exited parking
            _exitedGuests = historyItems.where((item) {
              final um = item['urisanMashin'];
              final umTuluv = um != null ? (um['tuluv'] ?? 0) : 0;
              final itemTuluv = item['tuluv'] ?? 0;
              return umTuluv == 2 || itemTuluv == 2;
            }).toList();

            // Extract set of plate numbers that are active or exited
            final activeOrExitedPlates = <String>{};
            for (final g in _activeGuests) {
              final p = (g['mashiniiDugaar'] ?? g['urisanMashin']?['urisanMashiniiDugaar'] ?? '').toString().trim().toUpperCase();
              if (p.isNotEmpty) activeOrExitedPlates.add(p);
            }
            for (final g in _exitedGuests) {
              final p = (g['mashiniiDugaar'] ?? g['urisanMashin']?['urisanMashiniiDugaar'] ?? '').toString().trim().toUpperCase();
              if (p.isNotEmpty) activeOrExitedPlates.add(p);
            }

            // "Хүлээлгэ" (Pending) - Items in ezenList with tuluv 0 AND not in active/exited history
            _pendingGuests = List<Map<String, dynamic>>.from(
              ezenList.where((item) {
                final tuluv = item['tuluv'] ?? 0;
                if (tuluv != 0) return false;
                final plate = (item['urisanMashiniiDugaar'] ?? item['mashiniiDugaar'] ?? '').toString().trim().toUpperCase();
                return !activeOrExitedPlates.contains(plate);
              })
            );

            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingHistory = false);
        }
      }
    } catch (e) {
      AppLogger.log('Error loading invited guests: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    final targetPlate = _mashiniiDugaarController.text.trim().toUpperCase();

    // Check duplicate pending invitation in local list
    final isAlreadyPending = _pendingGuests.any((guest) =>
        (guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? '')
            .toString()
            .trim()
            .toUpperCase() ==
        targetPlate);

    if (isAlreadyPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Энэ $targetPlate дугаартай машин аль хэдийн хүлээлгэнд байна'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Re-verify quota in real-time before sending request
      await _loadQuotaStatus();
      if (!_hasQuota) {
        throw Exception('Таны зочин урих лимит дууссан байна');
      }

      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();
      final userId = await StorageService.getUserId();
      
      if (baiguullagiinId == null || userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final khariu = await ApiService.inviteGuest(
        urisanMashiniiDugaar: targetPlate,
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        ezenId: userId,
        tulburiinTurul: _nekhemjlekhBolomjtoi ? _tulburiinTurul : 'zochin',
      );

      if (mounted) {
        // Clear only the car plate field (phone stays as user's phone)
        _mashiniiDugaarController.clear();

        // Түрээсийн зогсоолын үр дүнг тусад нь хэлнэ. Урилга АмарСүх дээр
        // үргэлж хадгалагдана - зогсоолд бүртгэгдээгүй бол хаалган дээр
        // зочин танигдахгүй тул оршин суугчид мэдэгдэх ёстой.
        final turees = khariu['turees'];
        String medegdel = 'Зочин амжилттай урилаа';
        Color ungu = AppColors.deepGreen;

        if (turees is Map) {
          final buurtgegdsen = turees['buurtgegdsen'] == true;
          final tokhirgoogui = turees['tokhirgoogui'] == true;

          if (buurtgegdsen) {
            // Гэрээ олдоогүй бол сервер "ezen"-ийг "zochin" болгож буулгадаг
            final tulukh = turees['tulburiinTurul']?.toString();
            if (_tulburiinTurul == 'ezen' && tulukh == 'zochin') {
              medegdel =
                  'Зочин уригдлаа.';
              ungu = Colors.green;
            } else if (tulukh == 'ezen') {
              medegdel =
                  'Зочин уригдлаа. Зогсоолын төлбөр таны нэхэмжлэхэд бичигдэнэ.';
            } else {
              medegdel = 'Зочин уригдлаа. Зогсоолд бүртгэгдлээ.';
            }
          } else if (!tokhirgoogui) {
            medegdel =
                'Зочин уригдлаа. Гэхдээ зогсоолын системд бүртгэгдсэнгүй - хаалган дээр танигдахгүй байж болзошгүй.';
            ungu = Colors.orange;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(medegdel),
            backgroundColor: ungu,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );

        // Reload history and quota
        _loadInvitedGuests();
        _loadQuotaStatus();
        _loadZogsooliinTuukh();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Clean up common technical prefixes
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        if (errorMessage.contains('Зочин хадгалахад алдаа гарлаа:')) {
          errorMessage = errorMessage.replaceFirst('Зочин хадгалахад алдаа гарлаа:', '').trim();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );

        // If it was a quota error (403), refresh to disable button
        if (e.toString().contains('403') || e.toString().contains('лимит')) {
          _loadQuotaStatus();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Зочин урих'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding(
            small: 16,
            medium: 20,
            large: 24,
            tablet: 28,
            veryNarrow: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quota status card
              if (_isLoadingQuota)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepGreen.withOpacity(0.5),
                    ),
                  ),
                )
              else if (_quotaError != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Квот ачаалж чадсангүй',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadQuotaStatus,
                        child: Text('Дахин оролдох'),
                      ),
                    ],
                  ),
                )
              else if (_quotaStatus != null && _quotaStatus!['hasRight'] == false)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF97316).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block_flipped, color: const Color(0xFFF97316), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Тухайн СӨХ нь зогсоолын холболт хийгээгүй байна.',
                          style: TextStyle(
                            color: const Color(0xFFF97316),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_quotaStatus != null && (_quotaStatus!['total'] > 0 || _quotaStatus!['freeMinutesPerGuest'] > 0))
                _buildQuotaCard(),
              
              if (!_isLoadingQuota && _quotaError == null && _quotaStatus != null && (_quotaStatus!['total'] > 0 || _quotaStatus!['freeMinutesPerGuest'] > 0))
                SizedBox(height: context.responsiveSpacing(
                  small: 16,
                  medium: 20,
                  large: 24,
                  tablet: 28,
                  veryNarrow: 12,
                )),

              // Form card
              Container(
                padding: context.responsivePadding(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                  veryNarrow: 16,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                  border: Border.all(color: context.borderColor, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Зочны машины мэдээлэл',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing(
                        small: 20,
                        medium: 24,
                        large: 28,
                        tablet: 32,
                        veryNarrow: 16,
                      )),
                      
                      // Car plate number (4 digits + 3 letters)
                      TextFormField(
                        key: ValueKey('plate_field_$_plateKeyboardType'),
                        controller: _mashiniiDugaarController,
                        focusNode: _plateFocusNode,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: _plateKeyboardType,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(7),
                          PlateNumberFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Машины дугаар',
                          hintText: '1234АБВ',
                          prefixIcon: Icon(
                            Icons.directions_car_outlined,
                            color: AppColors.deepGreen,
                            size: context.responsiveIconSize(
                              small: 22,
                              medium: 24,
                              large: 26,
                              tablet: 28,
                              veryNarrow: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: AppColors.deepGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor,
                          labelStyle: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: context.textSecondaryColor.withOpacity(0.5),
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 14,
                              medium: 16,
                              large: 18,
                              tablet: 20,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 17,
                            veryNarrow: 13,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Машины дугаар оруулна уу';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length != 7) {
                            return '4 тоо, 3 үсэг оруулна уу (жишээ: 1234УБҮ)';
                          }
                          // Check first 4 characters are digits
                          final digits = trimmed.substring(0, 4);
                          if (!RegExp(r'^[0-9]{4}$').hasMatch(digits)) {
                            return 'Эхний 4 тэмдэгт тоо байх ёстой';
                          }
                          // Check last 3 characters are Mongolian Cyrillic letters (А-Я, Ө, Ү, Ё)
                          final letters = trimmed.substring(4).toUpperCase();
                          if (!RegExp(r'^[А-ЯӨҮЁ]{3}$').hasMatch(letters)) {
                            return 'Сүүлийн 3 тэмдэгт заавал Монгол кирилл үсэг байна (жишээ: 1234УБҮ)';
                          }
                          return null;
                        },
                      ),

                      // Кирилл үсгийн товчлуур - утасны хэлийг солихгүйгээр
                      // сүүлийн 3 үсгийг шууд оруулах
                      _buildKirillTovchluur(),

                      SizedBox(height: context.responsiveSpacing(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 22,
                        veryNarrow: 12,
                      )),
                      
                      // Phone number (read-only, auto-filled with user's phone)
                      TextFormField(
                        controller: _ezemshigchiinUtasController,
                        keyboardType: TextInputType.phone,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Таны утасны дугаар',
                          hintText: _userPhoneNumber ?? 'Ачаалж байна...',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.deepGreen.withOpacity(0.6),
                            size: context.responsiveIconSize(
                              small: 22,
                              medium: 24,
                              large: 26,
                              tablet: 28,
                              veryNarrow: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: context.textSecondaryColor.withOpacity(0.5),
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 14,
                              medium: 16,
                              large: 18,
                              tablet: 20,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor.withOpacity(0.7),
                          fontSize: context.responsiveFontSize(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 17,
                            veryNarrow: 13,
                          ),
                        ),
                      ),
                      // Зогсоолын төлбөрийг хэн даах. Байгууллага
                      // зөвшөөрөөгүй бол сонголт БА түүний зай ч байхгүй.
                      if (_nekhemjlekhBolomjtoi) ...[
                        SizedBox(height: context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                          veryNarrow: 12,
                        )),
                        _buildTulburiinTurulSelector(),
                      ],

                      SizedBox(height: context.responsiveSpacing(
                        small: 24,
                        medium: 28,
                        large: 32,
                        tablet: 36,
                        veryNarrow: 20,
                      )),
                      
                      // Submit button
                        GestureDetector(
                          onTap: (_isLoading || !_hasQuota) ? null : _inviteGuest,
                         child: AnimatedContainer(
                           duration: const Duration(milliseconds: 200),
                           width: double.infinity,
                           padding: EdgeInsets.symmetric(
                             vertical: context.responsiveSpacing(
                               small: 12,
                               medium: 14,
                               large: 16,
                               tablet: 18,
                               veryNarrow: 10,
                             ),
                           ),
                           decoration: BoxDecoration(
                             gradient: (!_isLoading && _hasQuota)
                                 ? LinearGradient(
                                     colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                   )
                                 : null,
                             color: (!_isLoading && _hasQuota)
                                 ? null
                                 : Colors.grey.withOpacity(0.3),
                             borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                               small: 10,
                               medium: 12,
                               large: 14,
                               tablet: 16,
                               veryNarrow: 8,
                             )),
                             boxShadow: (!_isLoading && _hasQuota)
                                 ? [
                                     BoxShadow(
                                       color: AppColors.deepGreen.withOpacity(0.3),
                                       blurRadius: 8,
                                       offset: const Offset(0, 4),
                                     ),
                                   ]
                                 : [],
                           ),
                           child: Center(
                             child: _isLoading 
                               ? SizedBox(
                                   width: 20.sp,
                                   height: 20.sp,
                                   child: const CircularProgressIndicator(
                                     strokeWidth: 2,
                                     color: Colors.white,
                                   ),
                                 )
                               : Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(
                                       _hasQuota ? Icons.person_add_outlined : Icons.block_flipped,
                                       size: 20.sp,
                                       color: Colors.white,
                                     ),
                                     SizedBox(width: 8.w),
                                     Text(
                                       _hasQuota ? 'Зочин урих' : 'Эрх дууссан',
                                       style: TextStyle(
                                         color: Colors.white,
                                         fontSize: 15.sp,
                                         fontWeight: FontWeight.bold,
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
              
              SizedBox(height: context.responsiveSpacing(
                small: 24,
                medium: 28,
                large: 32,
                tablet: 36,
                veryNarrow: 20,
              )),
              
              // History section with Tabs
              Text(
                'Урилгын түүх',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: context.responsiveFontSize(
                    small: 16,
                    medium: 17,
                    large: 18,
                    tablet: 20,
                    veryNarrow: 14,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor, // Lighter background
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(4.w),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: context.cardBackgroundColor, // Card BG for selected
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Color(0xFF3B82F6), // Active Color
                  unselectedLabelColor: context.textPrimaryColor, // Inactive Color
                  labelStyle: TextStyle(
                    fontSize: 12.sp, 
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 12.sp, 
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
                  dividerColor: Colors.transparent, // Remove default divider
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Хүлээлгийн'),
                          if (_pendingGuests.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0 ? Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${_pendingGuests.length}',
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Идэвхтэй'),
                          if (_activeGuests.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1 ? Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${_activeGuests.length}',
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Гарсан'),
                        ],
                      ),
                    ),
                  ],
                  onTap: (index) {
                     setState(() {});
                  },
                ),
              ),
              
              SizedBox(height: 16.h),

              if (_isLoadingHistory)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.deepGreen,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 400.h, // Fixed height for list or use shrinkWrap with correct physics
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGuestList(_pendingGuests, 'Хүлээлгэ'),
                      _buildGuestList(_activeGuests, 'Идэвхтэй'),
                      _buildGuestList(_exitedGuests, 'Гарсан'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Улсын дугаарын сүүлийн 3 үсгийг оруулах кирилл товчлуур.
  ///
  /// ЯАГААД: утасны гаралтын хэлийг апп дундаас солих API байхгүй -
  /// TextInputType нь зөвхөн товчлуурын ТӨРЛИЙГ (тоо/текст) сонгодог, ХЭЛИЙГ
  /// нь биш. Тиймээс 4 цифр орсны дараа кирилл үсгийг өөрсдөө өгнө.
  Widget _buildKirillTovchluur() {
    final tekst = _mashiniiDugaarController.text;

    // Зөвхөн 4 цифр орсны дараа, 7 тэмдэгт болтол харуулна
    if (tekst.length < 4 || tekst.length >= 7) return const SizedBox.shrink();

    const useguud = [
      'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И',
      'Й', 'К', 'Л', 'М', 'Н', 'О', 'Ө', 'П', 'Р', 'С',
      'Т', 'У', 'Ү', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ',
      'Ы', 'Ь', 'Э', 'Ю', 'Я',
    ];

    void useg(String u) {
      if (_mashiniiDugaarController.text.length >= 7) return;
      _mashiniiDugaarController.text = _mashiniiDugaarController.text + u;
      _mashiniiDugaarController.selection = TextSelection.fromPosition(
        TextPosition(offset: _mashiniiDugaarController.text.length),
      );
    }

    void ustga() {
      final odoo = _mashiniiDugaarController.text;
      if (odoo.isEmpty) return;
      _mashiniiDugaarController.text = odoo.substring(0, odoo.length - 1);
      _mashiniiDugaarController.selection = TextSelection.fromPosition(
        TextPosition(offset: _mashiniiDugaarController.text.length),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard_alt_outlined,
                size: 13.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 5.w),
              Text(
                'Үсэг сонгоно уу (${tekst.length - 4}/3)',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 11.sp,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: ustga,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 15.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: useguud
                .map(
                  (u) => GestureDetector(
                    onTap: () => useg(u),
                    child: Container(
                      width: 34.w,
                      height: 34.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.surfaceColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: context.borderColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        u,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Зогсоолын төлбөрийг зочин өөрөө төлөх үү, эсвэл оршин суугчийн
  /// нэхэмжлэхэд бичих үү. Түрээсийн зогсоолын интеграц дээр л утгатай -
  /// бүртгэгдээгүй тохиолдолд сервер үүнийг үл тоомсорлоно.
  Widget _buildTulburiinTurulSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Зогсоолын төлбөр',
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _tulburiinTurulSongolt(
                utga: 'zochin',
                garchig: 'Зочин төлнө',
                tailbar: 'Хаалган дээр',
                dvrs: Icons.person_outline,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _tulburiinTurulSongolt(
                utga: 'ezen',
                garchig: 'Би даана',
                tailbar: 'Нэхэмжлэхэд',
                dvrs: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tulburiinTurulSongolt({
    required String utga,
    required String garchig,
    required String tailbar,
    required IconData dvrs,
  }) {
    final songogdson = _tulburiinTurul == utga;

    return GestureDetector(
      onTap: () {
        if (_tulburiinTurul != utga) {
          setState(() => _tulburiinTurul = utga);
          StorageService.saveZochinTulburiinTurul(utga);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: songogdson
              ? AppColors.deepGreen.withOpacity(0.12)
              : context.surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: songogdson
                ? AppColors.deepGreen
                : context.borderColor.withOpacity(0.5),
            width: songogdson ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              dvrs,
              size: 18.sp,
              color: songogdson
                  ? AppColors.deepGreen
                  : context.textSecondaryColor,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    garchig,
                    style: TextStyle(
                      color: songogdson
                          ? AppColors.deepGreen
                          : context.textPrimaryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tailbar,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 10.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestList(List<Map<String, dynamic>> guests, String type) {
    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 40.sp, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 10.h),
            Text('Машин байхгүй', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: ClampingScrollPhysics(),
      itemCount: guests.length,
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return _buildGuestCard(guests[index]);
      },
    );
  }

  Widget _buildQuotaCard() {
    final total = _quotaStatus?['total'] ?? 0;
    final used = _quotaStatus?['used'] ?? 0;
    final remaining = _quotaStatus?['remaining'] ?? 0;
    final period = _quotaStatus?['period'] == 'saraar' ? 'сард' : 'өдөрт';
    final freeMinutes = _quotaStatus?['freeMinutesPerGuest'] ?? 0;

    return Container(
      padding: context.responsivePadding(
        small: 16,
        medium: 18,
        large: 20,
        tablet: 22,
        veryNarrow: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        )),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Урилгын эрх ($period)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: context.responsiveFontSize(
                    small: 13,
                    medium: 14,
                    large: 15,
                    tablet: 16,
                    veryNarrow: 12,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (total == 0 || total > 999) ? 'Хязгааргүй' : '$remaining/$total үлдсэн',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          if (freeMinutes > 0) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Зочин бүр $freeMinutes минут үнэгүй',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFontSize(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                      veryNarrow: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteInvitation(Map<String, dynamic> guest) async {
    final id = guest['_id']?.toString();
    if (id == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Урилга цуцлах'),
        content: Text('Та энэ урилгыг цуцлахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Үгүй'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Тийм', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId == null) throw Exception('Байгууллагын ID олдсонгүй');

      await ApiService.deleteZochinInvitation(
        id: id,
        baiguullagiinId: baiguullagiinId,
      );

      if (mounted) {
        setState(() {
          _pendingGuests.removeWhere((item) => item['_id'] == id);
          _activeGuests.removeWhere((item) => item['_id'] == id);
          _exitedGuests.removeWhere((item) => item['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Урилга амжилттай цуцлагдлаа')),
        );
        _loadInvitedGuests(showLoading: false);
        _loadQuotaStatus();
        _loadZogsooliinTuukh();
      }
    } on ZochinZogsoolDeerException catch (e) {
      // Машин зогсоол дээр байхад цуцалбал гарах/төлбөрийн логик тасарна.
      // Урилга АмарСүх дээр ч устаагүй тул жагсаалтыг шинэчлээд орхино.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        _loadInvitedGuests(showLoading: false);
        _loadZogsooliinTuukh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Түрээсийн зогсоолын сүүлийн хөдөлгөөнийг картан дээр харуулна.
  /// Мэдээлэл байхгүй (интеграц асаагүй эсвэл зочин хараахан ороогүй) бол
  /// юу ч нэмэхгүй - хуучин карт хэвээрээ.
  Widget _buildZogsoolMedeelel(String mashiniiDugaar, int tuluv) {
    final dugaar = mashiniiDugaar.trim().toUpperCase();
    final tuukh = _zogsooliinTuukh[dugaar];
    if (tuukh == null) return const SizedBox.shrink();

    final uldsen = (tuukh['uneguiMinutUldsen'] as num?)?.toInt();
    final ashiglasan = (tuukh['uneguiMinutAshiglasan'] as num?)?.toInt();
    final tulukhDun = (tuukh['tulukhDun'] as num?)?.toInt() ?? 0;
    final tulburiinTurul = tuukh['tulburiinTurul']?.toString();
    final dotor = tuukh['garsanTsag'] == null;

    final temdegluud = <Widget>[];

    void nemye(IconData dvrs, String bichig, Color ungu) {
      temdegluud.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(dvrs, size: 10.sp, color: ungu),
            SizedBox(width: 3.w),
            Text(
              bichig,
              style: TextStyle(
                color: ungu,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // tuluv == 1 үед картын статус аль хэдийн "Идэвхтэй" гэж хэлсэн байгаа
    // тул давхардуулахгүй
    if (dotor && tuluv != 1) {
      nemye(Icons.local_parking, 'Зогсоол дээр', const Color(0xFF3B82F6));
    }

    if (uldsen != null && uldsen > 0) {
      nemye(Icons.timer_outlined, 'Үнэгүй $uldsen мин үлдсэн', AppColors.deepGreen);
    } else if (uldsen != null && uldsen <= 0) {
      nemye(Icons.timer_off_outlined, 'Үнэгүй минут дууссан', Colors.orange);
    } else if (ashiglasan != null && ashiglasan > 0) {
      nemye(Icons.timer_outlined, 'Үнэгүй $ashiglasan мин ашигласан', context.textSecondaryColor);
    }

    if (tulukhDun > 0) {
      final dunStr = NumberFormat('#,###').format(tulukhDun);
      nemye(
        Icons.payments_outlined,
        tulburiinTurul == 'ezen' ? '$dunStr₮ нэхэмжлэхэд' : '$dunStr₮ төлбөр',
        tulburiinTurul == 'ezen' ? Colors.orange : context.textSecondaryColor,
      );
    }

    if (temdegluud.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Wrap(spacing: 10.w, runSpacing: 4.h, children: temdegluud),
    );
  }

  /// Идэвхтэй зочны дэлгэрэнгүй - түрээсийн зогсоолоос ШУУД асуусан
  /// одоогийн байдал. Webhook хоцорсон ч энэ нь бодит утгыг харуулна.
  Widget _buildUrilgiinTuluvDelgerengui(String urilgiinId) {
    final achaalj = _tuluvAchaalj.contains(urilgiinId);
    final tuluv = _urilgiinTuluv[urilgiinId];

    Widget aguulga;

    if (achaalj && tuluv == null) {
      aguulga = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Зогсоолоос мэдээлэл авч байна...',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
          ),
        ],
      );
    } else if (tuluv == null) {
      aguulga = Text(
        'Зогсоолын мэдээлэл авах боломжгүй байна',
        style: TextStyle(color: Colors.orange, fontSize: 11.sp),
      );
    } else {
      final uldsen = (tuluv['uneguiMinutUldsen'] as num?)?.toInt() ?? 0;
      final ashiglasan =
          (tuluv['uneguiMinutAshiglasanNiit'] as num?)?.toInt() ?? 0;
      final tulburiinTurul = tuluv['tulburiinTurul']?.toString();

      // Сүүлийн session - идэвхтэй зочин бол гарах цаггүй нь энэ
      Map<String, dynamic>? sessionSuuli;
      final sessionuud = tuluv['sessionuud'];
      if (sessionuud is List && sessionuud.isNotEmpty) {
        final suuli = sessionuud.last;
        if (suuli is Map) sessionSuuli = Map<String, dynamic>.from(suuli);
      }

      String? orsonStr;
      if (sessionSuuli != null && sessionSuuli['orsonTsag'] != null) {
        try {
          orsonStr = DateFormat(
            'MM/dd HH:mm',
          ).format(DateTime.parse(sessionSuuli['orsonTsag'].toString()).toLocal());
        } catch (_) {}
      }

      aguulga = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tuluvMur(
            Icons.timer_outlined,
            'Үлдсэн үнэгүй минут',
            uldsen > 0 ? '$uldsen мин' : 'Дууссан',
            uldsen > 0 ? AppColors.deepGreen : Colors.orange,
          ),
          if (ashiglasan > 0)
            _tuluvMur(
              Icons.history_toggle_off,
              'Нийт ашигласан',
              '$ashiglasan мин',
              context.textSecondaryColor,
            ),
          if (orsonStr != null)
            _tuluvMur(
              Icons.login,
              'Орсон',
              orsonStr,
              const Color(0xFF3B82F6),
            ),
          _tuluvMur(
            Icons.payments_outlined,
            'Төлбөр',
            tulburiinTurul == 'ezen' ? 'Таны нэхэмжлэхэд' : 'Зочин өөрөө төлнө',
            tulburiinTurul == 'ezen'
                ? Colors.orange
                : context.textSecondaryColor,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor.withOpacity(0.5)),
      ),
      child: aguulga,
    );
  }

  Widget _tuluvMur(IconData dvrs, String garchig, String utga, Color ungu) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Icon(dvrs, size: 13.sp, color: ungu),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              garchig,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 11.sp,
              ),
            ),
          ),
          Text(
            utga,
            style: TextStyle(
              color: ungu,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    // Try to get data from either direct structure (ezenList) or nested (jagsaalt)
    final urisanMashin = guest['urisanMashin'];
    final isHistoryItem = urisanMashin != null;

    final mashiniiDugaar = isHistoryItem
        ? (guest['mashiniiDugaar'] ?? urisanMashin['urisanMashiniiDugaar'] ?? '')
        : (guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? '');

    final tuluv = isHistoryItem 
        ? (urisanMashin['tuluv'] ?? 0)
        : (guest['tuluv'] ?? 0);

    // Түрээсийн систем дээрх урилгыг АмарСүхийн ezenUrisanMashin._id-гээр
    // танина. ezenList дээр тэр нь баримтын өөрийнх нь _id, харин түүхийн
    // мөрөнд urisanMashin дотор л байна (дугаараар таарсан бол хоосон).
    final urilgiinId = isHistoryItem
        ? urisanMashin['_id']?.toString()
        : guest['_id']?.toString();

    final createdAt = isHistoryItem
        ? (urisanMashin['createdAt'] ?? guest['createdAt'])
        : guest['createdAt'];

    DateTime? entryTime;
    DateTime? exitTime;

    // Parse entry time from tuukh or createdAt
    if (guest['tuukh'] != null && guest['tuukh'] is List && (guest['tuukh'] as List).isNotEmpty) {
      final lastTuukh = (guest['tuukh'] as List).last;
      if (lastTuukh['tsagiinTuukh'] != null && (lastTuukh['tsagiinTuukh'] as List).isNotEmpty) {
        final tsagiinTuukh = lastTuukh['tsagiinTuukh'] as List;
        final firstEntry = tsagiinTuukh.first;
        final lastExit = tsagiinTuukh.last;
        if (firstEntry['orsonTsag'] != null) {
          try {
            entryTime = DateTime.parse(firstEntry['orsonTsag'].toString()).toLocal();
          } catch (_) {}
        }
        if (lastExit['garsanTsag'] != null) {
          try {
            exitTime = DateTime.parse(lastExit['garsanTsag'].toString()).toLocal();
          } catch (_) {}
        }
      }
    }

    if (entryTime == null && createdAt != null) {
      try {
        entryTime = DateTime.parse(createdAt.toString()).toLocal();
      } catch (_) {}
    }

    if (exitTime == null && (tuluv == 2)) {
      if (guest['garakhTsag'] != null) {
        try {
          exitTime = DateTime.parse(guest['garakhTsag'].toString()).toLocal();
        } catch (_) {}
      } else if (guest['updatedAt'] != null) {
        try {
          exitTime = DateTime.parse(guest['updatedAt'].toString()).toLocal();
        } catch (_) {}
      }
    }

    String entryTimeStr = entryTime != null ? DateFormat('HH:mm').format(entryTime) : '';
    String exitTimeStr = exitTime != null ? DateFormat('HH:mm').format(exitTime) : '';
    String dateStr = entryTime != null
        ? DateFormat('MM/dd').format(entryTime)
        : (createdAt != null ? DateFormat('MM/dd').format(DateTime.parse(createdAt.toString()).toLocal()) : '');

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (tuluv == 1) {
      statusText = entryTimeStr.isNotEmpty ? 'Идэвхтэй (Орсон: $entryTimeStr)' : 'Идэвхтэй';
      statusColor = const Color(0xFF3B82F6);
      statusBgColor = const Color(0xFF1E3A8A).withOpacity(0.3);
    } else if (tuluv == 2) {
      statusText = 'Гарсан';
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.withOpacity(0.1);
    } else {
      statusText = 'Хүлээлгэ';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    }

    final cardContent = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tuluv == 1)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mashiniiDugaar,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tuluv == 1) ...[
                                  Icon(Icons.location_on, size: 11.sp, color: statusColor),
                                  SizedBox(width: 3.w),
                                ],
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Түрээсийн зогсоолын мэдээлэл (webhook-оор ирсэн)
                      _buildZogsoolMedeelel(mashiniiDugaar.toString(), tuluv),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (tuluv == 1 && urilgiinId != null && urilgiinId.isNotEmpty)
                Icon(
                  _delgerengiiUrilgiinId == urilgiinId
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20.sp,
                  color: context.textSecondaryColor,
                ),
              if (tuluv != 1 && (entryTimeStr.isNotEmpty || exitTimeStr.isNotEmpty))
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entryTimeStr.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login, size: 11.sp, color: Colors.green[400]),
                            SizedBox(width: 3.w),
                            Text(
                              'Орсон: $entryTimeStr',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (exitTimeStr.isNotEmpty && tuluv == 2)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 11.sp, color: Colors.orange[300]),
                              SizedBox(width: 3.w),
                              Text(
                                'Гарсан: $exitTimeStr',
                                style: TextStyle(
                                  color: Colors.orange[300],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // Идэвхтэй зочин - товшиход түрээсээс одоогийн байдлыг шууд асууна
    if (tuluv == 1 && urilgiinId != null && urilgiinId.isNotEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _urilgiinTuluvSolikh(urilgiinId),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cardContent,
            if (_delgerengiiUrilgiinId == urilgiinId)
              _buildUrilgiinTuluvDelgerengui(urilgiinId),
          ],
        ),
      );
    }

    // Only allow swipe-to-delete if "Waiting" (tuluv == 0)
    if (tuluv == 0) {
      return Dismissible(
        key: Key(guest['_id']?.toString() ?? UniqueKey().toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          await _deleteInvitation(guest);
          return false; // We return false because _deleteInvitation handles the logic and refresh
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: cardContent,
      );
    }

    return cardContent;
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

/// Custom formatter for Mongolian car plates: 4 digits + 3 Mongolian Cyrillic letters
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
