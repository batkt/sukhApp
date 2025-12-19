import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
    // Try to open Facebook app first, then fallback to web
    final facebookUrl = 'https://www.facebook.com/Amarhome';
    final uri = Uri.parse(facebookUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Холбоо барих'),
      body: SafeArea(
        child: Column(
          children: [
            // Spacer
            const Spacer(),

            // Contact Options Bottom Sheet
            Container(
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    context.responsiveBorderRadius(
                      small: 30,
                      medium: 32,
                      large: 34,
                      tablet: 36,
                      veryNarrow: 24,
                    ),
                  ),
                  topRight: Radius.circular(
                    context.responsiveBorderRadius(
                      small: 30,
                      medium: 32,
                      large: 34,
                      tablet: 36,
                      veryNarrow: 24,
                    ),
                  ),
                ),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(
                      top: context.responsiveSpacing(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 8,
                      ),
                    ),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 2,
                          medium: 3,
                          large: 4,
                          tablet: 5,
                          veryNarrow: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 20,
                      medium: 24,
                      large: 28,
                      tablet: 32,
                      veryNarrow: 14,
                    ),
                  ),

                  // Title
                  Text(
                    'Холбоо барих',
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 24,
                      medium: 28,
                      large: 32,
                      tablet: 36,
                      veryNarrow: 18,
                    ),
                  ),

                  // Contact options
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(
                        small: 20,
                        medium: 22,
                        large: 24,
                        tablet: 26,
                        veryNarrow: 14,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Phone
                        _buildContactOption(
                          context,
                          icon: Icons.phone_outlined,
                          label: '7707 2707',
                          onTap: () => _launchPhone('77072707'),
                        ),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),

                        // Website
                        _buildContactOption(
                          context,
                          icon: Icons.language,
                          label: 'Amarhome.mn',
                          onTap: () => _launchWebsite('amarhome.mn'),
                        ),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),

                        // Facebook
                        _buildContactOption(
                          context,
                          icon: Icons.facebook,
                          label: 'Amarhome',
                          onTap: _launchFacebook,
                        ),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 30,
                            medium: 34,
                            large: 38,
                            tablet: 42,
                            veryNarrow: 24,
                          ),
                        ),
                      ],
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

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          ),
        ),
        child: Container(
          padding: context.responsivePadding(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 12,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          ),
        ),
            border: Border.all(color: context.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: context.responsivePadding(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
                decoration: BoxDecoration(
                  color: context.accentBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                      veryNarrow: 8,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.deepGreen,
                  size: context.responsiveIconSize(
                    small: 24,
                    medium: 26,
                    large: 28,
                    tablet: 30,
                    veryNarrow: 20,
                  ),
                ),
              ),
              SizedBox(
                width: context.responsiveSpacing(
                  small: 16,
                  medium: 18,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 12,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.textSecondaryColor,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
