import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/models/ajiltan_model.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  bool isLoading = true;
  String? organizationName;
  List<String> phoneNumbers = [];
  List<Map<String, String>> staffPhoneNumbers = []; // {name, phone}
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBaiguullagaInfo();
  }

  Future<void> _loadBaiguullagaInfo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Байгууллагын мэдээлэл олдсонгүй';
        });
        return;
      }

      final response = await ApiService.fetchBaiguullagaById(baiguullagiinId);
      
      setState(() {
        organizationName = response['ner']?.toString() ?? 'СӨХ';
        if (response['utas'] != null && response['utas'] is List) {
          phoneNumbers = (response['utas'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        isLoading = false;
      });

      // Load staff phone numbers
      _loadStaffPhoneNumbers();
    } catch (e) {
      print('Error loading baiguullaga info: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Мэдээлэл татахад алдаа гарлаа';
      });
    }
  }

  Future<void> _loadStaffPhoneNumbers() async {
    try {
      final response = await ApiService.fetchAjiltan();
      final barilgiinId = await StorageService.getBarilgiinId();
      final ajiltanResponse = AjiltanResponse.fromJson(response);

      print('📞 [CONTACT PAGE] Loading staff phones, barilgiinId: $barilgiinId');
      print('📞 [CONTACT PAGE] Total ajiltan count: ${ajiltanResponse.jagsaalt.length}');

      // Collect phone numbers - first try to filter by barilgiinId, if empty show all
      List<Map<String, String>> staffPhones = [];
      
      for (var ajiltan in ajiltanResponse.jagsaalt) {
        print('📞 [CONTACT PAGE] Ajiltan: ${ajiltan.ner}, utas: ${ajiltan.utas}, barilguud: ${ajiltan.barilguud}');
        
        // Check if current barilgiinId is in the ajiltan's barilguud list
        final isInBuilding = barilgiinId != null && ajiltan.barilguud.contains(barilgiinId);
        
        if (isInBuilding && ajiltan.utas.isNotEmpty) {
          final name = ajiltan.ovog != null && ajiltan.ovog!.isNotEmpty
              ? '${ajiltan.ovog} ${ajiltan.ner}'
              : ajiltan.ner;
          staffPhones.add({
            'name': name,
            'phone': ajiltan.utas,
            'position': ajiltan.albanTushaal ?? 'Ажилтан',
          });
        }
      }

      // If no staff found for specific building, show all staff with phone numbers
      if (staffPhones.isEmpty) {
        print('📞 [CONTACT PAGE] No staff for specific building, showing all staff');
        for (var ajiltan in ajiltanResponse.jagsaalt) {
          if (ajiltan.utas.isNotEmpty) {
            final name = ajiltan.ovog != null && ajiltan.ovog!.isNotEmpty
                ? '${ajiltan.ovog} ${ajiltan.ner}'
                : ajiltan.ner;
            staffPhones.add({
              'name': name,
              'phone': ajiltan.utas,
              'position': ajiltan.albanTushaal ?? 'Ажилтан',
            });
          }
        }
      }

      print('📞 [CONTACT PAGE] Final staff phones count: ${staffPhones.length}');

      if (mounted) {
        setState(() {
          staffPhoneNumbers = staffPhones;
        });
      }
    } catch (e) {
      print('❌ [CONTACT PAGE] Error loading staff phone numbers: $e');
      // Silent fail - staff phone numbers are optional
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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

                  // Title - Organization Name
                  if (isLoading)
                    SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.deepGreen,
                      ),
                    )
                  else if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 14.sp,
                      ),
                    )
                  else ...[
                    Text(
                      organizationName ?? 'СӨХ',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 8,
                        medium: 10,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 6,
                      ),
                    ),
                    Text(
                      'Холбоо барих утас',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 24,
                      medium: 28,
                      large: 32,
                      tablet: 36,
                      veryNarrow: 18,
                    ),
                  ),

                  // Phone numbers from baiguullaga
                  if (!isLoading && errorMessage == null)
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
                          if (phoneNumbers.isEmpty)
                            Text(
                              'Утасны дугаар бүртгэгдээгүй байна',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 14.sp,
                              ),
                            )
                          else
                            ...phoneNumbers.map((phone) => Padding(
                              padding: EdgeInsets.only(
                                bottom: context.responsiveSpacing(
                                  small: 12,
                                  medium: 14,
                                  large: 16,
                                  tablet: 18,
                                  veryNarrow: 10,
                                ),
                              ),
                              child: _buildContactOption(
                                context,
                                icon: Icons.phone_outlined,
                                label: phone,
                                subtitle: 'СӨХ утас',
                                onTap: () => _launchPhone(phone),
                              ),
                            )),
                          // Staff phone numbers
                          if (staffPhoneNumbers.isNotEmpty) ...[
                            SizedBox(
                              height: context.responsiveSpacing(
                                small: 16,
                                medium: 18,
                                large: 20,
                                tablet: 22,
                                veryNarrow: 12,
                              ),
                            ),
                            Text(
                              'СӨХ Ажилтан',
                              style: TextStyle(
                                color: AppColors.deepGreen,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
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
                            ...staffPhoneNumbers.map((staff) => Padding(
                              padding: EdgeInsets.only(
                                bottom: context.responsiveSpacing(
                                  small: 12,
                                  medium: 14,
                                  large: 16,
                                  tablet: 18,
                                  veryNarrow: 10,
                                ),
                              ),
                              child: _buildContactOption(
                                context,
                                icon: Icons.person_outline,
                                label: staff['phone'] ?? '',
                                subtitle: '${staff['name']} - ${staff['position']}',
                                onTap: () => _launchPhone(staff['phone'] ?? ''),
                              ),
                            )),
                          ],
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 18,
                              medium: 20,
                              large: 24,
                              tablet: 28,
                              veryNarrow: 14,
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
    String? subtitle,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.phone,
                color: AppColors.deepGreen,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
