import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/mongol_plate_keyboard.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/screens/zochin_urikh/top_toast.dart';

Color _yashil(BuildContext context) =>
    context.isDarkMode ? AppColors.secondaryLight : AppColors.deepGreen;

class ZochinNemekhPage extends StatefulWidget {
  final Map<String, dynamic>? quotaStatus;
  final bool hasQuota;
  final List<Map<String, dynamic>> pendingGuests;

  const ZochinNemekhPage({
    super.key,
    this.quotaStatus,
    this.hasQuota = true,
    this.pendingGuests = const [],
  });

  @override
  State<ZochinNemekhPage> createState() => _ZochinNemekhPageState();
}

class _ZochinNemekhPageState extends State<ZochinNemekhPage> {
  final _formKey = GlobalKey<FormState>();
  final _mashiniiDugaarController = TextEditingController();
  final FocusNode _plateFocusNode = FocusNode();
  TextInputType _plateKeyboardType = TextInputType.number;
  final GlobalKey _plateFieldKey = GlobalKey();

  bool _isLoading = false;
  String _tulburiinTurul = 'zochin';
  Map<String, dynamic>? _quotaStatus;
  bool _hasQuota = true;

  bool get _nekhemjlekhBolomjtoi => _quotaStatus?['nekhemjlekhEsekh'] == true;

  @override
  void initState() {
    super.initState();
    _quotaStatus = widget.quotaStatus;
    _hasQuota = widget.hasQuota;
    _mashiniiDugaarController.addListener(_onPlateTextChanged);
    _plateFocusNode.addListener(_onPlateFocusChanged);
    _loadTulburiinTurul();
    _loadFreshQuota();

    // Auto-focus after page transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _plateFocusNode.requestFocus();
    });
  }

  void _onPlateFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onPlateTextChanged() {
    final text = _mashiniiDugaarController.text;
    final targetType = MongolPlateKeyboard.keyboardTypeFor(text);
    if (_plateKeyboardType != targetType) {
      setState(() {
        _plateKeyboardType = targetType;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_plateFocusNode.hasFocus) return;
        SystemChannels.textInput.invokeMethod(
          targetType == TextInputType.none ? 'TextInput.hide' : 'TextInput.show',
        );
        final ctx = _plateFieldKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.3, duration: const Duration(milliseconds: 200));
        }
      });
    } else {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadTulburiinTurul() async {
    final khadgalsan = await StorageService.getZochinTulburiinTurul();
    if (khadgalsan != null && mounted && khadgalsan != _tulburiinTurul) {
      setState(() => _tulburiinTurul = khadgalsan);
    }
  }

  Future<void> _loadFreshQuota() async {
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
    } catch (_) {}
  }

  @override
  void dispose() {
    _mashiniiDugaarController.removeListener(_onPlateTextChanged);
    _plateFocusNode.removeListener(_onPlateFocusChanged);
    _plateFocusNode.dispose();
    _mashiniiDugaarController.dispose();
    super.dispose();
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    final targetPlate = _mashiniiDugaarController.text.trim().toUpperCase();

    setState(() => _isLoading = true);

    try {
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

        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final activeGreen = _yashil(context);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Шинэ зочин урих',
      ),
      bottomNavigationBar: _plateFocusNode.hasFocus &&
              MongolPlateKeyboard.kheregtei(_mashiniiDugaarController.text)
          ? MongolPlateKeyboard(
              controller: _mashiniiDugaarController,
              docked: true,
              onDone: () => _plateFocusNode.unfocus(),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quota summary card
                if (_quotaStatus != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: activeGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: activeGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 20.sp, color: activeGreen),
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
                                  color: activeGreen,
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
                  SizedBox(height: 20.h),
                ],

                // Plate input section
                Text(
                  'Машины дугаар',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  key: _plateFieldKey,
                  controller: _mashiniiDugaarController,
                  focusNode: _plateFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: _plateKeyboardType,
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
                      color: context.textSecondaryColor.withOpacity(0.4),
                      letterSpacing: 2,
                      fontSize: 18.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.directions_car_outlined,
                      color: activeGreen,
                    ),
                    filled: true,
                    fillColor: context.cardBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: activeGreen, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Машины дугаар оруулна уу';
                    }
                    final trimmed = value.trim();
                    if (trimmed.length != 7) {
                      return '4 тоо, 3 үсэг оруулна уу (жишээ: 5555ННН)';
                    }
                    final digits = trimmed.substring(0, 4);
                    if (!RegExp(r'^[0-9]{4}$').hasMatch(digits)) {
                      return 'Эхний 4 тэмдэгт тоо байх ёстой';
                    }
                    final letters = trimmed.substring(4).toUpperCase();
                    if (!RegExp(r'^[А-ЯӨҮЁ]{3}$').hasMatch(letters)) {
                      return 'Сүүлийн 3 тэмдэгт Монгол кирилл үсэг байна';
                    }
                    return null;
                  },
                ),

                // Payment choice
                if (_nekhemjlekhBolomjtoi) ...[
                  SizedBox(height: 20.h),
                  Text(
                    'Зогсоолын төлбөр',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
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
                            setState(() => _tulburiinTurul = 'zochin');
                            StorageService.saveZochinTulburiinTurul('zochin');
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _paymentChoiceItem(
                          value: 'ezen',
                          title: 'Би даана',
                          sub: 'Нэхэмжлэхэд',
                          icon: Icons.receipt_long_outlined,
                          selected: _tulburiinTurul == 'ezen',
                          onTap: () {
                            setState(() => _tulburiinTurul = 'ezen');
                            StorageService.saveZochinTulburiinTurul('ezen');
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 32.h),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _inviteGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
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
                        : Text(
                            'Зочин урих',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
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
    final activeGreen = _yashil(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? activeGreen.withOpacity(0.12) : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? activeGreen : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: selected ? activeGreen : context.textSecondaryColor,
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
                      color: selected ? activeGreen : context.textPrimaryColor,
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
