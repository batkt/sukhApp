import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/router/app_router.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/services/storage_service.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  void _showDevelopmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1a2e), Color(0xFF252547)],
              ),
              border: Border.all(color: const Color(0xFFe6ff00), width: 2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFe6ff00).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BouncingRocket(),
                SizedBox(height: 24.h),

                Text(
                  'Хөгжүүлэлт явагдаж байна',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // Description
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe6ff00),
                      foregroundColor: const Color(0xFF1a1a2e),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1a1a2e),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Logo and App Name Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  AppLogo(
                    minHeight: 50.w,
                    maxHeight: 50.w,
                    minWidth: 50.w,
                    maxWidth: 50.w,
                    showImage: true,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Amarhome',
                    style: TextStyle(
                      color: const Color(0xFFe6ff00),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.grey,
              thickness: 0.5,
              indent: 16.w,
              endIndent: 16.w,
            ),
            SizedBox(height: 10.h),
            // Wrap menu items in Expanded and SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Хувийн мэдээлэл',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.receipt,
                      title: 'Гэрээ',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/geree');
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Нэхэмжлэх',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/nekhemjlekh');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.people_alt_outlined,
                      title: 'Санал хүсэлт',
                      onTap: () {
                        Navigator.pop(context);
                        _showDevelopmentModal(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.directions_car_outlined,
                      title: 'Машин',
                      onTap: () {
                        Navigator.pop(context);
                        _showDevelopmentModal(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.phone,
                      title: 'Дуудлага үйлчилгээ ',
                      onTap: () {
                        Navigator.pop(context);
                        _showDevelopmentModal(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.mark_unread_chat_alt,
                      title: 'Мэдэгдэл',
                      onTap: () {
                        Navigator.pop(context);
                        _showDevelopmentModal(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Тохиргоо',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/tokhirgoo');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Гарах',
                      onTap: () async {
                        final router = GoRouter.of(context);

                        Navigator.pop(context);

                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF1a1a2e),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Гарах',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'Та системээс гарахдаа итгэлтэй байна уу?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                                  child: const Text(
                                    'Үгүй',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(true);
                                  },
                                  child: const Text(
                                    'Тийм',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldLogout == true) {
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

            SizedBox(height: 10.h),
            // Footer stays at the bottom
            Padding(
              padding: EdgeInsets.only(bottom: 5.h, top: 10.h),
              child: Text(
                '© 2025 Powered by Zevtabs LLC',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFFe6ff00),
        size: 24.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
    );
  }
}

// Bouncing Rocket Animation Widget
class _BouncingRocket extends StatefulWidget {
  const _BouncingRocket();

  @override
  State<_BouncingRocket> createState() => _BouncingRocketState();
}

class _BouncingRocketState extends State<_BouncingRocket>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: -15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFe6ff00).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch,
              color: const Color(0xFFe6ff00),
              size: 48.sp,
            ),
          ),
        );
      },
    );
  }
}
