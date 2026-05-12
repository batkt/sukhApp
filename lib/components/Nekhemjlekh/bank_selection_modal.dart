import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BankSelectionModal extends StatelessWidget {
  final List<QPayBank> qpayBanks;
  final bool isLoadingQPay;
  final String contactPhone;
  final Function(QPayBank) onBankTap;
  final Function() onQPayWalletTap;

  const BankSelectionModal({
    super.key,
    required this.qpayBanks,
    required this.isLoadingQPay,
    this.contactPhone = '',
    required this.onBankTap,
    required this.onQPayWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        width: modalWidth,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 14.h),
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Банк сонгох',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.textSecondaryColor,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: isLoadingQPay
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.deepGreen,
                        strokeWidth: 3,
                      ),
                    )
                  : qpayBanks.isEmpty
                      ? _buildEmptyState(context)
                      : GridView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 40.h),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: qpayBanks.length,
                          itemBuilder: (context, index) {
                            final bank = qpayBanks[index];
                            return _buildQPayBankItem(context, bank, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_rounded, size: 64.sp, color: context.textSecondaryColor.withOpacity(0.2)),
            SizedBox(height: 20.h),
            Text(
              contactPhone.isNotEmpty
                  ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
                  : 'Банкны мэдээлэл олдсонгүй',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQPayBankItem(BuildContext context, QPayBank bank, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          if (bank.description.contains('qPay хэтэвч') ||
              bank.name.toLowerCase().contains('qpay wallet')) {
            onQPayWalletTap();
          } else {
            onBankTap(bank);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: context.borderColor.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(
                    _getLogoUrl(bank.logo),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.account_balance,
                        color: context.textSecondaryColor.withOpacity(0.5),
                        size: 24.sp,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  bank.description,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getLogoUrl(String url) {
    if (kIsWeb && url.isNotEmpty && url.startsWith('http')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
