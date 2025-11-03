import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : const Color(0xFFe6ff00),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.red : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
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
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // TODO: Notification button - will be developed later
                        // Stack(
                        //   children: [
                        //     Container(
                        //       decoration: BoxDecoration(
                        //         color: Colors.white.withOpacity(0.1),
                        //         borderRadius: BorderRadius.circular(100),
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: Colors.black.withOpacity(0.25),
                        //             blurRadius: 12,
                        //             spreadRadius: 0,
                        //             offset: const Offset(0, 4),
                        //           ),
                        //         ],
                        //       ),
                        //       child: Material(
                        //         color: Colors.transparent,
                        //         child: InkWell(
                        //           onTap: () {
                        //             final RenderBox renderBox =
                        //                 context.findRenderObject() as RenderBox;
                        //             final position = renderBox.localToGlobal(
                        //               Offset.zero,
                        //             );
                        //
                        //             showGeneralDialog(
                        //               context: context,
                        //               barrierDismissible: true,
                        //               barrierLabel: '',
                        //               barrierColor: Colors.transparent,
                        //               transitionDuration: const Duration(
                        //                 milliseconds: 200,
                        //               ),
                        //               pageBuilder:
                        //                   (
                        //                     context,
                        //                     animation,
                        //                     secondaryAnimation,
                        //                   ) {
                        //                     return Material(
                        //                       color: Colors.transparent,
                        //                       child: Stack(
                        //                         children: [
                        //                           GestureDetector(
                        //                             onTap: () =>
                        //                                 Navigator.pop(context),
                        //                             child: Container(
                        //                               color: Colors.transparent,
                        //                             ),
                        //                           ),
                        //                           Positioned(
                        //                             top: position.dy + 60,
                        //                             right: 16,
                        //                             child: FadeTransition(
                        //                               opacity: animation,
                        //                               child:
                        //                                   const NotificationDropdown(),
                        //                             ),
                        //                           ),
                        //                         ],
                        //                       ),
                        //                     );
                        //                   },
                        //             );
                        //           },
                        //           borderRadius: BorderRadius.circular(100),
                        //           child: Padding(
                        //             padding: const EdgeInsets.all(7),
                        //             child: Icon(
                        //               Icons.notifications_rounded,
                        //               color: Colors.white.withOpacity(0.3),
                        //               size: 30,
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //     Positioned(
                        //       right: 8,
                        //       top: 8,
                        //       child: Container(
                        //         padding: const EdgeInsets.all(4),
                        //         decoration: const BoxDecoration(
                        //           color: Colors.red,
                        //           shape: BoxShape.circle,
                        //         ),
                        //         constraints: const BoxConstraints(
                        //           minWidth: 16,
                        //           minHeight: 16,
                        //         ),
                        //         child: const Text(
                        //           '3',
                        //           style: TextStyle(
                        //             color: Colors.white,
                        //             fontSize: 10,
                        //             fontWeight: FontWeight.bold,
                        //           ),
                        //           textAlign: TextAlign.center,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(width: 20),
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
                                final RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final position = renderBox.localToGlobal(
                                  Offset.zero,
                                );

                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  barrierColor: Colors.transparent,
                                  transitionDuration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  pageBuilder: (context, animation, secondaryAnimation) {
                                    return Material(
                                      color: Colors.transparent,
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                          Positioned(
                                            top: position.dy + 120,
                                            right: 16,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: Container(
                                                width: 200,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1a1a2e,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 20,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _buildProfileMenuItem(
                                                      context,
                                                      icon: Icons
                                                          .settings_outlined,
                                                      title: 'Тохиргоо',
                                                      onTap: () {
                                                        context.push(
                                                          '/tokhirgoo',
                                                        );
                                                      },
                                                    ),

                                                    const Divider(
                                                      color: Colors.white12,
                                                      height: 1,
                                                    ),
                                                    _buildProfileMenuItem(
                                                      context,
                                                      icon: Icons.logout,
                                                      title: 'Гарах',
                                                      onTap: () async {
                                                        // Store the router before popping
                                                        final router =
                                                            GoRouter.of(
                                                              context,
                                                            );

                                                        Navigator.pop(context);

                                                        final shouldLogout = await showDialog<bool>(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder:
                                                              (
                                                                BuildContext
                                                                dialogContext,
                                                              ) {
                                                                return AlertDialog(
                                                                  backgroundColor:
                                                                      const Color(
                                                                        0xFF1a1a2e,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          16,
                                                                        ),
                                                                  ),
                                                                  title: const Text(
                                                                    'Гарах',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  content: const Text(
                                                                    'Та системээс гарахдаа итгэлтэй байна уу?',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white70,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.of(
                                                                          dialogContext,
                                                                        ).pop(
                                                                          false,
                                                                        );
                                                                      },
                                                                      child: const Text(
                                                                        'Үгүй',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white70,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.of(
                                                                          dialogContext,
                                                                        ).pop(
                                                                          true,
                                                                        );
                                                                      },
                                                                      child: const Text(
                                                                        'Тийм',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.red,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                        );

                                                        if (shouldLogout ==
                                                            true) {
                                                          // Clear authentication data
                                                          await StorageService.clearAuthData();

                                                          // Navigate to login screen using the stored router
                                                          router.go(
                                                            '/newtrekh',
                                                          );
                                                        }
                                                      },
                                                      isLogout: true,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(100),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 26,
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

              Builder(
                builder: (context) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final screenWidth = MediaQuery.of(context).size.width;
                  // 720x1600 phone will have width ~360-400 and height ~700-850 (considering status bar)
                  final isSmallScreen = screenHeight < 900 || screenWidth < 400;
                  final isVerySmallScreen =
                      screenHeight < 700 || screenWidth < 380;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen
                          ? 12
                          : (isSmallScreen ? 16 : 16),
                    ),
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
                                fontSize: isVerySmallScreen
                                    ? 12
                                    : (isSmallScreen ? 14 : 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumberWithComma(totalNiitTulbur)}₮',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isVerySmallScreen
                                    ? 20
                                    : (isSmallScreen ? 22 : 26),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFe6ff00),
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
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVerySmallScreen
                                      ? 14
                                      : (isSmallScreen ? 16 : 20),
                                  vertical: isVerySmallScreen
                                      ? 6
                                      : (isSmallScreen ? 8 : 10),
                                ),
                                child: Text(
                                  'Төлөх',
                                  style: TextStyle(
                                    color: const Color(0xFF0a0e27),
                                    fontSize: isVerySmallScreen
                                        ? 12
                                        : (isSmallScreen ? 14 : 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(
                height: MediaQuery.of(context).size.height < 700 ? 8 : 12,
              ),

              // Payment Date Display Section with scrolling
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isLoadingPaymentData)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFe6ff00),
                            ),
                          ),
                        )
                      else if (gereeData == null)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: const Center(
                            child: Text(
                              'Төлбөрийн мэдээлэл олдсонгүй',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else if (paymentDate == null)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: const Center(
                            child: Text(
                              'Төлбөрийн огноо тохируулаагүй байна',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildPaymentDisplay(),

                      const SizedBox(height: 12),

                      // Contract Information Container
                      if (gereeData != null)
                        Builder(
                          builder: (context) {
                            final screenHeight = MediaQuery.of(
                              context,
                            ).size.height;
                            final screenWidth = MediaQuery.of(
                              context,
                            ).size.width;
                            final isSmallScreen =
                                screenHeight < 900 || screenWidth < 400;
                            final isVerySmallScreen =
                                screenHeight < 700 || screenWidth < 380;

                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 12 : 16,
                              ),
                              padding: EdgeInsets.all(
                                isVerySmallScreen
                                    ? 10
                                    : (isSmallScreen ? 12 : 15),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2D3748),
                                    Color(0xFF1A202C),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Гэрээний мэдээлэл',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isVerySmallScreen
                                              ? 14
                                              : (isSmallScreen ? 16 : 18),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? 10
                                            : (isSmallScreen ? 12 : 16),
                                      ),
                                      _buildInfoRow(
                                        'Гэрээний дугаар',
                                        gereeData!.gereeniiDugaar,
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? 6
                                            : (isSmallScreen ? 8 : 12),
                                      ),
                                      _buildInfoRow(
                                        'Барилгын нэр',
                                        gereeData!.bairNer,
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? 6
                                            : (isSmallScreen ? 8 : 12),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoRow(
                                              'Давхар',
                                              gereeData!.davkhar.toString(),
                                            ),
                                          ),
                                          SizedBox(
                                            width: isVerySmallScreen
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),
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
                                  SizedBox(
                                    height: isVerySmallScreen
                                        ? 10
                                        : (isSmallScreen ? 12 : 16),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height < 700
                            ? 8
                            : 12,
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

  Widget _buildPaymentDisplay() {
    final daysDifference = _calculateDaysDifference();
    final isOverdue = hasUnpaidInvoice && daysDifference > 0;
    final displayDays = daysDifference.abs();

    // Get screen dimensions to determine if we're on a small screen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 900 || screenWidth < 400;
    final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

    // Adjust sizes based on screen height
    final circleSize = isVerySmallScreen
        ? 160.0
        : (isSmallScreen ? 180.0 : 250.0);
    final circlePadding = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 20.0);
    final strokeWidth = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 18.0);
    final fontSize = isVerySmallScreen ? 50.0 : (isSmallScreen ? 60.0 : 80.0);
    final subtitleFontSize = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);
    final verticalPadding = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 20.0);
    final spacingAfterCircle = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 20.0);

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
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress indicator with proper padding
          Padding(
            padding: EdgeInsets.all(circlePadding),
            child: SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: isOverdue
                          ? 1.0
                          : (displayDays / 30).clamp(0.0, 1.0),
                      strokeWidth: strokeWidth,
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
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(
                        height: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      ),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: subtitleFontSize,
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

          SizedBox(height: spacingAfterCircle),

          // Payment date info
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 20),
              vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
            ),
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
                  size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                ),
                const SizedBox(width: 8),
                Text(
                  _getPaymentDateLabel(),
                  style: TextStyle(
                    color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
                    fontSize: isVerySmallScreen
                        ? 11
                        : (isSmallScreen ? 12 : 14),
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

    // If no unpaid invoice, show next invoice date
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Төлбөр төлөх',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price information panel
                  Container(
                    padding: const EdgeInsets.all(14),
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
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Төлбөр төлөх',
                        style: TextStyle(
                          fontSize: 16,
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
