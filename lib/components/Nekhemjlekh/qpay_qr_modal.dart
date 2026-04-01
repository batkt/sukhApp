import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class QPayQRModal extends StatefulWidget {
  final String? qrImageOwnOrg;
  final String? qrImageWallet;
  final String? qrText;
  final List<dynamic>? urls;

  final double? amount;
  final String? bankCode;
  final String? accountNo;
  final String? accountName;
  final String? description;

  final Future<bool?> Function()? onCheckPaymentAsync;

  final VoidCallback? onCheckPayment;

  final bool closeOnSuccess;

  final String? walletPaymentId;
  final String? invoiceNumber;

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
    this.walletPaymentId,
    this.invoiceNumber,
  });

  @override
  State<QPayQRModal> createState() => _QPayQRModalState();
}

class _QPayQRModalState extends State<QPayQRModal> {
  bool _isChecking = false;
  bool? _paidResult;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _startSocketListener();
  }

  void _startSocketListener() {
    if (widget.walletPaymentId != null) {
      SocketService.instance.listenForWalletQPayUpdates(widget.walletPaymentId!,
          (data) {
        if (data['status'] == 'PAID' && mounted) {
          _handlePaidViaSocket();
        }
      });
    } else if (widget.invoiceNumber != null) {
      SocketService.instance.listenForQPayUpdates(widget.invoiceNumber!, (data) {
        if (data['status'] == 'PAID' && mounted) {
          _handlePaidViaSocket();
        }
      });
    }
  }

  void _handlePaidViaSocket() {
    setState(() {
      _paidResult = true;
      _resultMessage = 'Төлбөр амжилттай төлөгдлөө';
    });
    if (widget.closeOnSuccess) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  Future<void> _handleCheckPayment() async {
    print('🖱️ [QPayModal] Check Payment button clicked');
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _resultMessage = null;
      _paidResult = null;
    });

    bool? result;
    try {
      if (widget.onCheckPaymentAsync != null) {
        print('⏳ [QPayModal] Calling onCheckPaymentAsync callback');
        result = await widget.onCheckPaymentAsync!.call();
        print('📊 [QPayModal] result from callback: $result');
      } else {
        // Legacy
        print('⚠️ [QPayModal] No onCheckPaymentAsync callback, calling legacy onCheckPayment');
        widget.onCheckPayment?.call();
        result = null;
      }
    } catch (e) {
      print('❌ [QPayModal] Error in _handleCheckPayment logic: $e');
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
    print('💬 [QPayModal] Status update: _paidResult=$_paidResult, _resultMessage=$_resultMessage');

    if (result == true && widget.closeOnSuccess) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true);
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
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final primaryColor = context.isDarkMode ? AppColors.deepGreenAccent : AppColors.deepGreen;

    if (!hasOwnOrg && !hasWallet && !hasQrText) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textPrimary, size: 24.sp),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(30.w),
                        decoration: BoxDecoration(
                          color: textPrimary.withOpacity(0.02),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.qr_code_scanner_rounded, size: 80.sp, color: textSecondary.withOpacity(0.1)),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Нэхэмжлэх олдсонгүй',
                        style: TextStyle(
                          color: textPrimary.withOpacity(0.8),
                          fontSize: 16.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 48.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Буцах', style: TextStyle(fontSize: 15.sp)),
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
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ТӨЛБӨР ТӨЛӨЛТ',
          style: TextStyle(
            color: textPrimary.withOpacity(0.9),
            fontSize: 13.sp,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
        child: Column(
          children: [
            _buildAmountHeader(context, textPrimary, textSecondary, primaryColor),
            SizedBox(height: 24.h),
            _buildQRSection(context, hasOwnOrg, hasWallet, hasQrText, textPrimary, textSecondary, primaryColor),
            SizedBox(height: 32.h),
            _buildBankAppSection(context, textPrimary, textSecondary, primaryColor),
            SizedBox(height: 24.h),
            _buildTransferDetails(context, textPrimary, textSecondary, primaryColor),
            if (_resultMessage != null) _buildStatusFeedback(context, textPrimary),
            SizedBox(height: 100.h),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context, primaryColor),
    );
  }

  Widget _buildModernHeader(BuildContext context, Color textPrimary, Color textSecondary) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20.sp),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            'ТӨЛБӨР ТӨЛӨЛТ',
            style: TextStyle(
              color: textPrimary.withOpacity(0.9),
              fontSize: 13.sp,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHeader(BuildContext context, Color textPrimary, Color textSecondary, Color primaryColor) {
    return Column(
      children: [
        Text(
          'ТӨЛӨХ ДҮН',
          style: TextStyle(
            color: textSecondary.withOpacity(0.4),
            fontSize: 10.sp,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          '${widget.amount != null ? NumberFormat('#,###').format(widget.amount) : '0'}₮',
          style: TextStyle(
            color: textPrimary,
            fontSize: 32.sp,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection(BuildContext context, bool hasOwnOrg, bool hasWallet, bool hasQrText, Color textPrimary, Color textSecondary, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: textPrimary.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          if (hasOwnOrg && (hasWallet || hasQrText))
            Row(
              children: [
                Expanded(child: _buildQRCard('Хэрэглээний төлбөр', widget.qrImageOwnOrg, null, textSecondary)),
                SizedBox(width: 16.w),
                Expanded(child: _buildQRCard('Хэтэвч', widget.qrImageWallet, widget.qrText, textSecondary)),
              ],
            )
          else
            _buildQRCard(
              hasOwnOrg ? 'Гүйлгээний QR' : 'QPay QR',
              hasOwnOrg ? widget.qrImageOwnOrg : widget.qrImageWallet,
              hasOwnOrg ? null : widget.qrText,
              textSecondary,
              isLarge: true,
            ),
          SizedBox(height: 20.h),
          Text(
            'QR кодыг банкны апп-аар уншуулна уу',
            style: TextStyle(
              color: textSecondary.withOpacity(0.5),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard(String label, String? image, String? text, Color textSecondary, {bool isLarge = false}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: textSecondary.withOpacity(0.4),
            fontSize: 9.sp,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: _buildQRCode(text, image, size: isLarge ? 200.w : 130.w),
        ),
      ],
    );
  }

  Widget _buildBankAppSection(BuildContext context, Color textPrimary, Color textSecondary, Color primaryColor) {
    if (widget.urls == null || widget.urls!.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'БАНКНЫ АПП-ААР НЭЭХ',
            style: TextStyle(
              color: textSecondary.withOpacity(0.4),
              fontSize: 10.sp,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.95,
          ),
          itemCount: widget.urls!.length,
          itemBuilder: (context, index) {
            final urlData = widget.urls![index] as Map<String, dynamic>;
            final logo = _getLogoUrl(urlData['logo']?.toString() ?? '');
            final name = urlData['name']?.toString() ?? '';
            final link = urlData['link']?.toString() ?? '';

            return _buildBankItem(context, name, logo, link, textPrimary, textSecondary);
          },
        ),
      ],
    );
  }

  Widget _buildBankItem(BuildContext context, String name, String logo, String link, Color textPrimary, Color textSecondary) {
    return GestureDetector(
      onTap: () async {
        if (link.isEmpty) return;
        final uri = Uri.tryParse(link);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (mounted) showGlassSnackBar(context, message: 'Апп нээхэд алдаа гарлаа');
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: textPrimary.withOpacity(0.03)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: logo.isNotEmpty
                    ? Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: 20.sp, color: Colors.grey))
                    : Icon(Icons.account_balance, size: 20.sp, color: Colors.grey),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              style: TextStyle(
                color: textPrimary.withOpacity(0.7),
                fontSize: 10.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDetails(BuildContext context, Color textPrimary, Color textSecondary, Color primaryColor) {
    if (widget.accountNo == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: textPrimary.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: textPrimary.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'БАНКНЫ ШИЛЖҮҮЛЭГ',
            style: TextStyle(color: textSecondary.withOpacity(0.4), fontSize: 9.sp, letterSpacing: 1.0),
          ),
          SizedBox(height: 16.h),
          _buildDetailTile(context, 'Банкны код', widget.bankCode ?? '', false, textPrimary, textSecondary),
          _buildDetailTile(context, 'Данс', widget.accountNo ?? '', true, textPrimary, textSecondary),
          _buildDetailTile(context, 'Хүлээн авагч', widget.accountName ?? '', false, textPrimary, textSecondary),
          _buildDetailTile(context, 'Утга', widget.description ?? '', true, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildDetailTile(BuildContext context, String label, String value, bool isCopyable, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 11.sp)),
          Row(
            children: [
              Text(value, style: TextStyle(color: textPrimary, fontSize: 12.sp)),
              if (isCopyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    showGlassSnackBar(context, message: 'Хууллаа');
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(Icons.copy_rounded, size: 14.sp, color: textSecondary.withOpacity(0.3)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFeedback(BuildContext context, Color textPrimary) {
    final isSuccess = _paidResult == true;
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1)),
        ),
        child: Text(
          _resultMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSuccess ? Colors.green : Colors.red,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, Color primaryColor) {
    if (widget.onCheckPaymentAsync == null && widget.onCheckPayment == null) return const SizedBox();

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 34.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(top: BorderSide(color: context.textPrimaryColor.withOpacity(0.02))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isChecking ? null : _handleCheckPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          child: _isChecking
              ? SizedBox(height: 20.w, width: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('ТӨЛБӨР ШАЛГАХ', style: TextStyle(fontSize: 14.sp, letterSpacing: 1.0)),
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
