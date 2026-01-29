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
              veryNarrow: 16,
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
                  veryNarrow: 18,
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
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 12,
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
                    veryNarrow: 12,
                  ),
                ),

                // Description
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
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
                    veryNarrow: 16,
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
                          veryNarrow: 12,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 15,
                          veryNarrow: 11,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 800;
    
    // Standard drawer width: 304 on phones, larger on tablets
    double drawerWidth;
    if (isLargeScreen) {
      drawerWidth = 380; // Large tablets/iPads
    } else if (isTablet) {
      drawerWidth = 340; // Small tablets/iPad mini
    } else if (screenWidth > 400) {
      drawerWidth = 304; // iPhone Max/Plus models
    } else {
      drawerWidth = screenWidth * 0.82; // Smaller phones
    }
    
    return Drawer(
      backgroundColor: context.backgroundColor,
      width: drawerWidth,
      child: Column(
        children: [
          // AppBar-like header with deep green background
          Container(
            color: AppColors.getDeepGreen(context.isDarkMode),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: isTablet ? 20 : 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
                child: Row(
                  children: [
                    // Green circle background for logo
                    Container(
                      width: isTablet ? 48 : 40,
                      height: isTablet ? 48 : 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: Center(
                        child: AppLogo(
                          minHeight: isTablet ? 36 : 30,
                          maxHeight: isTablet ? 36 : 30,
                          minWidth: isTablet ? 36 : 30,
                          maxWidth: isTablet ? 36 : 30,
                          showImage: true,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Text(
                        'Amarhome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
                  SizedBox(height: isTablet ? 16 : 12),
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
                            isTablet: isTablet,
                          ),
                          // Show address selection only for users without baiguullagiinId
                          if (_baiguullagiinId == null ||
                              _baiguullagiinId!.isEmpty)
                            _buildMenuItem(
                              context,
                              icon: Icons.location_on_outlined,
                              title: 'Хаяг сонгох',
                              onTap: () {
                                Navigator.pop(context);
                                context.push(
                                  '/address_selection?fromMenu=true',
                                );
                              },
                              isTablet: isTablet,
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
                              isTablet: isTablet,
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.receipt_long_outlined,
                              title: 'Нэхэмжлэх',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/nekhemjlekh');
                              },
                              isTablet: isTablet,
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
                            isTablet: isTablet,
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
                              isTablet: isTablet,
                            ),
                          if (_baiguullagiinId != null &&
                              _baiguullagiinId!.isNotEmpty)
                            _buildMenuItem(
                              context,
                              icon: Icons.person_add_alt_outlined,
                              title: 'Зочин урих',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/zochin-urikh');
                              },
                              isTablet: isTablet,
                            ),
                          _buildMenuItem(
                            context,
                            icon: Icons.cloud_outlined,
                            title: 'И-Баримт',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/ebarimt');
                            },
                            isTablet: isTablet,
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.phone_outlined,
                            title: 'Холбоо барих',
                            onTap: () {
                              Navigator.pop(context);
                              _showContactBottomSheet(context);
                            },
                            isTablet: isTablet,
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
                                          veryNarrow: 14,
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
                                          small: 14,
                                          medium: 15,
                                          large: 16,
                                          tablet: 18,
                                          veryNarrow: 12,
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
                                          small: 11,
                                          medium: 12,
                                          large: 13,
                                          tablet: 14,
                                          veryNarrow: 10,
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
                                            fontSize: context
                                                .responsiveFontSize(
                                                  small: 11,
                                                  medium: 12,
                                                  large: 13,
                                                  tablet: 14,
                                                  veryNarrow: 10,
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
                                            fontSize: context
                                                .responsiveFontSize(
                                                  small: 11,
                                                  medium: 12,
                                                  large: 13,
                                                  tablet: 14,
                                                  veryNarrow: 10,
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
                            isTablet: isTablet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 8),
                  // Footer stays at the bottom
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: isTablet ? 16 : 8,
                      top: isTablet ? 12 : 8,
                    ),
                    child: Text(
                      '© 2026 Powered by Zevtabs LLC',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: context.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
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
    bool isTablet = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
          child: Row(
            children: [
              // Clean icon without border
              Icon(
                icon,
                color: isLogout ? Colors.red : AppColors.deepGreen,
                size: isTablet ? 26 : 22,
              ),
              SizedBox(width: isTablet ? 16 : 14),
              // Title text
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isLogout ? Colors.red : context.textPrimaryColor,
                    fontSize: isTablet ? 17 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Right arrow
              Icon(
                Icons.chevron_right,
                color: isLogout
                    ? Colors.red.withOpacity(0.5)
                    : context.textSecondaryColor,
                size: isTablet ? 24 : 20,
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
              veryNarrow: 12,
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
                veryNarrow: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}
