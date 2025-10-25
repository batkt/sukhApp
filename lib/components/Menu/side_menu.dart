import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/router/app_router.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1a1a2e),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
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
                context.push('/sanal_khuselt');
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.directions_car_outlined,
              title: 'Машин',
              onTap: () {
                Navigator.pop(context);
                context.push("/mashin");
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.phone,
              title: 'Дуудлага үйлчилгээ ',
              onTap: () {
                Navigator.pop(context);
                context.push("/duudlaga");
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.mark_unread_chat_alt,
              title: 'Мэдэгдэл',
              onTap: () {
                Navigator.pop(context);
                context.push('/medegdel');
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
