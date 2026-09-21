import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/models/ger_buliin_gishuun_model.dart';
import 'package:sukh_app/services/ger_bul_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

/// Гэр бүлийн гишүүн урих цонх.
/// Амжилттай илгээвэл `true` буцаана.
Future<bool?> showGishuunUrikhSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GishuunUrikhSheet(),
  );
}

class _GishuunUrikhSheet extends StatefulWidget {
  const _GishuunUrikhSheet();

  @override
  State<_GishuunUrikhSheet> createState() => _GishuunUrikhSheetState();
}

class _GishuunUrikhSheetState extends State<_GishuunUrikhSheet> {
  final _formKey = GlobalKey<FormState>();
  final _utasController = TextEditingController();

  String _kholboo = 'Эхнэр';
  String _erkh = GishuuniiErkh.kharakhTuluk;
  bool _isLoading = false;
  bool _isSuccess = false;

  String _sentUtas = '';
  String _sentKholboo = '';
  String _sentErkh = '';

  static const List<String> _kholboonuud = [
    'Эхнэр',
    'Нөхөр',
    'Хүү',
    'Охин',
    'Аав',
    'Ээж',
    'Ах',
    'Эгч',
    'Дүү',
    'Бусад',
  ];

  @override
  void initState() {
    super.initState();
    _utasController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _utasController.dispose();
    super.dispose();
  }

  String? _getOperator(String phone) {
    final clean = phone.trim();
    if (clean.length < 2) return null;
    final prefix = clean.substring(0, 2);
    const mobicom = {'99', '95', '94', '85'};
    const unitel = {'88', '86', '89'};
    const skytel = {'90', '91', '96'};
    const gmobile = {'98', '93', '97'};

    if (mobicom.contains(prefix)) return 'Mobicom';
    if (unitel.contains(prefix)) return 'Unitel';
    if (skytel.contains(prefix)) return 'Skytel';
    if (gmobile.contains(prefix)) return 'G-Mobile';
    return null;
  }

  Color _getOperatorColor(String? op) {
    switch (op) {
      case 'Mobicom':
        return const Color(0xFFE50027);
      case 'Unitel':
        return const Color(0xFF00A859);
      case 'Skytel':
        return const Color(0xFF0072CE);
      case 'G-Mobile':
        return const Color(0xFFFF6F00);
      default:
        return AppColors.deepGreen;
    }
  }

  IconData _getKholbooIcon(String kholboo) {
    switch (kholboo) {
      case 'Эхнэр':
      case 'Нөхөр':
        return Icons.favorite_rounded;
      case 'Хүү':
      case 'Охин':
        return Icons.child_care_rounded;
      case 'Аав':
      case 'Ээж':
        return Icons.family_restroom_rounded;
      case 'Ах':
      case 'Эгч':
      case 'Дүү':
        return Icons.escalator_warning_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Future<void> _ilgeeye() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final utas = _utasController.text.trim();
    final kholboo = _kholboo;
    final erkh = _erkh;

    setState(() => _isLoading = true);
    try {
      await GerBulService.gishuunUriya(
        utas: utas,
        kholboo: kholboo,
        erkh: erkh,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _sentUtas = utas;
        _sentKholboo = kholboo;
        _sentErkh = erkh;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _copyInvitationInstructions() async {
    final text =
        'Сайн байна уу? Танд Sukh (AmarHome) апп-аар дамжуулан гэр бүлийн гишүүнээр нэгдэх урилга илгээлээ.\n\n'
        '1. Sukh аппликейшн татаж нээнэ үү.\n'
        '2. Утасны дугаараа ($_sentUtas) оруулан нэвтрэх хэсэгт орно.\n'
        '3. SMS-ээр очсон 4 оронтой баталгаажуулах кодоор баталгаажуулна уу.';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showGlassSnackBar(
      context,
      message: 'Урилгын заавар амжилттай хуулагдлаа',
      icon: Icons.copy_all_rounded,
      iconColor: AppColors.deepGreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161A1D) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _isSuccess ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final isDark = context.isDarkMode;
    final operator = _getOperator(_utasController.text);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: context.inputGrayColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Row
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add_rounded,
                    color: AppColors.deepGreen,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Гэр бүлийн гишүүн урих',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Танай тоотын мэдээлэлд хандах эрхтэй гишүүн нэмэх',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.textSecondaryColor,
                    size: 22.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // Info note
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.deepGreen.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sms_outlined,
                    color: AppColors.deepGreen,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Уригдсан дугаар руу 4 оронтой код очих бөгөөд 24 цагийн турш хүчинтэй байна.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF2C4A3E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Phone Field
            _buildSectionLabel('УТАСНЫ ДУГААР', isRequired: true),
            TextFormField(
              controller: _utasController,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: 1.2,
              ),
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return 'Утасны дугаар оруулна уу';
                if (clean.length != 8) return '8 оронтой дугаар оруулна уу';
                final prefix = clean.substring(0, 2);
                const valid = {
                  '80', '85', '86', '88', '89',
                  '90', '91', '93', '94', '95', '96', '97', '98', '99',
                  '70', '75', '77',
                };
                if (!valid.contains(prefix)) {
                  return 'Зөв монгол үүрэн утасны дугаар оруулна уу';
                }
                return null;
              },
              decoration: InputDecoration(
                counterText: '',
                hintText: '99112233',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: context.inputGrayColor,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(
                  Icons.phone_iphone_rounded,
                  size: 20.sp,
                  color: AppColors.deepGreen,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (operator != null)
                      Container(
                        margin: EdgeInsets.only(right: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getOperatorColor(operator).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          operator,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: _getOperatorColor(operator),
                          ),
                        ),
                      ),
                    if (_utasController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 16.sp,
                          color: context.inputGrayColor,
                        ),
                        onPressed: () => _utasController.clear(),
                      ),
                  ],
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: AppColors.deepGreen,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Relationship Selection
            _buildSectionLabel('ТАНЫ ЮУ БОЛОХ', isRequired: true),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _kholboonuud.map((item) {
                final isSelected = _kholboo == item;
                return InkWell(
                  onTap: () => setState(() => _kholboo = item),
                  borderRadius: BorderRadius.circular(24.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.deepGreen
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.deepGreen
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getKholbooIcon(item),
                          size: 14.sp,
                          color: isSelected
                              ? Colors.white
                              : context.textSecondaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),

            // Permissions Selection
            _buildSectionLabel('ГИШҮҮНИЙ ЭРХ', isRequired: true),
            _buildErkhOption(
              title: GishuuniiErkh.kharakhTuluk,
              badge: 'БҮРЭН ЭРХ',
              description:
                  'Байрны төлбөр харах, шууд төлөх, хүсэлт илгээх, хаалга онгойлгох',
              icon: Icons.payments_rounded,
              badgeColor: AppColors.deepGreen,
            ),
            SizedBox(height: 8.h),
            _buildErkhOption(
              title: GishuuniiErkh.kharakh,
              badge: 'ХЯЗГААРЛАГДМАЛ',
              description:
                  'Байрны нэхэмжлэх, үлдэгдэл, мэдэгдлийг зөвхөн харах (төлбөр төлөхгүй)',
              icon: Icons.visibility_rounded,
              badgeColor: Colors.blueGrey,
            ),
            SizedBox(height: 24.h),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.5.h,
              decoration: BoxDecoration(
                color: context.inputGrayColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Success Animated Icon
          Center(
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepGreen.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 46.sp,
                color: AppColors.deepGreen,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Урилга амжилттай илгээгдлээ!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '$_sentUtas дугаар луу 4 оронтой баталгаажуулах код SMS-ээр очлоо.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondaryColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),

          // Summary Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Утасны дугаар', _sentUtas),
                Divider(height: 16.h, color: isDark ? Colors.white10 : Colors.black12),
                _buildSummaryRow('Хамаарал', _sentKholboo),
                Divider(height: 16.h, color: isDark ? Colors.white10 : Colors.black12),
                _buildSummaryRow('Олгосон эрх', _sentErkh),
                Divider(height: 16.h, color: isDark ? Colors.white10 : Colors.black12),
                _buildSummaryRow('Хүчинтэй хугацаа', '24 цаг'),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // Copy instructions button
          OutlinedButton.icon(
            onPressed: _copyInvitationInstructions,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: BorderSide(
                color: AppColors.deepGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: Icon(
              Icons.copy_rounded,
              color: AppColors.deepGreen,
              size: 18.sp,
            ),
            label: Text(
              'Урилгын зааврыг хуулах',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'Болсон',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            color: context.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title, {bool isRequired = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 8.h),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.textSecondaryColor,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErkhOption({
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required Color badgeColor,
  }) {
    final isSelected = _erkh == title;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () => setState(() => _erkh = title),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepGreen.withValues(alpha: isDark ? 0.14 : 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppColors.deepGreen
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.deepGreen.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: isSelected
                    ? AppColors.deepGreen
                    : context.textSecondaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: context.textSecondaryColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.deepGreen : context.inputGrayColor,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _ilgeeye,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isLoading ? context.inputGrayColor : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.deepGreen.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: _isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Урилга илгээх',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
