import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';

class UtilityCodeInputPage extends StatefulWidget {
  const UtilityCodeInputPage({super.key});

  @override
  State<UtilityCodeInputPage> createState() => _UtilityCodeInputPageState();
}

class _UtilityCodeInputPageState extends State<UtilityCodeInputPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _searchAndAdd() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showGlassSnackBar(context, message: 'Хэрэглэгчийн кодоо оруулна уу', icon: Icons.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.findBillingByBillerAndCustomerCode(
        billerCode: 'ONLINE',
        customerCode: code,
      );

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          Map<String, dynamic> billingData;
          
          if (data is List) {
            if (data.isEmpty) throw Exception('Биллинг олдсонгүй');
            billingData = Map<String, dynamic>.from(data[0]);
          } else {
            billingData = Map<String, dynamic>.from(data);
          }

          // Save the billing to wallet
          await ApiService.saveWalletBilling(
            billingName: billingData['billingName'] ?? billingData['customerName'] ?? 'Онлайн биллинг',
            customerId: billingData['customerId']?.toString(),
            customerCode: billingData['customerCode']?.toString() ?? code,
          );

          if (mounted) {
            showGlassSnackBar(
              context, 
              message: 'Биллинг амжилттай нэмэгдлээ', 
              icon: Icons.check_circle, 
              iconColor: Colors.green
            );
            Navigator.of(context).pop(true); // Return success
            Navigator.of(context).pop(true); // Pop back to billing list
          }
        } else {
          showGlassSnackBar(context, message: response['message'] ?? 'Биллинг олдсонгүй', icon: Icons.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, message: e.toString().replaceFirst('Exception: ', ''), icon: Icons.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildStandardAppBar(context, title: 'Онлайн биллер'),
      body: CustomPaint(
        painter: SharedBgPainter(isDark: isDark, brandColor: AppColors.deepGreen),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48.h),
                Text(
                  'Хэрэглэгчийн код оруулах',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Та төлбөр төлөх үйлчилгээнийхээ хэрэглэгчийн кодыг оруулж хайна уу.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Жишээ: 123456',
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(20.w),
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchAndAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(18.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: _isLoading 
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Хайж нэмэх', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
