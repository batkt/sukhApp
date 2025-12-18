import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/screens/contact/contact_bottom_sheet.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? _baiguullagiinId;

  @override
  void initState() {
    super.initState();
    _loadOrganizationInfo();
  }

  Future<void> _loadOrganizationInfo() async {
    final id = await StorageService.getBaiguullagiinId();
    if (!mounted) return;
    setState(() {
      _baiguullagiinId = id;
    });
  }

  void _showDevelopmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: context.responsivePadding(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.surfaceColor, context.surfaceElevatedColor],
              ),
              border: Border.all(color: AppColors.deepGreen, width: 2),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 24,
                  medium: 26,
                  large: 28,
                  tablet: 30,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BouncingRocket(),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                  ),
                ),

                Text(
                  'Хөгжүүлэлт явагдаж байна',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 20,
                      medium: 22,
                      large: 24,
                      tablet: 26,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                  ),
                ),

                // Description
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                    ),
                    height: 1.5,
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                  ),
                ),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: context.textPrimaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsiveSpacing(
                          small: 14,
                          medium: 16,
                          large: 18,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 16,
                          medium: 17,
                          large: 18,
                          tablet: 19,
                        ),
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
      backgroundColor: context.backgroundColor,
      child: Column(
        children: [
          // AppBar-like header with deep green background
          Container(
            color: AppColors.getDeepGreen(context.isDarkMode),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: context.responsiveSpacing(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: context.responsiveHorizontalPadding(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                ),
                child: Row(
                  children: [
                    AppLogo(
                      minHeight: context.responsiveSpacing(
                        small: 40,
                        medium: 44,
                        large: 48,
                        tablet: 52,
                      ),
                      maxHeight: context.responsiveSpacing(
                        small: 40,
                        medium: 44,
                        large: 48,
                        tablet: 52,
                      ),
                      minWidth: context.responsiveSpacing(
                        small: 40,
                        medium: 44,
                        large: 48,
                        tablet: 52,
                      ),
                      maxWidth: context.responsiveSpacing(
                        small: 40,
                        medium: 44,
                        large: 48,
                        tablet: 52,
                      ),
                      showImage: true,
                    ),
                    SizedBox(
                      width: context.responsiveSpacing(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Amarhome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(
                            small: 24,
                            medium: 26,
                            large: 28,
                            tablet: 30,
                          ),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu items
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                    ),
                  ),
                  // Wrap menu items in SingleChildScrollView
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.person_outline,
                            title: 'Хувийн мэдээлэл',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/tokhirgoo');
                            },
                          ),
                          // Show contract / invoice / parking only for users
                          // that are linked to an organization (have baiguullagiinId)
                          if (_baiguullagiinId != null &&
                              _baiguullagiinId!.isNotEmpty) ...[
                            _buildMenuItem(
                              context,
                              icon: Icons.home_outlined,
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
                          ],
                          _buildMenuItem(
                            context,
                            icon: Icons.feedback_outlined,
                            title: 'Санал хүсэлт',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/gomdol-sanal-progress');
                            },
                          ),
                          if (_baiguullagiinId != null &&
                              _baiguullagiinId!.isNotEmpty)
                            _buildMenuItem(
                              context,
                              icon: Icons.local_parking_outlined,
                              title: 'Зогсоол',
                              onTap: () {
                                Navigator.pop(context);
                                _showDevelopmentModal(context);
                              },
                            ),
                          _buildMenuItem(
                            context,
                            icon: Icons.cloud_outlined,
                            title: 'И-Баримт',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/ebarimt');
                            },
                          ),
                          // _buildMenuItem(
                          //   context,
                          //   icon: Icons.notifications_outlined,
                          //   title: 'Мэдэгдэл',
                          //   onTap: () {
                          //     Navigator.pop(context);
                          //     context.push('/medegdel-list');
                          //   },
                          // ),
                          _buildMenuItem(
                            context,
                            icon: Icons.phone_outlined,
                            title: 'Холбоо барих',
                            onTap: () {
                              Navigator.pop(context);
                              _showContactBottomSheet(context);
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
                                    backgroundColor:
                                        context.cardBackgroundColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        context.responsiveBorderRadius(
                                          small: 16,
                                          medium: 18,
                                          large: 20,
                                          tablet: 22,
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: context.borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    title: Text(
                                      'Гарах',
                                      style: TextStyle(
                                        color: AppColors.deepGreen,
                                        fontSize: context.responsiveFontSize(
                                          small: 20,
                                          medium: 22,
                                          large: 24,
                                          tablet: 26,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    content: Text(
                                      'Та системээс гарахдаа итгэлтэй байна уу?',
                                      style: TextStyle(
                                        color: context.textSecondaryColor,
                                        fontSize: context.responsiveFontSize(
                                          small: 16,
                                          medium: 17,
                                          large: 18,
                                          tablet: 19,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(
                                            dialogContext,
                                          ).pop(false);
                                        },
                                        child: Text(
                                          'Үгүй',
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: context.responsiveFontSize(
                                              small: 16,
                                              medium: 17,
                                              large: 18,
                                              tablet: 19,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop(true);
                                        },
                                        child: Text(
                                          'Тийм',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: context.responsiveFontSize(
                                              small: 16,
                                              medium: 17,
                                              large: 18,
                                              tablet: 19,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldLogout == true) {
                                // Disconnect socket before logout
                                SocketService.instance.disconnect();

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
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                    ),
                  ),
                  // Footer stays at the bottom
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: context.responsiveSpacing(
                        small: 5,
                        medium: 6,
                        large: 7,
                        tablet: 8,
                      ),
                      top: context.responsiveSpacing(
                        small: 10,
                        medium: 12,
                        large: 14,
                        tablet: 16,
                      ),
                    ),
                    child: Text(
                      '© 2025 Powered by Zevtabs LLC',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 15,
                        ),
                        color: context.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 20,
                      medium: 24,
                      large: 28,
                      tablet: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContactBottomSheet(),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 8,
            medium: 10,
            large: 12,
            tablet: 14,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
            ),
            vertical: context.responsiveSpacing(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
            ),
          ),
          child: Row(
            children: [
              // Icon with outline style
              Container(
                padding: context.responsivePadding(
                  small: 8,
                  medium: 9,
                  large: 10,
                  tablet: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 8,
                      medium: 10,
                      large: 12,
                      tablet: 14,
                    ),
                  ),
                  border: Border.all(
                    color: isLogout
                        ? Colors.red.withOpacity(0.3)
                        : AppColors.deepGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.red : AppColors.deepGreen,
                  size: context.responsiveIconSize(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                  ),
                ),
              ),
              SizedBox(
                width: context.responsiveSpacing(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                ),
              ),
              // Title text
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isLogout ? Colors.red : context.textPrimaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                    ),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Right arrow
              Icon(
                Icons.arrow_forward_ios,
                color: isLogout
                    ? Colors.red.withOpacity(0.5)
                    : context.textSecondaryColor,
                size: context.responsiveIconSize(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                ),
              ),
            ],
          ),
        ),
      ),
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
            padding: context.responsivePadding(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
            ),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.rocket_launch,
              color: AppColors.deepGreen,
              size: context.responsiveIconSize(
                small: 48,
                medium: 52,
                large: 56,
                tablet: 60,
              ),
            ),
          ),
        );
      },
    );
  }
}
