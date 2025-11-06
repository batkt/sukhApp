import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
// TODO: Uncomment when notification feature is implemented
// import 'package:sukh_app/components/Notifications/notification.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/nekhemjlekh_cron_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class NuurKhuudas extends StatefulWidget {
  const NuurKhuudas({Key? key}) : super(key: key);

  @override
  State<NuurKhuudas> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<NuurKhuudas> {
  DateTime? paymentDate;
  bool isLoadingPaymentData = true;
  Geree? gereeData;
  double totalNiitTulbur = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // New variables for invoice tracking
  int? nekhemjlekhUusgekhOgnoo;
  DateTime? oldestUnpaidInvoiceDate;
  bool hasUnpaidInvoice = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void didUpdateWidget(NuurKhuudas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    try {
      final userId = await StorageService.getUserId();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (userId == null) {
        if (mounted) {
          setState(() {
            isLoadingPaymentData = false;
          });
        }
        return;
      }

      final gereeResponse = await ApiService.fetchGeree(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Сервертэй холбогдох хугацаа дууслаа');
        },
      );

      if (gereeResponse['jagsaalt'] != null &&
          gereeResponse['jagsaalt'] is List) {
        final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];

        if (gereeJagsaalt.isNotEmpty) {
          final firstContract = gereeJagsaalt[0];

          final geree = Geree.fromJson(firstContract);

          final nekhemjlekhResponse =
              await ApiService.fetchNekhemjlekhiinTuukh(
                gereeniiDugaar: geree.gereeniiDugaar,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw Exception('Сервертэй холбогдох хугацаа дууслаа');
                },
              );

          double total = 0.0;
          DateTime? unpaidInvoiceDate;
          bool foundUnpaid = false;

          if (nekhemjlekhResponse['jagsaalt'] != null &&
              nekhemjlekhResponse['jagsaalt'] is List) {
            final List<dynamic> nekhemjlekhJagsaalt =
                nekhemjlekhResponse['jagsaalt'];

            for (var invoice in nekhemjlekhJagsaalt) {
              final tuluv = invoice['tuluv'];

              if (tuluv == 'Төлөөгүй') {
                foundUnpaid = true;
                final niitTulbur = invoice['niitTulbur'];
                if (niitTulbur != null) {
                  total += (niitTulbur is int)
                      ? niitTulbur.toDouble()
                      : (niitTulbur as double);
                }

                final nekhemjlekhiinOgnoo = invoice['nekhemjlekhiinOgnoo'];
                if (nekhemjlekhiinOgnoo != null) {
                  try {
                    final invoiceDate = DateTime.parse(
                      nekhemjlekhiinOgnoo.toString(),
                    );
                    if (unpaidInvoiceDate == null ||
                        invoiceDate.isBefore(unpaidInvoiceDate)) {
                      unpaidInvoiceDate = invoiceDate;
                    }
                  } catch (e) {
                    print('Error parsing invoice date: $e');
                  }
                }
              }
            }
          }

          int? cronDay;
          if (baiguullagiinId != null) {
            try {
              final cronResponse =
                  await ApiService.fetchNekhemjlekhCron(
                    baiguullagiinId: baiguullagiinId,
                  ).timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      throw Exception('Сервертэй холбогдох хугацаа дууслаа');
                    },
                  );

              if (cronResponse['success'] == true &&
                  cronResponse['data'] != null &&
                  cronResponse['data'] is List &&
                  (cronResponse['data'] as List).isNotEmpty) {
                final cronData = NekhemjlekhCron.fromJson(
                  cronResponse['data'][0],
                );
                cronDay = cronData.nekhemjlekhUusgekhOgnoo;
              }
            } catch (e) {
              print('Error fetching cron data: $e');
            }
          }

          DateTime? parsedDate;
          final gereeniiOgnoo = firstContract['gereeniiOgnoo'];
          if (gereeniiOgnoo != null && gereeniiOgnoo.toString().isNotEmpty) {
            try {
              parsedDate = DateTime.parse(gereeniiOgnoo.toString());
            } catch (e) {
              print('Error parsing date: $e');
            }
          }

          if (mounted) {
            setState(() {
              paymentDate = parsedDate;
              gereeData = geree;
              totalNiitTulbur = total;
              hasUnpaidInvoice = foundUnpaid;
              oldestUnpaidInvoiceDate = unpaidInvoiceDate;
              nekhemjlekhUusgekhOgnoo = cronDay;
              isLoadingPaymentData = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoadingPaymentData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingPaymentData = false;
          });
        }
      }
    } catch (e) {
      print('Төлбөрийн мэдээлэл татхад алдаа гарлаа: $e');
      if (mounted) {
        setState(() {
          isLoadingPaymentData = false;
        });

        final errorMessage = e.toString().contains('Интернэт холболт')
            ? 'Интернэт холболт тасарсан байна'
            : e.toString().contains('хугацаа дууслаа')
            ? 'Сервертэй холбогдох хугацаа дууслаа'
            : 'Төлбөрийн мэдээлэл татахад алдаа гарлаа';

        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  int _calculateDaysDifference() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (hasUnpaidInvoice && oldestUnpaidInvoiceDate != null) {
      final invoiceDate = DateTime(
        oldestUnpaidInvoiceDate!.year,
        oldestUnpaidInvoiceDate!.month,
        oldestUnpaidInvoiceDate!.day,
      );
      return today.difference(invoiceDate).inDays;
    }

    if (nekhemjlekhUusgekhOgnoo != null) {
      DateTime nextInvoiceDate;

      if (today.day < nekhemjlekhUusgekhOgnoo!) {
        nextInvoiceDate = DateTime(
          today.year,
          today.month,
          nekhemjlekhUusgekhOgnoo!,
        );
      } else {
        int nextMonth = today.month + 1;
        int nextYear = today.year;

        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int invoiceDay = nekhemjlekhUusgekhOgnoo!;
        if (invoiceDay > daysInNextMonth) {
          invoiceDay = daysInNextMonth;
        }

        nextInvoiceDate = DateTime(nextYear, nextMonth, invoiceDay);
      }

      return nextInvoiceDate.difference(today).inDays;
    }

    if (paymentDate != null) {
      final payment = DateTime(
        paymentDate!.year,
        paymentDate!.month,
        paymentDate!.day,
      );
      return payment.difference(today).inDays;
    }

    return 0;
  }

  String _formatNumberWithComma(double number) {
    final parts = number.toStringAsFixed(0).split('.');
    final integerPart = parts[0];
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return integerPart.replaceAllMapped(regex, (match) => '${match[1]},');
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Padding(
                            padding: EdgeInsets.all(10.w),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 26.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showPaymentModal,
                              borderRadius: BorderRadius.circular(100),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.w,
                                  vertical: 15.h,
                                ),
                                child: Text(
                                  'Төлөх',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Нийт үлдэгдэл',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isLoadingPaymentData)
                        SizedBox(
                          height: 300.h,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFe6ff00),
                            ),
                          ),
                        )
                      else if (gereeData == null)
                        SizedBox(
                          height: 300.h,
                          child: Center(
                            child: Text(
                              'Төлбөрийн мэдээлэл олдсонгүй',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        )
                      else if (paymentDate == null)
                        SizedBox(
                          height: 300.h,
                          child: Center(
                            child: Text(
                              'Төлбөрийн огноо тохируулаагүй байна',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildPaymentDisplay(),

                      SizedBox(height: 12.h),

                      // Contract Information Container
                      if (gereeData != null)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D3748), Color(0xFF1A202C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Гэрээний мэдээлэл',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _buildInfoRow(
                                'Гэрээний дугаар',
                                gereeData!.gereeniiDugaar,
                              ),
                              SizedBox(height: 8.h),
                              _buildInfoRow('Барилгын нэр', gereeData!.bairNer),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoRow(
                                      'Давхар',
                                      gereeData!.davkhar.toString(),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildInfoRow(
                                      'Тоот',
                                      gereeData!.toot.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 12.h),
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

  Widget _buildPaymentDisplay() {
    final daysDifference = _calculateDaysDifference();
    final isOverdue = hasUnpaidInvoice && daysDifference > 0;
    final displayDays = daysDifference.abs();

    // Determine subtitle text
    String subtitleText;
    if (isOverdue) {
      subtitleText = 'өдөр хэтэрсэн';
    } else if (hasUnpaidInvoice) {
      subtitleText = 'өдөр үлдсэн';
    } else {
      subtitleText = 'өдрийн дараа';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress indicator with proper padding
          Padding(
            padding: EdgeInsets.all(10.w),
            child: SizedBox(
              width: 200.w,
              height: 200.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 15.w,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: CircularProgressIndicator(
                      value: isOverdue
                          ? 1.0
                          : (displayDays / 30).clamp(0.0, 1.0),
                      strokeWidth: 15.w,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverdue
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFFe6ff00),
                      ),
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayDays.toString(),
                        style: TextStyle(
                          color: isOverdue
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFe6ff00),
                          fontSize: 65.sp,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Payment date info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white70,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _getPaymentDateLabel(),
                  style: TextStyle(
                    color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If has unpaid invoice, show the unpaid invoice date
    if (hasUnpaidInvoice && oldestUnpaidInvoiceDate != null) {
      final year = oldestUnpaidInvoiceDate!.year;
      final month = oldestUnpaidInvoiceDate!.month;
      final day = oldestUnpaidInvoiceDate!.day;
      return 'Төлөх ёстой огноо: $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    if (nekhemjlekhUusgekhOgnoo != null) {
      DateTime nextInvoiceDate;

      if (today.day < nekhemjlekhUusgekhOgnoo!) {
        nextInvoiceDate = DateTime(
          today.year,
          today.month,
          nekhemjlekhUusgekhOgnoo!,
        );
      } else {
        int nextMonth = today.month + 1;
        int nextYear = today.year;

        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int invoiceDay = nekhemjlekhUusgekhOgnoo!;
        if (invoiceDay > daysInNextMonth) {
          invoiceDay = daysInNextMonth;
        }

        nextInvoiceDate = DateTime(nextYear, nextMonth, invoiceDay);
      }

      return 'Дараагийн нэхэмжлэх: ${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
    }

    // Fallback to payment date
    if (paymentDate != null) {
      final year = paymentDate!.year;
      final month = paymentDate!.month;
      final day = paymentDate!.day;
      return 'Төлбөрийн огноо: $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    return '';
  }

  void _showPaymentModal() {
    // Check if there's any amount to pay
    if (totalNiitTulbur <= 0) {
      showGlassSnackBar(
        context,
        message: 'Нэхэмжлэл үүсээгүй байна',
        icon: Icons.info_outline,
        iconColor: const Color(0xFFe6ff00),
        textColor: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a0e27),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөр төлөх',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price information panel
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Төлөх дүн',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/nekhemjlekh');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe6ff00),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Төлбөр төлөх',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
