import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class MedegdelDetailModal extends StatefulWidget {
  final Medegdel notification;

  const MedegdelDetailModal({super.key, required this.notification});

  @override
  State<MedegdelDetailModal> createState() => _MedegdelDetailModalState();
}

class _MedegdelDetailModalState extends State<MedegdelDetailModal> {
  late Medegdel _notification;
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _markAsReadAutomatically();
  }

  Future<void> _markAsReadAutomatically() async {
    if (_notification.kharsanEsekh) {
      return;
    }

    final turul = _notification.turul.toLowerCase();
    final isMedegdel = turul == 'app';

    if (!isMedegdel) {
      return;
    }

    if (_isMarkingAsRead) {
      return;
    }

    setState(() {
      _isMarkingAsRead = true;
    });

    try {
      await ApiService.markMedegdelAsRead(_notification.id);
      if (mounted) {
        setState(() {
          _notification = Medegdel(
            id: _notification.id,
            baiguullagiinId: _notification.baiguullagiinId,
            barilgiinId: _notification.barilgiinId,
            ognoo: _notification.ognoo,
            title: _notification.title,
            gereeniiDugaar: _notification.gereeniiDugaar,
            message: _notification.message,
            orshinSuugchGereeniiDugaar:
                _notification.orshinSuugchGereeniiDugaar,
            orshinSuugchId: _notification.orshinSuugchId,
            orshinSuugchNer: _notification.orshinSuugchNer,
            orshinSuugchUtas: _notification.orshinSuugchUtas,
            kharsanEsekh: true,
            turul: _notification.turul,
            createdAt: _notification.createdAt,
            updatedAt: _notification.updatedAt,
            status: _notification.status,
            tailbar: _notification.tailbar,
            repliedAt: _notification.repliedAt,
          );
          _isMarkingAsRead = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMarkingAsRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGomdol = _notification.turul.toLowerCase() == 'gomdol';
    final isSanal = _notification.turul.toLowerCase() == 'sanal';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.backgroundColor, context.surfaceColor],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            context.responsiveBorderRadius(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
              veryNarrow: 18,
            ),
          ),
          topRight: Radius.circular(
            context.responsiveBorderRadius(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
              veryNarrow: 18,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
              top: context.responsiveSpacing(
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 8,
              ),
            ),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.textPrimaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 2,
                  medium: 3,
                  large: 4,
                  tablet: 5,
                  veryNarrow: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: context.responsivePadding(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
              veryNarrow: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isGomdol
                        ? 'Гомдол'
                        : isSanal
                        ? 'Санал'
                        : 'Мэдэгдэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.textPrimaryColor,
                    size: 28.sp,
                  ),
                  onPressed: () {
                    final turul = _notification.turul.toLowerCase();
                    final isMedegdel = turul == 'app';
                    final wasMarkedAsRead =
                        _notification.kharsanEsekh && isMedegdel;
                    Navigator.pop(context, wasMarkedAsRead);
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(isGomdol, isSanal)),
        ],
      ),
    );
  }

  String _getDisplayTurul(String turul) {
    final turulLower = turul.toLowerCase();
    if (turulLower == 'gomdol') return 'Гомдол';
    if (turulLower == 'sanal') return 'Санал';
    if (turulLower == 'khariu' ||
        turulLower == 'hariu' ||
        turulLower == 'хариу')
      return 'Хариу';
    if (turulLower == 'app') return 'Мэдэгдэл';
    return turul; // Return original if not recognized
  }

  String _getStatusText(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    if (status == 'done') {
      return 'Шийдэгдсэн';
    }
    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан') {
      return 'Татгалзсан';
    }
    if (notification.hasReply) {
      return 'Хариу өгсөн';
    }
    return 'Хүлээгдэж байна';
  }

  bool _isStatusDone(Medegdel notification) {
    return notification.status?.toLowerCase() == 'done';
  }

  bool _isStatusRejected(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    return status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан';
  }

  Widget _buildContent(bool isGomdol, bool isSanal) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 22,
          veryNarrow: 12,
        ),
        vertical: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.textPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
              border: Border.all(
                color: _isStatusDone(_notification)
                    ? AppColors.success.withOpacity(0.3)
                    : context.textPrimaryColor.withOpacity(0.15),
                width: _isStatusDone(_notification) ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isGomdol
                        ? Colors.orange.withOpacity(0.15)
                        : isSanal
                        ? AppColors.secondaryAccent.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGomdol
                            ? Icons.report_problem
                            : isSanal
                            ? Icons.lightbulb_outline
                            : Icons.notifications,
                        size: 18.sp,
                        color: isGomdol
                            ? Colors.orange
                            : isSanal
                            ? AppColors.secondaryAccent
                            : AppColors.primary,
                      ),
                      SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                      Text(
                        _getDisplayTurul(_notification.turul),
                        style: TextStyle(
                          color: isGomdol
                              ? Colors.orange
                              : isSanal
                              ? AppColors.secondaryAccent
                              : AppColors.primary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isGomdol || isSanal) ...[
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _isStatusDone(_notification)
                          ? AppColors.success.withOpacity(0.15)
                          : _isStatusRejected(_notification)
                          ? AppColors.error.withOpacity(0.15)
                          : _notification.hasReply
                          ? AppColors.success.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isStatusDone(_notification)
                              ? Icons.check_circle
                              : _isStatusRejected(_notification)
                              ? Icons.cancel
                              : _notification.hasReply
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 16.sp,
                          color: _isStatusDone(_notification)
                              ? AppColors.success
                              : _isStatusRejected(_notification)
                              ? AppColors.error
                              : _notification.hasReply
                              ? AppColors.success
                              : Colors.orange,
                        ),
                        SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                        Text(
                          _getStatusText(_notification),
                          style: TextStyle(
                            color: _isStatusDone(_notification)
                                ? AppColors.success
                                : _isStatusRejected(_notification)
                                ? AppColors.error
                                : _notification.hasReply
                                ? AppColors.success
                                : Colors.orange,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Text(
              _notification.title,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: context.textPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
              border: Border.all(
                color: context.textPrimaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Text(
              _notification.message,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 15.sp,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (_notification.hasReply && (isGomdol || isSanal)) ...[
            SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success.withOpacity(0.12),
                    AppColors.success.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          color: AppColors.success,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Хариу',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _notification.tailbar!,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (_notification.repliedAt != null) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.textPrimaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14.sp,
                            color: context.inputGrayColor,
                          ),
                          SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                          Text(
                            'Хариу өгсөн: ${_formatDate(_notification.repliedAt!)}',
                            style: TextStyle(
                              color: context.inputGrayColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: context.textPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
              border: Border.all(
                color: _isStatusDone(_notification)
                    ? AppColors.success.withOpacity(0.3)
                    : context.textPrimaryColor.withOpacity(0.15),
                width: _isStatusDone(_notification) ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.textPrimaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Дэлгэрэнгүй',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _buildDetailRow(
                  'Огноо',
                  _notification.formattedDateTime,
                  Icons.calendar_today,
                ),
                if (_notification.gereeniiDugaar != null &&
                    _notification.gereeniiDugaar!.isNotEmpty)
                  _buildDetailRow(
                    'Гэрээний дугаар',
                    _notification.gereeniiDugaar!,
                    Icons.description,
                  ),
                if (_notification.orshinSuugchGereeniiDugaar != null &&
                    _notification.orshinSuugchGereeniiDugaar!.isNotEmpty)
                  _buildDetailRow(
                    'Оршин суугчийн гэрээний дугаар',
                    _notification.orshinSuugchGereeniiDugaar!,
                    Icons.person_outline,
                  ),
                if (_notification.orshinSuugchNer != null &&
                    _notification.orshinSuugchNer!.isNotEmpty)
                  _buildDetailRow(
                    'Оршин суугчийн нэр',
                    _notification.orshinSuugchNer!,
                    Icons.person,
                  ),
                if (_notification.orshinSuugchUtas != null &&
                    _notification.orshinSuugchUtas!.isNotEmpty)
                  _buildDetailRow(
                    'Утасны дугаар',
                    _notification.orshinSuugchUtas!,
                    Icons.phone,
                  ),
                _buildDetailRow(
                  'Төлөв',
                  _getStatusText(_notification),
                  _isStatusDone(_notification)
                      ? Icons.check_circle
                      : _isStatusRejected(_notification)
                      ? Icons.cancel
                      : _notification.hasReply
                      ? Icons.check_circle
                      : Icons.pending,
                ),
                _buildDetailRow(
                  'Үүсгэсэн огноо',
                  _formatDate(_notification.createdAt),
                  Icons.access_time,
                ),
                if (_notification.updatedAt != _notification.createdAt)
                  _buildDetailRow(
                    'Шинэчлэгдсэн огноо',
                    _formatDate(_notification.updatedAt),
                    Icons.update,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.textPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.textPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(icon, size: 18.sp, color: context.textPrimaryColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.inputGrayColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class MedegdelDetailScreen extends StatefulWidget {
  final Medegdel notification;

  const MedegdelDetailScreen({super.key, required this.notification});

  @override
  State<MedegdelDetailScreen> createState() => _MedegdelDetailScreenState();
}

class _MedegdelDetailScreenState extends State<MedegdelDetailScreen> {
  late Medegdel _notification;
  bool _isMarkingAsRead = false;

  String _getDisplayTurul(String turul) {
    final turulLower = turul.toLowerCase();
    if (turulLower == 'gomdol') return 'Гомдол';
    if (turulLower == 'sanal') return 'Санал';
    if (turulLower == 'khariu' ||
        turulLower == 'hariu' ||
        turulLower == 'хариу')
      return 'Хариу';
    if (turulLower == 'app') return 'Мэдэгдэл';
    return turul; // Return original if not recognized
  }

  String _getStatusText(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    if (status == 'done') {
      return 'Шийдэгдсэн';
    }
    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан') {
      return 'Татгалзсан';
    }
    if (notification.hasReply) {
      return 'Хариу өгсөн';
    }
    return 'Хүлээгдэж байна';
  }

  bool _isStatusDone(Medegdel notification) {
    return notification.status?.toLowerCase() == 'done';
  }

  bool _isStatusRejected(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    return status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан';
  }

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _markAsReadAutomatically();
  }

  Future<void> _markAsReadAutomatically() async {
    if (_notification.kharsanEsekh) {
      return;
    }

    final turul = _notification.turul.toLowerCase();
    final isMedegdel = turul == 'app';

    if (!isMedegdel) {
      return;
    }

    if (_isMarkingAsRead) {
      return;
    }

    setState(() {
      _isMarkingAsRead = true;
    });

    try {
      await ApiService.markMedegdelAsRead(_notification.id);
      if (mounted) {
        setState(() {
          _notification = Medegdel(
            id: _notification.id,
            baiguullagiinId: _notification.baiguullagiinId,
            barilgiinId: _notification.barilgiinId,
            ognoo: _notification.ognoo,
            title: _notification.title,
            gereeniiDugaar: _notification.gereeniiDugaar,
            message: _notification.message,
            orshinSuugchGereeniiDugaar:
                _notification.orshinSuugchGereeniiDugaar,
            orshinSuugchId: _notification.orshinSuugchId,
            orshinSuugchNer: _notification.orshinSuugchNer,
            orshinSuugchUtas: _notification.orshinSuugchUtas,
            kharsanEsekh: true,
            turul: _notification.turul,
            createdAt: _notification.createdAt,
            updatedAt: _notification.updatedAt,
            status: _notification.status,
            tailbar: _notification.tailbar,
            repliedAt: _notification.repliedAt,
          );
          _isMarkingAsRead = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMarkingAsRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGomdol = _notification.turul.toLowerCase() == 'gomdol';
    final isSanal = _notification.turul.toLowerCase() == 'sanal';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final turul = _notification.turul.toLowerCase();
          final isMedegdel = turul == 'app';
          final wasMarkedAsRead = _notification.kharsanEsekh && isMedegdel;
          if (Navigator.canPop(context)) {
            Navigator.pop(context, wasMarkedAsRead);
          } else {
            context.pop(wasMarkedAsRead);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.backgroundColor, context.surfaceColor],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: context.responsivePadding(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
              veryNarrow: 12,
            ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: context.textPrimaryColor,
                          size: 28.sp,
                        ),
                        onPressed: () {
                          final turul = _notification.turul.toLowerCase();
                          final isMedegdel = turul == 'app';
                          final wasMarkedAsRead =
                              _notification.kharsanEsekh && isMedegdel;
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, wasMarkedAsRead);
                          } else {
                            context.pop(wasMarkedAsRead);
                          }
                        },
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          isGomdol
                              ? 'Гомдол'
                              : isSanal
                              ? 'Санал'
                              : 'Мэдэгдэл',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: context.responsivePadding(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
              veryNarrow: 12,
            ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
                            border: Border.all(
                              color: _isStatusDone(_notification)
                                  ? AppColors.success.withOpacity(0.3)
                                  : context.textPrimaryColor.withOpacity(0.15),
                              width: _isStatusDone(_notification) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isGomdol
                                      ? Colors.orange.withOpacity(0.15)
                                      : isSanal
                                      ? AppColors.secondaryAccent.withOpacity(
                                          0.15,
                                        )
                                      : AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGomdol
                                          ? Icons.report_problem
                                          : isSanal
                                          ? Icons.lightbulb_outline
                                          : Icons.notifications,
                                      size: 18.sp,
                                      color: isGomdol
                                          ? Colors.orange
                                          : isSanal
                                          ? AppColors.secondaryAccent
                                          : AppColors.primary,
                                    ),
                                    SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                                    Text(
                                      _getDisplayTurul(_notification.turul),
                                      style: TextStyle(
                                        color: isGomdol
                                            ? Colors.orange
                                            : isSanal
                                            ? AppColors.secondaryAccent
                                            : AppColors.primary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isGomdol || isSanal) ...[
                                SizedBox(width: 10.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isStatusDone(_notification)
                                        ? AppColors.success.withOpacity(0.15)
                                        : _isStatusRejected(_notification)
                                        ? AppColors.error.withOpacity(0.15)
                                        : _notification.hasReply
                                        ? AppColors.success.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isStatusDone(_notification)
                                            ? Icons.check_circle
                                            : _isStatusRejected(_notification)
                                            ? Icons.cancel
                                            : _notification.hasReply
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        size: 16.sp,
                                        color: _isStatusDone(_notification)
                                            ? AppColors.success
                                            : _isStatusRejected(_notification)
                                            ? AppColors.error
                                            : _notification.hasReply
                                            ? AppColors.success
                                            : Colors.orange,
                                      ),
                                      SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                                      Text(
                                        _getStatusText(_notification),
                                        style: TextStyle(
                                          color: _isStatusDone(_notification)
                                              ? AppColors.success
                                              : _isStatusRejected(_notification)
                                              ? AppColors.error
                                              : _notification.hasReply
                                              ? AppColors.success
                                              : Colors.orange,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            _notification.title,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
                            border: Border.all(
                              color: context.textPrimaryColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _notification.message,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 15.sp,
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (_notification.hasReply &&
                            (isGomdol || isSanal)) ...[
                          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
                          Container(
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.success.withOpacity(0.12),
                                  AppColors.success.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      ),
                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.reply_rounded,
                                        color: AppColors.success,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Хариу',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  _notification.tailbar!,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: 14.sp,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (_notification.repliedAt != null) ...[
                                  SizedBox(height: 14.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.textPrimaryColor
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8.w),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14.sp,
                                          color: context.inputGrayColor,
                                        ),
                                        SizedBox(
                        width: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                                        Text(
                                          'Хариу өгсөн: ${_formatDate(_notification.repliedAt!)}',
                                          style: TextStyle(
                                            color: context.inputGrayColor,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),
                        Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
                            border: Border.all(
                              color: _isStatusDone(_notification)
                                  ? AppColors.success.withOpacity(0.3)
                                  : context.textPrimaryColor.withOpacity(0.15),
                              width: _isStatusDone(_notification) ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: context.textPrimaryColor,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Дэлгэрэнгүй',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18.h),
                              _buildDetailRow(
                                'Огноо',
                                _notification.formattedDateTime,
                                Icons.calendar_today,
                              ),
                              if (_notification.gereeniiDugaar != null &&
                                  _notification.gereeniiDugaar!.isNotEmpty)
                                _buildDetailRow(
                                  'Гэрээний дугаар',
                                  _notification.gereeniiDugaar!,
                                  Icons.description,
                                ),
                              if (_notification.orshinSuugchGereeniiDugaar !=
                                      null &&
                                  _notification
                                      .orshinSuugchGereeniiDugaar!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Оршин суугчийн гэрээний дугаар',
                                  _notification.orshinSuugchGereeniiDugaar!,
                                  Icons.person_outline,
                                ),
                              if (_notification.orshinSuugchNer != null &&
                                  _notification.orshinSuugchNer!.isNotEmpty)
                                _buildDetailRow(
                                  'Оршин суугчийн нэр',
                                  _notification.orshinSuugchNer!,
                                  Icons.person,
                                ),
                              if (_notification.orshinSuugchUtas != null &&
                                  _notification.orshinSuugchUtas!.isNotEmpty)
                                _buildDetailRow(
                                  'Утасны дугаар',
                                  _notification.orshinSuugchUtas!,
                                  Icons.phone,
                                ),
                              _buildDetailRow(
                                'Төлөв',
                                _getStatusText(_notification),
                                _isStatusDone(_notification)
                                    ? Icons.check_circle
                                    : _isStatusRejected(_notification)
                                    ? Icons.cancel
                                    : _notification.hasReply
                                    ? Icons.check_circle
                                    : Icons.pending,
                              ),
                              _buildDetailRow(
                                'Үүсгэсэн огноо',
                                _formatDate(_notification.createdAt),
                                Icons.access_time,
                              ),
                              if (_notification.updatedAt !=
                                  _notification.createdAt)
                                _buildDetailRow(
                                  'Шинэчлэгдсэн огноо',
                                  _formatDate(_notification.updatedAt),
                                  Icons.update,
                                ),
                            ],
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.textPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.textPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(icon, size: 18.sp, color: context.textPrimaryColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.inputGrayColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
