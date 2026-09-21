import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Цэвэрлэгээний огноо, цаг сонгох хуудас.
///
/// Material-ийн стандарт `showDatePicker` + `showTimePicker` нь хоёр тусдаа
/// цонх нээж, цагийг нь тоологчоор сонгуулдаг — цэвэрлэгээ захиалахад хэт
/// удаан бөгөөд ямар цагууд БОЛОМЖТОЙ болохыг огт харуулдаггүй.
///
/// Энд нэг хуудсан дээр: дээр нь 14 хоногийн зурвас, доор нь цагийн нүднүүд.
/// Өнөөдрийн өнгөрсөн цагууд болон ажлын бус цаг нь идэвхгүй харагдана.
class OgnooSongokhSheet extends StatefulWidget {
  const OgnooSongokhSheet({super.key, this.ekhniiSongolt});

  /// Өмнө нь сонгосон утга байвал түүн дээрээ нээгдэнэ.
  final DateTime? ekhniiSongolt;

  /// Хуудсыг нээгээд сонгосон утгыг буцаана. Болив `null`.
  static Future<DateTime?> uzuuley(
    BuildContext context, {
    DateTime? ekhniiSongolt,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OgnooSongokhSheet(ekhniiSongolt: ekhniiSongolt),
    );
  }

  @override
  State<OgnooSongokhSheet> createState() => _OgnooSongokhSheetState();
}

/// Цэвэрлэгээ хийлгэх боломжтой цагийн хязгаар.
const int _ekhlekhTsag = 9;
const int _duusakhTsag = 20;

/// Хэдэн хоногийн дараах хүртэл захиалж болох вэ.
const int _khonogiinToo = 14;

class _OgnooSongokhSheetState extends State<OgnooSongokhSheet> {
  late DateTime _songosonUdur;
  TimeOfDay? _songosonTsag;

  static const _garagiinNer = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
  static const _sariinNer = [
    '1-р сар',
    '2-р сар',
    '3-р сар',
    '4-р сар',
    '5-р сар',
    '6-р сар',
    '7-р сар',
    '8-р сар',
    '9-р сар',
    '10-р сар',
    '11-р сар',
    '12-р сар',
  ];

  @override
  void initState() {
    super.initState();
    final odoo = DateTime.now();
    final ekhnii = widget.ekhniiSongolt;
    // Өмнөх сонголт нь өнгөрсөн байвал өнөөдрөөс эхэлнэ.
    _songosonUdur = (ekhnii != null && !ekhnii.isBefore(_udriinEkhlel(odoo)))
        ? _udriinEkhlel(ekhnii)
        : _udriinEkhlel(odoo);
    if (ekhnii != null && !ekhnii.isBefore(odoo)) {
      _songosonTsag = TimeOfDay(hour: ekhnii.hour, minute: ekhnii.minute);
    }
  }

  DateTime _udriinEkhlel(DateTime o) => DateTime(o.year, o.month, o.day);

  /// Тухайн цаг сонгох боломжтой юу (өнөөдрийн өнгөрсөн цаг биш эсэх).
  bool _bolomjtoiTsag(TimeOfDay tsag) {
    final odoo = DateTime.now();
    if (_songosonUdur.isAfter(_udriinEkhlel(odoo))) return true;
    final uyeTsag = DateTime(
      _songosonUdur.year,
      _songosonUdur.month,
      _songosonUdur.day,
      tsag.hour,
      tsag.minute,
    );
    // Одооноос хойш дор хаяж 1 цагийн зайтай байхаар — тэр даруй ирж чадахгүй.
    return uyeTsag.isAfter(odoo.add(const Duration(hours: 1)));
  }

  List<TimeOfDay> get _tsaguud {
    final jagsaalt = <TimeOfDay>[];
    for (var tsag = _ekhlekhTsag; tsag <= _duusakhTsag; tsag++) {
      jagsaalt.add(TimeOfDay(hour: tsag, minute: 0));
      if (tsag != _duusakhTsag) {
        jagsaalt.add(TimeOfDay(hour: tsag, minute: 30));
      }
    }
    return jagsaalt;
  }

  String _khoyorOron(int t) => t.toString().padLeft(2, '0');

  String _udriinTeksts(DateTime udur) {
    final odoo = _udriinEkhlel(DateTime.now());
    final zuruu = udur.difference(odoo).inDays;
    if (zuruu == 0) return 'Өнөөдөр';
    if (zuruu == 1) return 'Маргааш';
    if (zuruu == 2) return 'Нөгөөдөр';
    return '${_sariinNer[udur.month - 1]} ${udur.day}';
  }

  @override
  Widget build(BuildContext context) {
    final udruud = List.generate(
      _khonogiinToo,
      (i) => _udriinEkhlel(DateTime.now()).add(Duration(days: i)),
    );
    final songoltBelen = _songosonTsag != null;

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Чирэх бариул
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
              decoration: BoxDecoration(
                color: context.textSecondaryColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            child: Text(
              'Хэзээ цэвэрлүүлэх вэ?',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // ── Огнооны зурвас ──────────────────────────────────────────────
          SizedBox(
            height: 74.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: udruud.length,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (_, i) {
                final udur = udruud[i];
                final songogdson = udur == _songosonUdur;
                return _UdriinNudee(
                  garag: _garagiinNer[udur.weekday - 1],
                  udur: udur.day,
                  songogdson: songogdson,
                  onTap: () {
                    setState(() {
                      _songosonUdur = udur;
                      // Өдөр солиход сонгосон цаг боломжгүй болж мэднэ.
                      if (_songosonTsag != null &&
                          !_bolomjtoiTsag(_songosonTsag!)) {
                        _songosonTsag = null;
                      }
                    });
                  },
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
            child: Text(
              _udriinTeksts(_songosonUdur),
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Цагийн нүднүүд ──────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _tsaguud.map((tsag) {
                  final bolomjtoi = _bolomjtoiTsag(tsag);
                  final songogdson =
                      _songosonTsag?.hour == tsag.hour &&
                      _songosonTsag?.minute == tsag.minute;
                  return _TsagiinNudee(
                    shoshgo:
                        '${_khoyorOron(tsag.hour)}:${_khoyorOron(tsag.minute)}',
                    songogdson: songogdson,
                    bolomjtoi: bolomjtoi,
                    onTap: bolomjtoi
                        ? () => setState(() => _songosonTsag = tsag)
                        : null,
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: songoltBelen
                    ? () => Navigator.pop(
                        context,
                        DateTime(
                          _songosonUdur.year,
                          _songosonUdur.month,
                          _songosonUdur.day,
                          _songosonTsag!.hour,
                          _songosonTsag!.minute,
                        ),
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  disabledBackgroundColor: context.textSecondaryColor
                      .withValues(alpha: 0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  songoltBelen
                      ? '${_udriinTeksts(_songosonUdur)}, '
                            '${_khoyorOron(_songosonTsag!.hour)}:'
                            '${_khoyorOron(_songosonTsag!.minute)} — Сонгох'
                      : 'Цагаа сонгоно уу',
                  style: TextStyle(
                    color: songoltBelen
                        ? Colors.white
                        : context.textSecondaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Огнооны зурвас дахь нэг өдөр.
class _UdriinNudee extends StatelessWidget {
  const _UdriinNudee({
    required this.garag,
    required this.udur,
    required this.songogdson,
    required this.onTap,
  });

  final String garag;
  final int udur;
  final bool songogdson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56.w,
        decoration: BoxDecoration(
          color: songogdson ? AppColors.deepGreen : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: songogdson ? AppColors.deepGreen : context.borderColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              garag,
              style: TextStyle(
                color: songogdson
                    ? Colors.white.withValues(alpha: 0.85)
                    : context.textSecondaryColor,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '$udur',
              style: TextStyle(
                color: songogdson ? Colors.white : context.textPrimaryColor,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Цагийн нэг нүд.
class _TsagiinNudee extends StatelessWidget {
  const _TsagiinNudee({
    required this.shoshgo,
    required this.songogdson,
    required this.bolomjtoi,
    required this.onTap,
  });

  final String shoshgo;
  final bool songogdson;
  final bool bolomjtoi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Боломжгүй цагийг нуухгүй, бүдгэрүүлнэ — өдөр бүр ижил байрлалтай
    // байснаар нүд дасаж, хайх шаардлагагүй болно.
    final ungu = songogdson
        ? Colors.white
        : bolomjtoi
        ? context.textPrimaryColor
        : context.textSecondaryColor.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: songogdson
              ? AppColors.deepGreen
              : bolomjtoi
              ? context.cardBackgroundColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: songogdson
                ? AppColors.deepGreen
                : bolomjtoi
                ? context.borderColor
                : context.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          shoshgo,
          style: TextStyle(
            color: ungu,
            fontSize: 13.sp,
            fontWeight: songogdson ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
