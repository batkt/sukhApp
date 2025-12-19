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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Банк сонгох',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.textPrimaryColor,
                      size: 24.sp,
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
                            padding: EdgeInsets.all(20.w),
                            child: Text(
                              contactPhone.isNotEmpty
                                  ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
                                  : 'Банкны мэдээлэл олдсонгүй',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 16.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: 0.85,
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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: context.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bank logo
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.white : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.w),
                child: Image.network(
                  bank.logo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance,
                      color: context.textSecondaryColor,
                      size: 30.sp,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Bank name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                bank.description,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 11.sp,
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

