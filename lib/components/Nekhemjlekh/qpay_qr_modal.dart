import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class QPayQRModal extends StatefulWidget {
  final String? qrImageOwnOrg;
  final String? qrImageWallet;
  final String? qrText; // For Wallet API - QR code text to generate QR from

  /// Async payment check (preferred). Return:
  /// - true: paid
  /// - false: not paid yet
  /// - null: unknown/error
  final Future<bool?> Function()? onCheckPaymentAsync;

  /// Legacy callback (kept for compatibility). If provided, the modal will
  /// show a generic "checked" message but can't know paid/unpaid.
  final VoidCallback? onCheckPayment;

  /// If true, modal auto-closes after a successful payment check (paid=true).
  final bool closeOnSuccess;

  const QPayQRModal({
    super.key,
    this.qrImageOwnOrg,
    this.qrImageWallet,
    this.qrText,
    this.onCheckPaymentAsync,
    this.onCheckPayment,
    this.closeOnSuccess = false,
  });

  @override
  State<QPayQRModal> createState() => _QPayQRModalState();
}

class _QPayQRModalState extends State<QPayQRModal> {
  bool _isChecking = false;
  bool? _paidResult;
  String? _resultMessage;

  Future<void> _handleCheckPayment() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _resultMessage = null;
      _paidResult = null;
    });

    bool? result;
    try {
      if (widget.onCheckPaymentAsync != null) {
        result = await widget.onCheckPaymentAsync!.call();
      } else {
        // Legacy
        widget.onCheckPayment?.call();
        result = null;
      }
    } catch (_) {
      result = null;
    }

    if (!mounted) return;

    setState(() {
      _paidResult = result;
      if (result == true) {
        _resultMessage = 'Төлбөр амжилттай төлөгдлөө';
      } else if (result == false) {
        _resultMessage = 'Төлбөр төлөгдөөгүй байна';
      } else {
        _resultMessage = 'Төлбөр шалгалаа. Жагсаалтаас дахин шалгана уу.';
      }
      _isChecking = false;
    });

    if (result == true && widget.closeOnSuccess) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _buildQRCode(String? qrText, String? qrImage, {double size = 250}) {
    if (qrText != null && qrText.isNotEmpty) {
      // Generate QR code from text
      return QrImageView(
        data: qrText,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    } else if (qrImage != null && qrImage.isNotEmpty) {
      // Show QR image (base64 or URL)
      try {
        // Try to decode as base64 first
        return Image.memory(
          base64Decode(qrImage),
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } catch (e) {
        // If not base64, try as URL
        return Image.network(
          qrImage,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasOwnOrg =
        widget.qrImageOwnOrg != null && widget.qrImageOwnOrg!.isNotEmpty;
    final hasWallet =
        widget.qrImageWallet != null && widget.qrImageWallet!.isNotEmpty;
    final hasQrText = widget.qrText != null && widget.qrText!.isNotEmpty;

    if (!hasOwnOrg && !hasWallet && !hasQrText) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR код олдсонгүй',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text('Хаах', style: TextStyle(fontSize: 11.sp)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QPay хэтэвч QR код',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14.h),
            // Show 2 QR codes side by side if both exist, otherwise show single
            if (hasOwnOrg && (hasWallet || hasQrText))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // OWN_ORG QR
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Орон сууцны төлбөр',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: _buildQRCode(null, widget.qrImageOwnOrg, size: 130.w),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // WALLET QR
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Хэтэвчний төлбөр',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: _buildQRCode(
                            widget.qrText,
                            widget.qrImageWallet,
                            size: 130.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Single QR code
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: _buildQRCode(
                  widget.qrText,
                  hasOwnOrg ? widget.qrImageOwnOrg : widget.qrImageWallet,
                  size: 200.w,
                ),
              ),
            SizedBox(height: 14.h),
            Text(
              'QPay апп-аараа QR кодыг уншуулна уу',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
            if (_resultMessage != null) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (_paidResult == true)
                      ? Colors.green.withOpacity(0.12)
                      : (_paidResult == false)
                      ? Colors.red.withOpacity(0.12)
                      : (context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8F8F8)),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: (_paidResult == true)
                        ? Colors.green.withOpacity(0.35)
                        : (_paidResult == false)
                        ? Colors.red.withOpacity(0.35)
                        : (context.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
            if (widget.onCheckPaymentAsync != null ||
                widget.onCheckPayment != null) ...[
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleCheckPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isChecking
                      ? SizedBox(
                          height: 16.h,
                          width: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Төлбөр шалгах',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Хаах',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
