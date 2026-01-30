import 'package:flutter/material.dart';
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
    // For tablets/iPads, limit width and center the modal
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return Center(
      child: Container(
        width: modalWidth,
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: isTablet
              ? BorderRadius.circular(16.r)
              : BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: isTablet
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
      child: Column(
        children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Банк сонгох',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.textSecondaryColor,
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Bank grid
            Expanded(
              child: isLoadingQPay
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.deepGreen,
                      ),
                    )
                  : qpayBanks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              contactPhone.isNotEmpty
                                  ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
                                  : 'Банкны мэдээлэл олдсонгүй',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 12.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: qpayBanks.length,
                          itemBuilder: (context, index) {
                            final bank = qpayBanks[index];
                            return _buildQPayBankItem(context, bank);
                          },
                        ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildQPayBankItem(BuildContext context, QPayBank bank) {
    return GestureDetector(
      onTap: () {
        // Check if it's qPay wallet - show QR code
        if (bank.description.contains('qPay хэтэвч') ||
            bank.name.toLowerCase().contains('qpay wallet')) {
          onQPayWalletTap();
        } else {
          onBankTap(bank);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: context.isDarkMode
                ? AppColors.deepGreen.withOpacity(0.15)
                : AppColors.deepGreen.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bank logo
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  bank.logo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance,
                      color: context.textSecondaryColor,
                      size: 22.sp,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6.h),
            // Bank name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                bank.description,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

