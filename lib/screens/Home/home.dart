import 'package:flutter/material.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Notifications/notification.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/models/geree_model.dart';

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
  DateTime? paymentDate; // Full payment date from gereeniiOgnoo
  bool isLoadingPaymentData = true;
  Geree? gereeData; // Store full geree contract data
  double totalNiitTulbur = 0.0; // Total sum of all niitTulbur from jagsaalt
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

      final response = await ApiService.fetchGeree(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Сервертэй холбогдох хугацаа дууслаа');
        },
      );

      if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
        final List<dynamic> jagsaalt = response['jagsaalt'];

        if (jagsaalt.isNotEmpty) {
          final firstContract = jagsaalt[0];

          // Parse the geree data first
          final geree = Geree.fromJson(firstContract);

          // Calculate total niitTulbur from all contracts in jagsaalt
          double total = 0.0;
          for (var contract in jagsaalt) {
            final niitTulbur = contract['niitTulbur'];
            if (niitTulbur != null) {
              total += (niitTulbur is int)
                  ? niitTulbur.toDouble()
                  : (niitTulbur as double);
            }
          }

          // Try to parse date if available
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
      print('Error loading payment data: $e');
      setState(() {
        isLoadingPaymentData = false;
      });
    }
  }

  // Calculate days difference from today
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
                padding: const EdgeInsets.all(16.0),
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
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
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
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) {
                                            return Material(
                                              color: Colors.transparent,
                                              child: Stack(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        Navigator.pop(context),
                                                    child: Container(
                                                      color: Colors.transparent,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: position.dy + 60,
                                                    right: 16,
                                                    child: FadeTransition(
                                                      opacity: animation,
                                                      child:
                                                          const NotificationDropdown(),
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
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.notifications_rounded,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: const Text(
                                  '3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
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
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 30,
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Нийт үлдэгдэл',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 15,
                            ),
                            child: Text(
                              'Төлөх',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Payment Date Display Section
              Expanded(
                child: isLoadingPaymentData
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFe6ff00),
                        ),
                      )
                    : gereeData == null
                    ? const Center(
                        child: Text(
                          'Төлбөрийн мэдээлэл олдсонгүй',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : paymentDate == null
                    ? const Center(
                        child: Text(
                          'Төлбөрийн огноо тохируулаагүй байна',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : _buildPaymentDisplay(),
              ),

              const SizedBox(height: 20),

              // Contract Information Container
              if (gereeData != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(15),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Гэрээний мэдээлэл',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Гэрээний дугаар: ${gereeData!.gereeniiDugaar}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Барилгын нэр: ${gereeData!.bairNer}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Давхар: ${gereeData!.davkhar}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Тоот: ${gereeData!.toot}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Алдангт:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${gereeData!.baritsaaniiUldegdel.toStringAsFixed(0)} ₮',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Төлөх хугацаа:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDate(gereeData!.tulukhOgnoo),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 20,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: isOverdue ? 1.0 : (displayDays / 30).clamp(0.0, 1.0),
                    strokeWidth: 20,
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
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOverdue ? 'өдөр хэтэрсэн' : 'өдөр үлдсэн',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Payment date info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Төлбөрийн огноо: ${_formatPaymentDate()}',
                  style: TextStyle(
                    color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
                    fontSize: 14,
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
