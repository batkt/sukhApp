import 'package:flutter/material.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Notifications/notification.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';

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
  bool _isBlur = false;
  DateTime selectedDate = DateTime.now();
  int? selectedDay;
  int? paymentDay; // Day extracted from gereeniiOgnoo
  bool isLoadingPaymentDay = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadPaymentDay();
  }

  Future<void> _loadPaymentDay() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) return;

      final response = await ApiService.fetchGeree(userId);

      if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
        final List<dynamic> jagsaalt = response['jagsaalt'];

        if (jagsaalt.isNotEmpty) {
          final firstContract = jagsaalt[0];
          final gereeniiOgnoo = firstContract['gereeniiOgnoo'] as String?;

          if (gereeniiOgnoo != null) {
            try {
              final dateTime = DateTime.parse(gereeniiOgnoo);
              setState(() {
                paymentDay = dateTime.day;
                isLoadingPaymentDay = false;
              });
            } catch (e) {
              print('Error parsing gereeniiOgnoo: $e');
              setState(() {
                isLoadingPaymentDay = false;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading payment day: $e');
      setState(() {
        isLoadingPaymentDay = false;
      });
    }
  }

  int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int getFirstDayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return (firstDay.weekday - 1) % 7;
  }

  String getMonthName(int month) {
    const months = [
      '1-р сар',
      '2-р сар',
      '3-р сар',
      '4-р сар',
      '5-р сар',
      '6-р сар',
      '7-р сар',
      '8-р сар',
      '9-р сар',
      '10-р сар',
      '11-р сар',
      '12-р сар',
    ];
    return months[month - 1];
  }

  void changeMonth(int delta) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + delta, 1);
      selectedDay = null;
    });
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
    final daysInMonth = getDaysInMonth(selectedDate);
    final firstDayOffset = getFirstDayOfMonth(selectedDate);
    final totalCells = firstDayOffset + daysInMonth;

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
                      child: IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        iconSize: 30,
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
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
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                iconSize: 36,
                                onPressed: () {
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
                                color: Colors.black.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.person_rounded,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            iconSize: 30,
                            onPressed: () {
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
                                                color: const Color(0xFF1a1a2e),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _buildProfileMenuItem(
                                                    context,
                                                    icon:
                                                        Icons.settings_outlined,
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
                                                          GoRouter.of(context);

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
                                                                        color: Colors
                                                                            .white70,
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
                                                                        color: Colors
                                                                            .red,
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
                                                        router.go('/newtrekh');
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
                        const Text(
                          '152,200₮',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'Төлөх',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => changeMonth(-1),
                    ),
                    Text(
                      '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: () => changeMonth(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeekDay('Дав'),
                          _buildWeekDay('Мяг'),
                          _buildWeekDay('Лха'),
                          _buildWeekDay('Пүр'),
                          _buildWeekDay('Ба'),
                          _buildWeekDay('Бям', isWeekend: true),
                          _buildWeekDay('Ням', isWeekend: true),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 5,
                              ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            if (index < firstDayOffset) {
                              return const SizedBox();
                            }

                            int day = index - firstDayOffset + 1;

                            bool isToday =
                                selectedDate.year == DateTime.now().year &&
                                selectedDate.month == DateTime.now().month &&
                                day == DateTime.now().day;

                            bool hasBooking = day == 5 || day == 12;
                            bool isReserved = day == 12;
                            bool isPaymentDay =
                                paymentDay != null && day == paymentDay;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDay = day;
                                });
                              },
                              child: _buildCalendarDay(
                                day,
                                hasBooking: hasBooking,
                                isReserved: isReserved,
                                isSelected: selectedDay == day,
                                isToday: isToday,
                                isPaymentDay: isPaymentDay,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
                                'Товч мэдээлэл',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'СӨХ ийн төлбөрөө цаг тухайн бүрт нь төлж байгаарай',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

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
                        const Text(
                          '-25,880',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Дараагын төлөлт',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '21 Dec - 24 Dec',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
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

  Widget _buildWeekDay(String day, {bool isWeekend = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isWeekend ? const Color(0xFFe6ff00) : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
    int day, {
    bool hasBooking = false,
    bool isReserved = false,
    bool isSelected = false,
    bool isToday = false,
    bool isPaymentDay = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFe6ff00).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: isSelected || isToday
            ? Border.all(
                color: const Color(0xFFe6ff00),
                width: isToday && !isSelected ? 1 : 2,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: isSelected ? const Color(0xFFe6ff00) : Colors.white,
              fontSize: 16,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isPaymentDay) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Төлөлт хийх өдөр',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
