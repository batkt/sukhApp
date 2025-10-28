import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/router/app_router.dart';
import 'package:sukh_app/widgets/app_logo.dart';

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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e), // App dark background
                  Color(0xFF252547), // Lighter shade
                ],
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
                // Animated Icon
                const _BouncingRocket(),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Хөгжүүлэлт явагдаж байна',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: 16,
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
            const SizedBox(height: 20),
            // Logo and App Name Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const AppLogo(
                    minHeight: 50,
                    maxHeight: 50,
                    minWidth: 50,
                    maxWidth: 50,
                    showImage: true,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Amarhome',
                    style: TextStyle(
                      color: Color(0xFFe6ff00),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Colors.grey,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 10),
            _buildMenuItem(
              context,
              icon: Icons.dashboard_outlined,
              title: 'Хянах самбар',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.history,
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

            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(
                'ZevTabs © 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
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
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFe6ff00).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Color(0xFFe6ff00),
              size: 48,
            ),
          ),
        );
      },
    );
  }
}
