import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class VATReceiptModal extends StatelessWidget {
  final VATReceipt receipt;

  const VATReceiptModal({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
      ),
      child: OptimizedGlass(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
        opacity: 0.06,
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
                      'НӨАТ-ын баримт',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textPrimaryColor, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // QR Code
                      if (receipt.qrData.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.w),
                          ),
                          child: QrImageView(
                            data: receipt.qrData,
                            version: QrVersions.auto,
                            size: 250.w,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                      // Receipt Info
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: context.accentBackgroundColor,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(color: context.borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (receipt.lottery != null)
                              _buildReceiptInfoRow(
                                context,
                                'Сугалааны дугаар:',
                                receipt.lottery!,
                              ),
                            _buildReceiptInfoRow(
                              context,
                              'Огноо:',
                              receipt.formattedDate,
                            ),
                            _buildReceiptInfoRow(
                              context,
                              'Регистр:',
                              receipt.merchantTin,
                            ),
                            Divider(color: context.borderColor, height: 24.h),
                            Text(
                              'Бараа, үйлчилгээ:',
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ...receipt.receipts
                                .expand((r) => r.items)
                                .map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            color: context.textPrimaryColor,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item.qty} ${item.measureUnit} × ${item.unitPrice}₮',
                                              style: TextStyle(
                                                color: context.textSecondaryColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                            Text(
                                              '${item.totalAmount}₮',
                                              style: TextStyle(
                                                color: context.textPrimaryColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            Divider(color: context.borderColor, height: 24.h),
                            _buildReceiptInfoRow(
                              context,
                              'Нийт дүн:',
                              receipt.formattedAmount,
                              isBold: true,
                            ),
                            _buildReceiptInfoRow(
                              context,
                              'НӨАТ:',
                              '${receipt.totalVAT.toStringAsFixed(2)}₮',
                            ),
                            if (receipt.totalCityTax > 0)
                              _buildReceiptInfoRow(
                                context,
                                'Хотын татвар:',
                                '${receipt.totalCityTax.toStringAsFixed(2)}₮',
                              ),
                            Divider(color: context.borderColor, height: 24.h),
                            Text(
                              'Төлбөр:',
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ...receipt.payments.map(
                              (payment) => _buildReceiptInfoRow(
                                context,
                                payment.code,
                                '${payment.paidAmount}₮ (${payment.status})',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

