import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/tseverlegee/ognoo_songokh_sheet.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/tseverlegee_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Цэвэрлэгээ захиалах маягт.
///
/// Одоогоор ганц үйлчилгээтэй (Өрхийн цэвэрлэгээ) тул түүнийг сонгосон
/// байдлаар харуулаад, хэрэглэгчээс зөвхөн утас, хэзээ, нэмэлт мэдээллийг
/// асууна. Захиалга нь `POST /tseverlegee` руу шууд явж, админ талд "Шинэ"
/// төлөвтэйгээр гарч ирнэ.
class TseverlegeePage extends StatefulWidget {
  const TseverlegeePage({super.key});

  @override
  State<TseverlegeePage> createState() => _TseverlegeePageState();
}

class _TseverlegeePageState extends State<TseverlegeePage> {
  final _utasController = TextEditingController();
  final _nemelttController = TextEditingController();
  final _maygtTulkhuur = GlobalKey<FormState>();

  DateTime? _khusesenOgnoo;
  bool _yavuulj = false;

  @override
  void initState() {
    super.initState();
    _utasPrefill();
  }

  /// Нэвтрэхэд ашигласан дугаарыг нь урьдчилж бөглөнө — ихэнхдээ ижил дугаар
  /// байх тул хэрэглэгч дахин бичих шаардлагагүй.
  Future<void> _utasPrefill() async {
    final utas = await StorageService.getSavedPhoneNumber();
    if (!mounted || utas == null || utas.isEmpty) return;
    if (_utasController.text.isNotEmpty) return;
    _utasController.text = utas;
  }

  @override
  void dispose() {
    _utasController.dispose();
    _nemelttController.dispose();
    super.dispose();
  }

  Future<void> _ognooSongoyo() async {
    final songolt = await OgnooSongokhSheet.uzuuley(
      context,
      ekhniiSongolt: _khusesenOgnoo,
    );
    if (songolt == null || !mounted) return;
    setState(() => _khusesenOgnoo = songolt);
  }

  Future<void> _yavuulya() async {
    if (!(_maygtTulkhuur.currentState?.validate() ?? false)) return;

    if (_khusesenOgnoo == null) {
      _medegdye('Хэзээ цэвэрлүүлэхээ сонгоно уу', amjilttai: false);
      return;
    }
    // Огноо сонгоод удаан бодсон бол сонгосон мөч нь өнгөрсөн байж мэднэ.
    if (_khusesenOgnoo!.isBefore(DateTime.now())) {
      _medegdye('Өнгөрсөн цаг сонгосон байна', amjilttai: false);
      return;
    }

    setState(() => _yavuulj = true);
    try {
      await TseverlegeeService.zakhialgaUusgeye(
        utasniiDugaar: _utasController.text.trim(),
        khusesenOgnoo: _khusesenOgnoo!,
        nemelttMedeelel: _nemelttController.text.trim().isEmpty
            ? null
            : _nemelttController.text.trim(),
      );
      if (!mounted) return;
      _medegdye('Захиалга амжилттай илгээгдлээ', amjilttai: true);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _medegdye(
        e.toString().replaceAll('Exception: ', ''),
        amjilttai: false,
      );
    } finally {
      if (mounted) setState(() => _yavuulj = false);
    }
  }

  void _medegdye(String zurvas, {required bool amjilttai}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(zurvas),
        backgroundColor: amjilttai ? AppColors.deepGreen : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimaryColor,
            size: 18.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Цэвэрлэгээ',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _maygtTulkhuur,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TalbariinGarchig(text: 'Үйлчилгээний төрөл'),
              SizedBox(height: 8.h),
              const _UilchilgeeniiKhairtsag(),
              SizedBox(height: 20.h),

              const _TalbariinGarchig(text: 'Холбоо барих утас'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _utasController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13.sp,
                ),
                decoration: _talbariinZagvar(
                  context,
                  icon: Icons.phone_outlined,
                  sanuulga: '99001234',
                ),
                validator: (utga) {
                  final tseverkhen = (utga ?? '').trim();
                  if (tseverkhen.isEmpty) return 'Утасны дугаараа оруулна уу';
                  if (tseverkhen.length != 8) return '8 оронтой дугаар оруулна уу';
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              const _TalbariinGarchig(text: 'Хэзээ цэвэрлүүлэх вэ?'),
              SizedBox(height: 8.h),
              _OgnooniiTovch(
                ognoo: _khusesenOgnoo,
                onTap: _ognooSongoyo,
              ),
              SizedBox(height: 20.h),

              const _TalbariinGarchig(text: 'Нэмэлт мэдээлэл'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _nemelttController,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13.sp,
                ),
                decoration: _talbariinZagvar(
                  context,
                  sanuulga: 'Юу цэвэрлүүлэхээ бичнэ үү (заавал биш)',
                ),
              ),
              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _yavuulj ? null : _yavuulya,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    disabledBackgroundColor: AppColors.deepGreen.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _yavuulj
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Захиалга илгээх',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _talbariinZagvar(
    BuildContext context, {
    IconData? icon,
    required String sanuulga,
  }) {
    OutlineInputBorder khureeAvya(Color ungu, {double zuzaan = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: ungu, width: zuzaan),
        );

    return InputDecoration(
      hintText: sanuulga,
      hintStyle: TextStyle(
        color: context.textSecondaryColor.withValues(alpha: 0.6),
        fontSize: 13.sp,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: context.textSecondaryColor, size: 18.sp),
      filled: true,
      fillColor: context.cardBackgroundColor,
      counterText: '',
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      border: khureeAvya(context.borderColor),
      enabledBorder: khureeAvya(context.borderColor),
      focusedBorder: khureeAvya(AppColors.deepGreen, zuzaan: 1.4),
      errorBorder: khureeAvya(Colors.red.shade400),
      focusedErrorBorder: khureeAvya(Colors.red.shade400, zuzaan: 1.4),
    );
  }
}

class _TalbariinGarchig extends StatelessWidget {
  const _TalbariinGarchig({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Анхдагчаар сонгогдсон үйлчилгээ. Одоогоор ганц төрөлтэй тул сонголтгүй.
class _UilchilgeeniiKhairtsag extends StatelessWidget {
  const _UilchilgeeniiKhairtsag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.deepGreen, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.deepGreen,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Өрхийн цэвэрлэгээ',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Огноо, цаг сонгох талбар. Товшиход хуанли, дараа нь цагийн сонголт нээгдэнэ.
class _OgnooniiTovch extends StatelessWidget {
  const _OgnooniiTovch({required this.ognoo, required this.onTap});

  final DateTime? ognoo;
  final VoidCallback onTap;

  static String _khoyorOron(int too) => too.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final songogdson = ognoo != null;
    final bichveer = songogdson
        ? '${ognoo!.year}-${_khoyorOron(ognoo!.month)}-${_khoyorOron(ognoo!.day)}'
              '  ${_khoyorOron(ognoo!.hour)}:${_khoyorOron(ognoo!.minute)}'
        : 'Огноо, цаг сонгох';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: songogdson ? AppColors.deepGreen : context.borderColor,
            width: songogdson ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              color: songogdson
                  ? AppColors.deepGreen
                  : context.textSecondaryColor,
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                bichveer,
                style: TextStyle(
                  color: songogdson
                      ? context.textPrimaryColor
                      : context.textSecondaryColor.withValues(alpha: 0.6),
                  fontSize: 13.sp,
                  fontWeight: songogdson ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textSecondaryColor.withValues(alpha: 0.4),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}
