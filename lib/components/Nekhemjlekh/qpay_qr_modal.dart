import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class QPayQRModal extends StatefulWidget {
  final String? qrImageOwnOrg;
  final String? qrImageWallet;
  final String? qrText; // For Wallet API - QR code text to generate QR from
  final List<dynamic>? urls; // For jump to bank apps

  /// Optional bank transfer details (useful for Wallet QPay flows)
  final double? amount;
  final String? bankCode;
  final String? accountNo;
  final String? accountName;
  final String? description;

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
    this.urls,
    this.amount,
    this.bankCode,
    this.accountNo,
    this.accountName,
    this.description,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
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
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header fixed at top
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  'QPay хэтэвч QR код',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6.h),
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
                                    child: _buildQRCode(
                                      null,
                                      widget.qrImageOwnOrg,
                                      size: 130.w,
                                    ),
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
                            hasOwnOrg
                                ? widget.qrImageOwnOrg
                                : widget.qrImageWallet,
                            size: 200.w,
                          ),
                        ),
                      if (widget.urls != null && widget.urls!.isNotEmpty) ...[
                        SizedBox(height: 14.h),
                        Text(
                          'Банкны апп-аар нээх',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: widget.urls!.length,
                          itemBuilder: (context, index) {
                            final urlData =
                                widget.urls![index] as Map<String, dynamic>;
                            final name = urlData['name']?.toString() ?? '';
                            final logo = _getLogoUrl(
                                urlData['logo']?.toString() ?? '');
                            final link = urlData['link']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () async {
                                if (link.isEmpty) return;
                                final uri = Uri.tryParse(link);
                                if (uri == null) return;
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    showGlassSnackBar(
                                      context,
                                      message: 'Апп-ыг нээхэд алдаа гарлаа',
                                      icon: Icons.error_outline,
                                      iconColor: Colors.red,
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: context.isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32.w,
                                      height: 32.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        child: logo.isNotEmpty
                                            ? Image.network(
                                                logo,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                  Icons.account_balance_rounded,
                                                  size: 16.sp,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : Icon(
                                                Icons.account_balance_rounded,
                                                size: 16.sp,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      SizedBox(height: 14.h),
                      Text(
                        'QPay апп эсвэл банкны апп-аараа QR кодыг уншуулж, доорх дансны мэдээллээр шилжүүлнэ үү.',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.bankCode != null ||
                          widget.accountNo != null ||
                          widget.accountName != null ||
                          widget.amount != null ||
                          widget.description != null) ...[
                        SizedBox(height: 12.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.03)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Банкны гүйлгээний мэдээлэл',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (widget.amount != null) ...[
                                _buildBankDetailRow(
                                  context,
                                  label: 'Төлөх дүн',
                                  value:
                                      '${widget.amount!.toStringAsFixed(2)}₮',
                                ),
                              ],
                              if (widget.bankCode != null &&
                                  widget.bankCode!.isNotEmpty)
                                _buildBankDetailRow(
                                  context,
                                  label: 'Банкны код',
                                  value: widget.bankCode!,
                                ),
                              if (widget.accountNo != null &&
                                  widget.accountNo!.isNotEmpty)
                                _buildBankDetailRow(
                                  context,
                                  label: 'Дансны дугаар',
                                  value: widget.accountNo!,
                                  isCopyable: true,
                                ),
                              if (widget.accountName != null &&
                                  widget.accountName!.isNotEmpty)
                                _buildBankDetailRow(
                                  context,
                                  label: 'Хүлээн авагч',
                                  value: widget.accountName!,
                                ),
                              if (widget.description != null &&
                                  widget.description!.isNotEmpty)
                                _buildBankDetailRow(
                                  context,
                                  label: 'Гүйлгээний утга',
                                  value: widget.description!,
                                  isCopyable: true,
                                ),
                            ],
                          ),
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: label == 'Төлөх дүн'
                          ? Colors.white
                          : context.textPrimaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCopyable)
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 14.sp,
                      color: AppColors.deepGreen,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      showGlassSnackBar(
                        context,
                        message: 'Хууллаа',
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.deepGreen,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to handle CORS issues for bank logos on Web
  String _getLogoUrl(String url) {
    if (kIsWeb && url.isNotEmpty && url.startsWith('http')) {
      // Use weserv.nl as an image proxy to bypass CORS on Web
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
