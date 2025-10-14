import 'package:flutter/material.dart';
import 'package:sukh_app/models/Menu/side_menu.dart';
import 'package:sukh_app/models/Notifications/notification.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const BookingScreen(),
    );
  }
}

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

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  int? selectedDay;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Get the number of days in the current month
  int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Get the first day of the month (0 = Monday, 6 = Sunday)
  int getFirstDayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return (firstDay.weekday - 1) % 7;
  }

  // Get month name in Mongolian
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
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
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
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFe6ff00,
                                                      ).withOpacity(0.3),
                                                      width: 1,
                                                    ),
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
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                      ),
                                                      const Divider(
                                                        color: Colors.white12,
                                                        height: 1,
                                                      ),
                                                      _buildProfileMenuItem(
                                                        context,
                                                        icon:
                                                            Icons.help_outline,
                                                        title: 'Тусламж',
                                                        onTap: () {
                                                          Navigator.pop(
                                                            context,
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
                                                        onTap: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Нийт үлдэгдэл',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '152,200₮',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Төлөх',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Month selector with navigation
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
                      // Week days header
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

                      // Calendar grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            // Empty cells before the first day
                            if (index < firstDayOffset) {
                              return const SizedBox();
                            }

                            int day = index - firstDayOffset + 1;

                            // Check if it's today
                            bool isToday =
                                selectedDate.year == DateTime.now().year &&
                                selectedDate.month == DateTime.now().month &&
                                day == DateTime.now().day;

                            bool hasBooking = day == 5 || day == 12;
                            bool isReserved = day == 12;

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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Төлөх мэдээлэл',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '-25,880 Анхдагч төлөлт',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '4:10 PM',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFe6ff00).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
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
          if (hasBooking) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isReserved ? const Color(0xFFe6ff00) : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isReserved ? 'For one week' : 'Танилц хийх хайх',
                style: const TextStyle(
                  color: Colors.black,
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
