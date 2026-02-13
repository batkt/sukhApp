import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class VATReceiptModal extends StatefulWidget {
  final VATReceipt receipt;

  const VATReceiptModal({super.key, required this.receipt});

  @override
  State<VATReceiptModal> createState() => _VATReceiptModalState();
}

class _VATReceiptModalState extends State<VATReceiptModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
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
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    children: [
                      // QR Code
                      if (widget.receipt.qrData.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: QrImageView(
                            data: widget.receipt.qrData,
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
                            if (widget.receipt.lottery != null)
                              _buildCopyableReceiptInfoRow(
                                context,
                                'Сугалааны дугаар:',
                                widget.receipt.lottery!,
                              ),
                            _buildReceiptInfoRow(
                              context,
                              'Огноо:',
                              widget.receipt.formattedDate,
                            ),
                            _buildCopyableReceiptInfoRow(
                              context,
                              'ДДТД:',
                              widget.receipt.id.isNotEmpty
                                  ? widget.receipt.id
                                  : (widget.receipt.receiptId ?? ''),
                            ),
                            Divider(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.08),
                              height: 20.h,
                            ),
                            _buildCopyableReceiptInfoRow(
                              context,
                              'Нийт дүн:',
                              widget.receipt.formattedAmount,
                              isBold: true,
                            ),
                            _buildReceiptInfoRow(
                              context,
                              'НӨАТ:',
                              '${widget.receipt.totalVAT.toStringAsFixed(2)}₮',
                            ),
                            if (widget.receipt.totalCityTax > 0)
                              _buildReceiptInfoRow(
                                context,
                                'Хотын татвар:',
                                '${widget.receipt.totalCityTax.toStringAsFixed(2)}₮',
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
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableReceiptInfoRow(
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
              fontSize: 12.sp,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Хуулагдлаа: $value'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: context.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.7),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 13.sp,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.copy,
                  size: 16.sp,
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
