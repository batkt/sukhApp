import 'package:flutter/material.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
// TODO: Uncomment when notification feature is implemented
// import 'package:sukh_app/components/Notifications/notification.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/img/background_image.png'),
          fit: BoxFit.none,
          scale: 3,
        ),
      ),
      child: child,
    );
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

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        setState(() {
          isLoadingPaymentData = false;
        });
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
          if (nekhemjlekhResponse['jagsaalt'] != null &&
              nekhemjlekhResponse['jagsaalt'] is List) {
            final List<dynamic> nekhemjlekhJagsaalt =
                nekhemjlekhResponse['jagsaalt'];

            for (var invoice in nekhemjlekhJagsaalt) {
              final tuluv = invoice['tuluv'];
              // Only include invoices that are "Төлөөгүй" (unpaid)
              if (tuluv == 'Төлөөгүй') {
                final niitTulbur = invoice['niitTulbur'];
                if (niitTulbur != null) {
                  total += (niitTulbur is int)
                      ? niitTulbur.toDouble()
                      : (niitTulbur as double);
                }
              }
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

          setState(() {
            paymentDate = parsedDate;
            gereeData = geree;
            totalNiitTulbur = total;
            isLoadingPaymentData = false;
          });
        } else {
          setState(() {
            isLoadingPaymentData = false;
          });
        }
      } else {
        setState(() {
          isLoadingPaymentData = false;
        });
      }
    } catch (e) {
      print('Төлбөрийн мэдээлэл татхад алдаа гарлаа: $e');
      setState(() {
        isLoadingPaymentData = false;
      });
    }
  }

  int _calculateDaysDifference() {
    if (paymentDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final payment = DateTime(
      paymentDate!.year,
      paymentDate!.month,
      paymentDate!.day,
    );

    return payment.difference(today).inDays;
  }

  // Format number with comma separator
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
                  final isSmallScreen = screenHeight < 700;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16.0 : 24.0,
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
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumberWithComma(totalNiitTulbur)}₮',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 22 : 26,
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
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 8 : 10,
                                ),
                                child: Text(
                                  'Төлөх',
                                  style: TextStyle(
                                    color: const Color(0xFF0a0e27),
                                    fontSize: isSmallScreen ? 14 : 16,
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
                            final isSmallScreen = screenHeight < 700;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
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
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 12 : 16),
                                      _buildInfoRow(
                                        'Гэрээний дугаар',
                                        gereeData!.gereeniiDugaar,
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),
                                      _buildInfoRow(
                                        'Барилгын нэр',
                                        gereeData!.bairNer,
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoRow(
                                              'Давхар',
                                              gereeData!.davkhar.toString(),
                                            ),
                                          ),
                                          SizedBox(
                                            width: isSmallScreen ? 12 : 16,
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
                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  Row(
                                    children: List.generate(
                                      150 ~/ 6,
                                      (index) => Expanded(
                                        child: Container(
                                          color: index % 2 == 0
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.transparent,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Төлөх хугацаа:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formatDate(gereeData!.tulukhOgnoo),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
    final isOverdue = daysDifference < 0;
    final displayDays = daysDifference.abs();

    // Get screen height to determine if we're on a small screen
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    // Adjust sizes based on screen height
    final circleSize = isSmallScreen ? 180.0 : 250.0;
    final circlePadding = isSmallScreen ? 10.0 : 20.0;
    final strokeWidth = isSmallScreen ? 14.0 : 18.0;
    final fontSize = isSmallScreen ? 60.0 : 80.0;
    final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final verticalPadding = isSmallScreen ? 10.0 : 20.0;
    final spacingAfterCircle = isSmallScreen ? 10.0 : 20.0;

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
                        isOverdue ? '-$displayDays' : displayDays.toString(),
                        style: TextStyle(
                          color: isOverdue
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFe6ff00),
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        isOverdue ? 'өдөр хэтэрсэн' : 'өдөр үлдсэн',
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
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 10 : 12,
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
                  size: isSmallScreen ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Төлбөрийн огноо: ${_formatPaymentDate()}',
                  style: TextStyle(
                    color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
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

  String _formatPaymentDate() {
    if (paymentDate == null) return '';

    final year = paymentDate!.year;
    final month = paymentDate!.month;
    final day = paymentDate!.day;

    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  void _showPaymentModal() {
    // Check if there's any amount to pay
    if (totalNiitTulbur <= 0) {
      showGlassSnackBar(
        context,
        message: 'Танд төлөх төлбөр байхгүй байна',
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
