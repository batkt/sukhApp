import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/screens/zochin_urikh/top_toast.dart';

Color _yashil(BuildContext context) =>
    context.isDarkMode ? AppColors.secondaryLight : AppColors.deepGreen;

class ZochinMedeelelPage extends StatefulWidget {
  final Map<String, dynamic> guest;
  final Map<String, dynamic>? zogsoolTuukh;
  final Map<String, dynamic>? quotaStatus;

  const ZochinMedeelelPage({
    super.key,
    required this.guest,
    this.zogsoolTuukh,
    this.quotaStatus,
  });

  @override
  State<ZochinMedeelelPage> createState() => _ZochinMedeelelPageState();
}

class _ZochinMedeelelPageState extends State<ZochinMedeelelPage> {
  bool _isDeleting = false;
  Map<String, dynamic>? _liveStatus;

  @override
  void initState() {
    super.initState();
    _fetchLiveStatus();
  }

  Future<void> _fetchLiveStatus() async {
    final urisanMashin = widget.guest['urisanMashin'];
    final urilgiinId = (urisanMashin != null ? urisanMashin['_id'] : widget.guest['_id'])?.toString();
    if (urilgiinId == null || urilgiinId.isEmpty) return;

    try {
      final res = await ApiService.fetchZochinUrilgiinTuluv(urilgiinId);
      if (mounted && res != null && res['data'] is Map) {
        setState(() {
          _liveStatus = Map<String, dynamic>.from(res['data'] as Map);
        });
      }
    } catch (_) {}
  }

  String _formatPlate(String raw) {
    final clean = raw.replaceAll(' ', '').trim().toUpperCase();
    if (clean.length == 7 && RegExp(r'^[0-9]{4}[А-ЯӨҮЁA-Z]{3}$').hasMatch(clean)) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return clean;
  }



  Future<void> _deleteInvitation() async {
    final urisanMashin = widget.guest['urisanMashin'];
    final id = (urisanMashin != null ? urisanMashin['_id'] : widget.guest['_id'])?.toString();
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Урилга устгах',
          style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor),
        ),
        content: Text(
          'Та энэ зочны урилгыг устгахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Үгүй', style: TextStyle(color: context.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Устгах', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId == null) throw Exception('Байгууллагын ID олдсонгүй');

      await ApiService.deleteZochinInvitation(
        id: id,
        baiguullagiinId: baiguullagiinId,
      );

      if (mounted) {
        TopToast.show(
          context,
          message: 'Урилга амжилттай устгагдлаа',
          type: TopToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        TopToast.show(
          context,
          message: friendlyError(e, fallback: 'Урилга устгаж чадсангүй'),
          type: TopToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final urisanMashin = widget.guest['urisanMashin'];
    final isHistoryItem = urisanMashin != null;

    final rawPlate = isHistoryItem
        ? (widget.guest['mashiniiDugaar'] ?? urisanMashin['urisanMashiniiDugaar'] ?? '')
        : (widget.guest['urisanMashiniiDugaar'] ?? widget.guest['mashiniiDugaar'] ?? '');
    final plateStr = _formatPlate(rawPlate.toString());

    final tuluv = isHistoryItem
        ? (urisanMashin['tuluv'] ?? 0)
        : (widget.guest['tuluv'] ?? 0);

    DateTime? entryTime;
    DateTime? exitTime;
    DateTime? inviteTime;

    final createdAt = isHistoryItem
        ? (urisanMashin['createdAt'] ?? widget.guest['createdAt'])
        : (widget.guest['createdAt'] ?? widget.guest['ognoo']);

    if (createdAt != null) {
      try {
        inviteTime = DateTime.parse(createdAt.toString()).toLocal();
      } catch (_) {}
    }

    if (widget.guest['tuukh'] is List && (widget.guest['tuukh'] as List).isNotEmpty) {
      final lastTuukh = (widget.guest['tuukh'] as List).last;
      if (lastTuukh is Map && lastTuukh['tsagiinTuukh'] is List && (lastTuukh['tsagiinTuukh'] as List).isNotEmpty) {
        final tsagList = lastTuukh['tsagiinTuukh'] as List;
        final firstTsag = tsagList.first;
        final lastTsag = tsagList.last;
        if (firstTsag is Map && firstTsag['orsonTsag'] != null) {
          try {
            entryTime = DateTime.parse(firstTsag['orsonTsag'].toString()).toLocal();
          } catch (_) {}
        }
        if (lastTsag is Map && lastTsag['garsanTsag'] != null) {
          try {
            exitTime = DateTime.parse(lastTsag['garsanTsag'].toString()).toLocal();
          } catch (_) {}
        }
      }
    }

    if (widget.zogsoolTuukh != null) {
      if (entryTime == null && widget.zogsoolTuukh!['orsonTsag'] != null) {
        try {
          entryTime = DateTime.parse(widget.zogsoolTuukh!['orsonTsag'].toString()).toLocal();
        } catch (_) {}
      }
      if (exitTime == null && widget.zogsoolTuukh!['garsanTsag'] != null) {
        try {
          exitTime = DateTime.parse(widget.zogsoolTuukh!['garsanTsag'].toString()).toLocal();
        } catch (_) {}
      }
    }

    if (_liveStatus != null && _liveStatus!['sessionuud'] is List) {
      final sessList = _liveStatus!['sessionuud'] as List;
      if (sessList.isNotEmpty) {
        final lastSess = sessList.last;
        if (lastSess is Map) {
          if (entryTime == null && lastSess['orsonTsag'] != null) {
            try {
              entryTime = DateTime.parse(lastSess['orsonTsag'].toString()).toLocal();
            } catch (_) {}
          }
          if (exitTime == null && lastSess['garsanTsag'] != null) {
            try {
              exitTime = DateTime.parse(lastSess['garsanTsag'].toString()).toLocal();
            } catch (_) {}
          }
        }
      }
    }

    final bool isWaiting = (tuluv == 0);
    final bool isEntered = (tuluv == 1) || (!isWaiting && entryTime != null && exitTime == null);
    final bool isExited = (tuluv == 2) || (!isWaiting && exitTime != null);

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (isEntered) {
      statusText = 'Зогсоолд орсон';
      statusColor = _yashil(context);
      statusBgColor = _yashil(context).withOpacity(0.12);
    } else if (isExited) {
      statusText = 'Зогсоолоос гарсан';
      statusColor = context.textSecondaryColor;
      statusBgColor = context.isDarkMode
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05);
    } else {
      statusText = 'Зогсоолд ороогүй';
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warning.withOpacity(0.12);
    }





    final formattedInviteDate = inviteTime != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(inviteTime)
        : '-';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Зочны мэдээлэл',
        actions: isWaiting
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: context.textPrimaryColor),
                  color: context.cardBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  onSelected: (val) {
                    if (val == 'delete') _deleteInvitation();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text('Устгах', style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon, plate, status badge
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: _yashil(context).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: _yashil(context),
                                size: 32,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            plateStr,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.w,
                                  height: 7.w,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Detail items card: Урьсан огноо
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: _buildDetailRow(context, 'Урьсан огноо', formattedInviteDate),
                    ),

                    SizedBox(height: 24.h),

                    // Stepper: Зочны төлөв
                    Text(
                      'Зочны төлөв',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    _buildStatusTimeline(
                      context,
                      isEntered: isEntered,
                      isExited: isExited,
                      isWaiting: isWaiting,
                      entryTimeStr: entryTime != null
                          ? DateFormat('yyyy.MM.dd HH:mm').format(entryTime)
                          : null,
                      exitTimeStr: exitTime != null
                          ? DateFormat('yyyy.MM.dd HH:mm').format(exitTime)
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom delete button (only for waiting cars)
            if (isWaiting)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : _deleteInvitation,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.isDarkMode
                        ? AppColors.error.withOpacity(0.12)
                        : const Color(0xFFFFF1F2),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isDeleting
                      ? SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                            SizedBox(width: 8.w),
                            Text(
                              'Устгах',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 13.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(
    BuildContext context, {
    required bool isEntered,
    required bool isExited,
    required bool isWaiting,
    String? entryTimeStr,
    String? exitTimeStr,
  }) {
    return Column(
      children: [
        // Step 1: Зогсоолд орсон
        _buildTimelineStep(
          context,
          isActive: isEntered || isExited,
          isCurrent: isEntered,
          title: 'Зогсоолд орсон',
          subtext: entryTimeStr ?? '-',
          isFirst: true,
          isLast: false,
        ),
        // Step 2: Зогсоолоос гарсан
        _buildTimelineStep(
          context,
          isActive: isExited,
          isCurrent: isExited,
          title: 'Зогсоолоос гарсан',
          subtext: exitTimeStr ?? '-',
          isFirst: false,
          isLast: false,
        ),
        // Step 3: Зогсоолд ороогүй
        _buildTimelineStep(
          context,
          isActive: isWaiting,
          isCurrent: isWaiting,
          title: 'Зогсоолд ороогүй',
          subtext: isWaiting ? 'Хүлээлгэнд байна' : '-',
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required bool isActive,
    required bool isCurrent,
    required String title,
    required String subtext,
    required bool isFirst,
    required bool isLast,
  }) {
    final activeColor = _yashil(context);
    final inactiveBorder = context.borderColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column with line
          Column(
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? activeColor
                      : (isActive ? context.textSecondaryColor : Colors.transparent),
                  border: Border.all(
                    color: isCurrent
                        ? activeColor
                        : (isActive ? context.textSecondaryColor : inactiveBorder),
                    width: 2,
                  ),
                ),
                child: isCurrent
                    ? Center(
                        child: Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.borderColor,
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          // Content
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? context.textPrimaryColor : context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
