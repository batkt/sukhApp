import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/screens/contact/contact_bottom_sheet.dart';
import 'package:sukh_app/services/version_service.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? _baiguullagiinId;
  bool _canInviteGuests = false;
  String _userName = 'Ашиглагч';
  String _appVersion = 'v2.0.3'; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadOrganizationInfo();
    _checkGuestInvitePermission();
    _loadUserData();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await VersionService.getAppVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    if (mounted && name != null) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadOrganizationInfo() async {
    final id = await StorageService.getBaiguullagiinId();
    if (!mounted) return;
    setState(() {
      _baiguullagiinId = id;
    });
  }

  Future<void> _checkGuestInvitePermission() async {
    try {
      final response = await ApiService.fetchZochinSettings();
      if (mounted && response != null) {
        dynamic data = response;
        if (response.containsKey('data')) {
          data = response['data'];
        } else if (response.containsKey('result')) {
          data = response['result'];
        }

        bool canInvite = false;
        if (data is Map) {
          if (data.containsKey('orshinSuugchMashin') && data['orshinSuugchMashin'] != null) {
            final osm = data['orshinSuugchMashin'];
            canInvite = osm['zochinUrikhEsekh'] == true;
          } else if (data.containsKey('zochinUrikhEsekh')) {
            canInvite = data['zochinUrikhEsekh'] == true;
          }
        }
        setState(() {
          _canInviteGuests = canInvite;
        });
      }
    } catch (e) {
      debugPrint('❌ [SideMenu] Error checking guest invite permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    double drawerWidth = isTablet ? 280 : screenWidth * 0.78;

    return Drawer(
      backgroundColor: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          _buildProfileHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
              children: [
                _buildMenuSection(
                  'Үндсэн цэс',
                  [
                    _buildNavTile(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Хувийн мэдээлэл',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/tokhirgoo');
                      },
                    ),
                    _buildNavTile(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Хаяг сонгох',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/address_selection?fromMenu=true');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildMenuSection(
                  'Төлбөр ба Гэрээ',
                  [
                    _buildNavTile(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Миний гэрээ',
                      onTap: () {
                        if (_baiguullagiinId == null ||
                            _baiguullagiinId!.isEmpty ||
                            _baiguullagiinId == '698e7fd3b6dd386b6c56a808') {
                          _showOrgRequiredWarning(context);
                          return;
                        }
                        Navigator.pop(context);
                        context.push('/geree');
                      },
                    ),
                    _buildNavTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Нэхэмжлэхүүд',
                      onTap: () {
                        if (_baiguullagiinId == null ||
                            _baiguullagiinId!.isEmpty ||
                            _baiguullagiinId == '698e7fd3b6dd386b6c56a808') {
                          _showOrgRequiredWarning(context);
                          return;
                        }
                        Navigator.pop(context);
                        context.push('/nekhemjlekh');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildMenuSection(
                  'Бусад',
                  [
                    _buildNavTile(
                      context,
                      icon: Icons.cloud_done_outlined,
                      title: 'И-Баримт',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/ebarimt');
                      },
                    ),
                    if (_canInviteGuests)
                      _buildNavTile(
                        context,
                        icon: Icons.person_add_alt_outlined,
                        title: 'Зочин урих',
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/zochin-urikh');
                        },
                      ),
                    _buildNavTile(
                      context,
                      icon: Icons.mail_outline_rounded,
                      title: 'Санал хүсэлт',
                      onTap: () {
                        if (_baiguullagiinId == null ||
                            _baiguullagiinId!.isEmpty ||
                            _baiguullagiinId == '698e7fd3b6dd386b6c56a808') {
                          _showOrgRequiredWarning(context);
                          return;
                        }
                        Navigator.pop(context);
                        context.push('/gomdol-sanal-progress');
                      },
                    ),
                    _buildNavTile(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: 'Тусламж',
                      onTap: () {
                        Navigator.pop(context);
                        _showContactBottomSheet(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.deepGreen,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: const SelectableLogoImage(width: 44, height: 44),
          ),
          SizedBox(height: 16.h),
          Text(
            'Амархоум',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 3,
            width: 24.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.w, bottom: 8.h),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.5),
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.deepGreen, size: 22.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 13.sp, // Slightly smaller to fit gracefully on small iPhone screens
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textSecondaryColor.withOpacity(0.3),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: context.isDarkMode ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20.sp),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        'Системээс гарах',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Powered by Zevtabs LLC • v$_appVersion',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.4),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final router = GoRouter.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280.w,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Гарах',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Та системээс гарахдаа итгэлтэй байна уу?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Үгүй',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Тийм',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      await SessionService.logout();
      router.go('/newtrekh');
    }
  }

  void _showOrgRequiredWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280.w,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  color: AppColors.error,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Бүртгэлгүй СӨХ',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Таны хаягт СӨХ бүртгэгдээгүй байна.\nСӨХ-тэйгээ холбогдон бүртгүүлнэ үү.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Ойлголоо',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
}
