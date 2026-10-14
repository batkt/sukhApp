import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/utils/logger.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/mongol_plate_keyboard.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/screens/zochin_urikh/zochin_medeelel_page.dart';
import 'package:sukh_app/screens/zochin_urikh/top_toast.dart';

Color _yashil(BuildContext context) =>
    context.isDarkMode ? AppColors.secondaryLight : AppColors.deepGreen;

class ZochinUrikhPage extends StatefulWidget {
  const ZochinUrikhPage({super.key});

  @override
  State<ZochinUrikhPage> createState() => _ZochinUrikhPageState();
}

class _ZochinUrikhPageState extends State<ZochinUrikhPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mashiniiDugaarController = TextEditingController();
  final _ezemshigchiinUtasController = TextEditingController();
  final FocusNode _plateFocusNode = FocusNode();

  bool _isLoading = false;

  // Lists for different statuses
  List<Map<String, dynamic>> _pendingGuests = [];
  List<Map<String, dynamic>> _activeGuests = [];
  List<Map<String, dynamic>> _exitedGuests = [];

  late TabController _tabController;
  bool _isLoadingHistory = true;
  Map<String, dynamic>? _quotaStatus;
  bool _hasQuota = true;

  bool get _nekhemjlekhBolomjtoi => _quotaStatus?['nekhemjlekhEsekh'] == true;
  String _tulburiinTurul = 'zochin';

  final Map<String, Map<String, dynamic>> _zogsooliinTuukh = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPhone();
    _loadTulburiinTurul();
    _loadInvitedGuests();
    _loadQuotaStatus();
    _loadZogsooliinTuukh();
    _setupSocketListener();
  }



  void _setupSocketListener() {
    SocketService.instance.setNotificationCallback(_handleSocketMessage);
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    AppLogger.log('🔔 Socket message received in ZochinUrikhPage, reloading list...');
    final turul = data['type']?.toString();
    if (turul == 'ZOCHIN_ORSON' || turul == 'ZOCHIN_GARSAN') {
      _loadZogsooliinTuukh();
      if (mounted) {
        final medegdel = data['message']?.toString();
        if (medegdel != null && medegdel.isNotEmpty) {
          TopToast.show(
            context,
            message: medegdel,
            type: TopToastType.success,
          );
        }
      }
    }
    _loadInvitedGuests(showLoading: false);
    _loadQuotaStatus();
  }

  Future<void> _loadTulburiinTurul() async {
    final khadgalsan = await StorageService.getZochinTulburiinTurul();
    if (khadgalsan != null && mounted && khadgalsan != _tulburiinTurul) {
      setState(() => _tulburiinTurul = khadgalsan);
    }
  }

  Future<void> _loadZogsooliinTuukh() async {
    try {
      final khariu = await ApiService.fetchZochinZogsoolTuukh();
      final jagsaalt = khariu['jagsaalt'];
      if (jagsaalt is! List) return;

      final shine = <String, Map<String, dynamic>>{};
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
      final status = await ApiService.fetchZochinQuotaStatus();

      if (mounted) {
        setState(() {
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

          _quotaStatus = {
            'total': data['total'] ?? data['zochinErkhiinToo'] ?? 0,
            'used': data['used'] ?? data['ashiglasanToo'] ?? 0,
            'remaining': data['remaining'] ?? data['uldsenToo'] ?? 0,
            'period': data['period'] ?? 'saraar',
            'freeMinutesPerGuest': data['freeMinutesPerGuest'] ?? data['zochinTusBurUneguiMinut'] ?? 90,
            'hasRight': data['hasRight'] ?? data['zochinUrikhEsekh'] ?? true,
            'nekhemjlekhEsekh': data['nekhemjlekhEsekh'] == true,
          };

          final hasRight = _quotaStatus!['hasRight'] as bool;
          if (status['success'] == false || !hasRight) {
            _hasQuota = false;
          } else {
            final remaining = _quotaStatus!['remaining'] as int;
            final total = _quotaStatus!['total'] as int;
            _hasQuota = (total == 0) || (remaining > 0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasQuota = true;
        });
      }
    }
  }

  Future<void> _loadUserPhone() async {
    final phone = await StorageService.getSavedPhoneNumber();
    if (mounted && phone != null) {
      setState(() {
        _ezemshigchiinUtasController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    SocketService.instance.removeNotificationCallback(_handleSocketMessage);
    _plateFocusNode.dispose();
    _tabController.dispose();
    _mashiniiDugaarController.dispose();
    _ezemshigchiinUtasController.dispose();
    super.dispose();
  }

  bool _garsanEsekh(Map<String, dynamic> item) {
    final tuukh = item['tuukh'];
    if (tuukh is List && tuukh.isNotEmpty) {
      final mur = tuukh.first;
      if (mur is Map) {
        final khaalga = mur['garsanKhaalga'];
        if (khaalga != null && khaalga.toString().trim().isNotEmpty) return true;

        final tsaguud = mur['tsagiinTuukh'];
        if (tsaguud is List && tsaguud.isNotEmpty) {
          final tsag = tsaguud.first;
          if (tsag is Map && tsag['garsanTsag'] != null) return true;
        }
      }
    }

    final um = item['urisanMashin'];
    if (um is Map && (um['tuluv'] ?? 0) == 2) return true;
    return (item['tuluv'] ?? 0) == 2;
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
            final historyItems = List<Map<String, dynamic>>.from(jagsaalt);

            _activeGuests =
                historyItems.where((item) => !_garsanEsekh(item)).toList();
            _exitedGuests =
                historyItems.where((item) => _garsanEsekh(item)).toList();

            final activePlates = <String>{};
            for (final g in _activeGuests) {
              final p = (g['mashiniiDugaar'] ?? g['urisanMashin']?['urisanMashiniiDugaar'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();
              if (p.isNotEmpty) activePlates.add(p);
            }

            final seenPendingPlates = <String>{};
            _pendingGuests = [];
            for (final item in ezenList) {
              final tuluv = item['tuluv'] ?? 0;
              if (tuluv != 0) continue;
              final plate = (item['urisanMashiniiDugaar'] ?? item['mashiniiDugaar'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();
              if (plate.isEmpty) continue;
              if (activePlates.contains(plate)) continue;
              if (seenPendingPlates.contains(plate)) continue;
              seenPendingPlates.add(plate);
              _pendingGuests.add(Map<String, dynamic>.from(item));
            }

            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      AppLogger.log('Error loading invited guests: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  String _formatPlate(String raw) {
    return raw.replaceAll(' ', '').trim().toUpperCase();
  }

  String _formatPlateDisplay(String raw) {
    final clean = raw.replaceAll(' ', '').trim().toUpperCase();
    if (clean.length == 7 && RegExp(r'^[0-9]{4}[А-ЯӨҮЁA-Z]{3}$').hasMatch(clean)) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return clean;
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    final targetPlate = _mashiniiDugaarController.text.replaceAll(' ', '').trim().toUpperCase();

    final activePlates = <String>{};
    for (final g in _activeGuests) {
      final p = (g['mashiniiDugaar'] ?? g['urisanMashin']?['urisanMashiniiDugaar'] ?? '')
          .toString()
          .replaceAll(' ', '')
          .trim()
          .toUpperCase();
      if (p.isNotEmpty) activePlates.add(p);
    }
    if (activePlates.contains(targetPlate)) {
      TopToast.show(
        context,
        message: 'Тухайн машин зогсоолд орсон байна.',
        type: TopToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        _mashiniiDugaarController.clear();
        Navigator.pop(context);

        final turees = khariu['turees'];
        String medegdel = 'Зочин амжилттай уригдлаа';
        Color ungu = _yashil(context);

        if (turees is Map) {
          final buurtgegdsen = turees['buurtgegdsen'] == true;
          final tokhirgoogui = turees['tokhirgoogui'] == true;

          if (buurtgegdsen) {
            final tulukh = turees['tulburiinTurul']?.toString();
            if (_tulburiinTurul == 'ezen' && tulukh == 'zochin') {
              medegdel = 'Зочин уригдлаа.';
            } else if (tulukh == 'ezen') {
              medegdel = 'Зочин уригдлаа. Зогсоолын төлбөр таны нэхэмжлэхэд бичигдэнэ.';
            } else {
              medegdel = 'Зочин уригдлаа. Зогсоолд бүртгэгдлээ.';
            }
          } else if (!tokhirgoogui) {
            medegdel = 'Зочин уригдлаа. Гэхдээ зогсоолын системд бүртгэгдсэнгүй.';
            ungu = AppColors.warning;
          }
        }

        TopToast.show(
          context,
          message: medegdel,
          type: ungu == AppColors.warning
              ? TopToastType.warning
              : TopToastType.success,
        );

        _loadInvitedGuests();
        _loadQuotaStatus();
        _loadZogsooliinTuukh();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = friendlyError(e, fallback: 'Зочин урьж чадсангүй. Дахин оролдоно уу.');
        TopToast.show(
          context,
          message: errorMessage,
          type: TopToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInviteBottomSheet() {
    _mashiniiDugaarController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalCtx).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                width: 40.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.15)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                            ),
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Шинэ зочин урих',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: context.textSecondaryColor),
                                  onPressed: () => Navigator.pop(modalCtx),
                                ),
                              ],
                            ),
                            Divider(height: 16.h, color: context.borderColor),
                            SizedBox(height: 10.h),

                            // Quota info
                            if (_quotaStatus != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: _yashil(context).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: _yashil(context).withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 20.sp, color: _yashil(context)),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Зочин бүр ${_quotaStatus!['freeMinutesPerGuest']} минут үнэгүй',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
                                              color: _yashil(context),
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'Үлдсэн урилгын эрх: ${_quotaStatus!['total'] == 0 ? "Хязгааргүй" : "${_quotaStatus!['remaining']}/${_quotaStatus!['total']}"}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],

                            // Plate Input with dynamic keypad
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _mashiniiDugaarController,
                              builder: (context, value, _) {
                                final clean = value.text.replaceAll(' ', '').toUpperCase();
                                final isDigitPhase = clean.length < 4;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Машины дугаар',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    TextFormField(
                                      key: ValueKey(isDigitPhase ? 'plate_digits' : 'plate_letters'),
                                      controller: _mashiniiDugaarController,
                                      focusNode: _plateFocusNode,
                                      autofocus: true,
                                      showCursor: true,
                                      textCapitalization: TextCapitalization.characters,
                                      keyboardType: isDigitPhase ? TextInputType.number : TextInputType.none,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(7),
                                        PlateNumberFormatter(),
                                      ],
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '5555ННН',
                                        hintStyle: TextStyle(
                                          color: context.textSecondaryColor.withOpacity(0.35),
                                          letterSpacing: 2,
                                          fontSize: 18.sp,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.directions_car_outlined,
                                          color: _yashil(context),
                                        ),
                                        filled: true,
                                        fillColor: context.surfaceColor,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide(color: context.borderColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide(color: context.borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide(color: _yashil(context), width: 1.8),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Машины дугаар оруулна уу';
                                        }
                                        final t = val.replaceAll(' ', '').trim().toUpperCase();
                                        if (t.length != 7) {
                                          return '4 тоо, 3 үсэг оруулна уу (жишээ: 5555ННН)';
                                        }
                                        final digits = t.substring(0, 4);
                                        if (!RegExp(r'^[0-9]{4}$').hasMatch(digits)) {
                                          return 'Эхний 4 тэмдэгт тоо байх ёстой';
                                        }
                                        final letters = t.substring(4);
                                        if (!RegExp(r'^[А-ЯӨҮЁ]{3}$').hasMatch(letters)) {
                                          return 'Сүүлийн 3 тэмдэгт Монгол кирилл үсэг байна';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (MongolPlateKeyboard.kheregtei(clean)) ...[
                                      SizedBox(height: 12.h),
                                      MongolPlateKeyboard(
                                        controller: _mashiniiDugaarController,
                                        docked: false,
                                        onDone: () => _plateFocusNode.unfocus(),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),

                            // Payment choice
                            if (_nekhemjlekhBolomjtoi) ...[
                              SizedBox(height: 16.h),
                              Text(
                                'Зогсоолын төлбөр',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _paymentChoiceItem(
                                      value: 'zochin',
                                      title: 'Зочин төлнө',
                                      sub: 'Хаалган дээр',
                                      icon: Icons.person_outline,
                                      selected: _tulburiinTurul == 'zochin',
                                      onTap: () {
                                        setModalState(() => _tulburiinTurul = 'zochin');
                                        setState(() => _tulburiinTurul = 'zochin');
                                        StorageService.saveZochinTulburiinTurul('zochin');
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: _paymentChoiceItem(
                                      value: 'ezen',
                                      title: 'Би даана',
                                      sub: 'Нэхэмжлэхэд',
                                      icon: Icons.receipt_long_outlined,
                                      selected: _tulburiinTurul == 'ezen',
                                      onTap: () {
                                        setModalState(() => _tulburiinTurul = 'ezen');
                                        setState(() => _tulburiinTurul = 'ezen');
                                        StorageService.saveZochinTulburiinTurul('ezen');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            SizedBox(height: 20.h),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setModalState(() => _isLoading = true);
                                        await _inviteGuest();
                                        if (mounted) {
                                          setModalState(() => _isLoading = false);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _yashil(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Урих',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
          },
        );
      },
    );
  }

  Widget _paymentChoiceItem({
    required String value,
    required String title,
    required String sub,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final activeColor = _yashil(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? activeColor : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: selected ? activeColor : context.textSecondaryColor,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? activeColor : context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.textSecondaryColor,
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

  Future<void> _deleteInvitation(Map<String, dynamic> guest) async {
    final urisanMashin = guest['urisanMashin'];
    final id = (urisanMashin != null ? urisanMashin['_id'] : guest['_id'])?.toString();
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Урилга цуцлах', style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
        content: Text('Та энэ зочны урилгыг цуцлахдаа итгэлтэй байна уу?', style: TextStyle(color: context.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Үгүй', style: TextStyle(color: context.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Тийм', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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
        TopToast.show(
          context,
          message: 'Урилга амжилттай цуцлагдлаа',
          type: TopToastType.success,
        );
        _loadInvitedGuests(showLoading: false);
        _loadQuotaStatus();
        _loadZogsooliinTuukh();
      }
    } catch (e) {
      if (mounted) {
        TopToast.show(
          context,
          message: friendlyError(e, fallback: 'Урилга цуцалж чадсангүй.'),
          type: TopToastType.error,
        );
      }
    }
  }

  void _openDetails(Map<String, dynamic> guest) async {
    final urisanMashin = guest['urisanMashin'];
    final plate = (urisanMashin != null
            ? (guest['mashiniiDugaar'] ?? urisanMashin['urisanMashiniiDugaar'] ?? '')
            : (guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? ''))
        .toString()
        .trim()
        .toUpperCase();

    final tuukh = _zogsooliinTuukh[plate];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZochinMedeelelPage(
          guest: guest,
          zogsoolTuukh: tuukh,
          quotaStatus: _quotaStatus,
        ),
      ),
    );

    if (result == true) {
      _loadInvitedGuests(showLoading: false);
      _loadQuotaStatus();
      _loadZogsooliinTuukh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = [..._activeGuests, ..._pendingGuests];
    activeList.sort((a, b) {
      DateTime? timeA;
      DateTime? timeB;
      try {
        final aDateStr = a['urisanMashin']?['updatedAt'] ??
            a['urisanMashin']?['createdAt'] ??
            a['updatedAt'] ??
            a['createdAt'];
        if (aDateStr != null) timeA = DateTime.parse(aDateStr.toString());
      } catch (_) {}
      try {
        final bDateStr = b['urisanMashin']?['updatedAt'] ??
            b['urisanMashin']?['createdAt'] ??
            b['updatedAt'] ??
            b['createdAt'];
        if (bDateStr != null) timeB = DateTime.parse(bDateStr.toString());
      } catch (_) {}
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });
    final total = (_quotaStatus?['total'] ?? 0) as int;
    final remaining = (_quotaStatus?['remaining'] ?? 0) as int;
    final freeMinutes = (_quotaStatus?['freeMinutesPerGuest'] ?? 90) as int;
    final isLimitReached = !_hasQuota;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Зочин урих',
        actions: [
          if (_quotaStatus != null)
            Center(
              child: GestureDetector(
                onTap: () {
                  _loadInvitedGuests();
                  _loadQuotaStatus();
                  _loadZogsooliinTuukh();
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16.w),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isLimitReached
                        ? AppColors.error.withOpacity(0.12)
                        : _yashil(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isLimitReached
                          ? AppColors.error.withOpacity(0.25)
                          : _yashil(context).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 15.sp,
                        color: isLimitReached ? AppColors.error : _yashil(context),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        total == 0 ? 'Хязгааргүй' : '$remaining/$total',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isLimitReached ? AppColors.error : _yashil(context),
                        ),
                      ),
                      if (freeMinutes > 0) ...[
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 6.w),
                          width: 1,
                          height: 10.h,
                          color: (isLimitReached ? AppColors.error : _yashil(context))
                              .withOpacity(0.3),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          size: 13.sp,
                          color: isLimitReached ? AppColors.error : _yashil(context),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '$freeMinutes мин',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isLimitReached ? AppColors.error : _yashil(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.borderColor, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: _yashil(context),
                indicatorWeight: 2.5,
                labelColor: _yashil(context),
                unselectedLabelColor: context.textSecondaryColor,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(text: 'Идэвхтэй (${activeList.length})'),
                  const Tab(text: 'Түүх'),
                ],
              ),
            ),

            // Prominent "+ Зочин" button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isLimitReached ? null : _showInviteBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yashil(context),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.shade300,
                    disabledForegroundColor: context.textSecondaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isLimitReached) ...[
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        isLimitReached ? 'Лимит дууссан' : 'Зочин',
                        style: TextStyle(
                          color: isLimitReached
                              ? context.textSecondaryColor
                              : Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content list
            Expanded(
              child: _isLoadingHistory
                  ? Center(
                      child: CircularProgressIndicator(color: _yashil(context)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGuestList(activeList, isHistoryTab: false),
                        _buildGuestList(_exitedGuests, isHistoryTab: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestList(List<Map<String, dynamic>> list, {required bool isHistoryTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 48.sp, color: context.textSecondaryColor.withOpacity(0.5)),
            SizedBox(height: 12.h),
            Text(
              isHistoryTab ? 'Түүх байхгүй байна' : 'Идэвхтэй урилга байхгүй байна',
              style: TextStyle(color: context.textSecondaryColor, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (ctx, index) => _buildGuestCard(list[index]),
    );
  }

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    final urisanMashin = guest['urisanMashin'];
    final isHistoryItem = urisanMashin != null;

    final rawPlate = isHistoryItem
        ? (guest['mashiniiDugaar'] ?? urisanMashin['urisanMashiniiDugaar'] ?? '')
        : (guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? '');
    final plateStr = _formatPlate(rawPlate.toString());

    final tuluv = isHistoryItem
        ? (urisanMashin['tuluv'] ?? 0)
        : (guest['tuluv'] ?? 0);

    DateTime? entryTime;
    DateTime? exitTime;
    final createdAt = isHistoryItem
        ? (urisanMashin['createdAt'] ?? guest['createdAt'])
        : (guest['createdAt'] ?? guest['ognoo']);

    if (guest['tuukh'] is List && (guest['tuukh'] as List).isNotEmpty) {
      final lastTuukh = (guest['tuukh'] as List).last;
      if (lastTuukh is Map && lastTuukh['tsagiinTuukh'] is List && (lastTuukh['tsagiinTuukh'] as List).isNotEmpty) {
        final tsagList = lastTuukh['tsagiinTuukh'] as List;
        final firstTsag = tsagList.first;
        final lastTsag = tsagList.last;
        if (firstTsag is Map && firstTsag['orsonTsag'] != null) {
          try {
            entryTime = DateTime.parse(firstTsag['orsonTsag'].toString()).toLocal();
          } catch (_) {}
        }
        if (lastTsag is Map && lastTsag['garsanTsag'] != null) {
          try {
            exitTime = DateTime.parse(lastTsag['garsanTsag'].toString()).toLocal();
          } catch (_) {}
        }
      }
    }

    final bool isWaiting = (tuluv == 0);
    final bool isEntered = (tuluv == 1) || (!isWaiting && entryTime != null && exitTime == null);
    final bool isExited = (tuluv == 2) || (!isWaiting && exitTime != null);

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (isEntered) {
      statusText = 'Зогсоолд орсон';
      statusColor = _yashil(context);
      statusBgColor = _yashil(context).withOpacity(0.12);
    } else if (isExited) {
      statusText = 'Зогсоолоос гарсан';
      statusColor = context.textSecondaryColor;
      statusBgColor = context.isDarkMode
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05);
    } else {
      statusText = 'Зогсоолд ороогүй';
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warning.withOpacity(0.12);
    }

    String timePrefix = '';
    if (entryTime != null) {
      timePrefix = DateFormat('yyyy-MM-dd HH:mm').format(entryTime);
    } else if (createdAt != null) {
      try {
        final cDate = DateTime.parse(createdAt.toString()).toLocal();
        timePrefix = DateFormat('yyyy-MM-dd HH:mm').format(cDate);
      } catch (_) {}
    }
    if (timePrefix.isEmpty) {
      timePrefix = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    }

    final freeMinutes = (urisanMashin?['tusBurUneguiMinut'] ??
        guest['tusBurUneguiMinut'] ??
        _quotaStatus?['freeMinutesPerGuest'] ??
        90) as int;

    String subtitle = '$timePrefix · $freeMinutes минут';
    if (isEntered) {
      subtitle = '$timePrefix · Үлдсэн $freeMinutes минут';
    }

    return InkWell(
      onTap: () => _openDetails(guest),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular car icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _yashil(context).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: _yashil(context),
                      size: 22.sp,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Plate Number - formatted with space and never wraps
                Text(
                  _formatPlateDisplay(plateStr),
                  style: TextStyle(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                // Status pill in top right
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                // Compact 3 dots menu
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: context.textSecondaryColor, size: 18.sp),
                    color: context.cardBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    onSelected: (val) {
                      if (val == 'details') {
                        _openDetails(guest);
                      } else if (val == 'delete') {
                        _deleteInvitation(guest);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: context.textPrimaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Зочны мэдээлэл', style: TextStyle(color: context.textPrimaryColor)),
                          ],
                        ),
                      ),
                      if (isWaiting)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              SizedBox(width: 8),
                              Text('Устгах', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.only(left: 50.w),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13.sp,
                    color: context.textSecondaryColor,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.5.sp,
                      ),
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
    final text = newValue.text.replaceAll(' ', '').toUpperCase();
    String result = '';

    for (int i = 0; i < text.length && i < 7; i++) {
      String char = text[i];
      if (i < 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          result += char;
        }
      } else {
        if (_latinToCyrillic.containsKey(char)) {
          char = _latinToCyrillic[char]!;
        }
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
