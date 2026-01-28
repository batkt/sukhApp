import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class VATReceiptModal extends StatelessWidget {
  final VATReceipt receipt;

  const VATReceiptModal({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
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
            padding: EdgeInsets.all(14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'НӨАТ-ын баримт',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
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
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                children: [
                  // QR Code
                  if (receipt.qrData.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: QrImageView(
                        data: receipt.qrData,
                        version: QrVersions.auto,
                        size: 180.w,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 14.h),
                  ],
                  // Receipt Info
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
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
                        Divider(
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                          height: 20.h,
                        ),
                        Text(
                          'Бараа, үйлчилгээ:',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...receipt.receipts
                            .expand((r) => r.items)
                            .map(
                              (item) => Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.qty} ${item.measureUnit} × ${item.unitPrice}₮',
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                        Text(
                                          '${item.totalAmount}₮',
                                          style: TextStyle(
                                            color: context.textPrimaryColor,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        Divider(
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                          height: 20.h,
                        ),
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
                        Divider(
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                          height: 20.h,
                        ),
                        Text(
                          'Төлбөр:',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
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
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 10.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

