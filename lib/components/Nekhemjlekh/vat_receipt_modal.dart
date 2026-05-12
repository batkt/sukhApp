import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
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
  bool _showCopied = false;

  void _triggerCopied() {
    if (!mounted) return;
    setState(() => _showCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

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
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
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
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Column(
                            children: [
                              // Scanned Status Indicator
                               if (widget.receipt.id.isNotEmpty || (widget.receipt.receiptId?.isNotEmpty ?? false))
                                Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 16.sp),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'ИБаримт бүртгэгдсэн байна',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                        'СУГАЛААНЫ ДУГААР:',
                                        widget.receipt.lottery!,
                                      ),
                                    _buildReceiptInfoRow(
                                      context,
                                      'ОГНОО:',
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
                                      'НИЙТ ДҮН:',
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
                                        'ХОТЫН ТАТВАР:',
                                        '${widget.receipt.totalCityTax.toStringAsFixed(2)}₮',
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // Share button instead of print
                              SizedBox(
                                width: double.infinity,
                                height: 54.h,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Only copy lottery number as requested
                                    final lottery = widget.receipt.lottery ?? '';
                                    if (lottery.isNotEmpty) {
                                      Clipboard.setData(ClipboardData(text: lottery));
                                      _triggerCopied();
                                    }
                                  },
                                  icon: Icon(Icons.copy_rounded, size: 20.sp),
                                  label: Text(
                                    'СУГАЛААНЫ ДУГААР ХУУЛАХ',
                                    style: TextStyle(
                                      fontSize: 11.sp, 
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.deepGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Minimal Copied Pill
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showCopied ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.content_copy_rounded,
                          size: 14.sp,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Амжилттай хуулагдлаа',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 11.sp,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.visible,
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _triggerCopied();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 11.sp,
                        fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: context.textSecondaryColor.withOpacity(0.3),
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.content_copy_rounded,
                    size: 12.sp,
                    color: context.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
