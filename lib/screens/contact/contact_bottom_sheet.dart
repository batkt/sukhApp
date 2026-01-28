import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class ContactBottomSheet extends StatelessWidget {
  const ContactBottomSheet({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchFacebook() async {
    final facebookUrl = 'https://www.facebook.com/Amarhome';
    final uri = Uri.parse(facebookUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            'Холбоо барих',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Contact options
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company contacts section
                _buildSectionHeader(context, 'Амархоум'),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.phone_outlined,
                  label: '7707 2707',
                  subtitle: 'Лавлах утас',
                  onTap: () => _launchPhone('77072707'),
                ),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.language,
                  label: 'Amarhome.mn',
                  subtitle: 'Вебсайт',
                  onTap: () => _launchWebsite('amarhome.mn'),
                ),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.facebook,
                  label: 'Amarhome',
                  subtitle: 'Facebook хуудас',
                  onTap: _launchFacebook,
                ),

                SizedBox(height: 16.h),

                // Emergency section
                _buildSectionHeader(context, 'Яаралтай тусламж', isEmergency: true),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.local_police_outlined,
                  label: '102',
                  subtitle: 'Цагдаа',
                  onTap: () => _launchPhone('102'),
                  isEmergency: true,
                ),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.local_hospital_outlined,
                  label: '103',
                  subtitle: 'Түргэн тусламж',
                  onTap: () => _launchPhone('103'),
                  isEmergency: true,
                ),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.local_fire_department_outlined,
                  label: '101',
                  subtitle: 'Гал унтраах',
                  onTap: () => _launchPhone('101'),
                  isEmergency: true,
                ),
                SizedBox(height: 8.h),
                _buildContactOption(
                  context,
                  icon: Icons.emergency_outlined,
                  label: '105',
                  subtitle: 'Онцгой байдал',
                  onTap: () => _launchPhone('105'),
                  isEmergency: true,
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool isEmergency = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
      child: Row(
        children: [
          if (isEmergency) ...[
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 14.sp,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            title,
            style: TextStyle(
              color: isEmergency ? AppColors.error : AppColors.deepGreen,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    final accentColor = isEmergency ? AppColors.error : AppColors.deepGreen;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF252525)
                : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.call,
                color: accentColor,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

