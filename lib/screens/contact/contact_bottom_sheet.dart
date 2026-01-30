import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/models/geree_model.dart';

class ContactBottomSheet extends StatefulWidget {
  const ContactBottomSheet({super.key});

  @override
  State<ContactBottomSheet> createState() => _ContactBottomSheetState();
}

class _ContactBottomSheetState extends State<ContactBottomSheet> {
  bool isLoading = true;
  String? organizationName;
  List<String> suhPhoneNumbers = []; // СӨХ phone numbers from baiguullaga
  List<String> ajiltanPhones = []; // Ajiltan phone numbers from geree.suhUtas
  bool isExpanded = false; // For expandable СӨХ section

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      
      // Get organization name and phones from baiguullaga
      List<String> baiguullagaPhones = [];
      if (baiguullagiinId != null) {
        final baiguullagaResponse = await ApiService.fetchBaiguullagaById(baiguullagiinId);
        if (mounted) {
          setState(() {
            organizationName = baiguullagaResponse['ner']?.toString() ?? 'СӨХ';
          });
        }
        // Get organization phones (СӨХ main phones)
        if (baiguullagaResponse['utas'] != null && baiguullagaResponse['utas'] is List) {
          baiguullagaPhones = (baiguullagaResponse['utas'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      // Fetch ajiltan phone numbers from geree's suhUtas field
      List<String> staffPhones = [];
      try {
        final userId = await StorageService.getUserId();
        if (userId != null) {
          final gereeResponse = await ApiService.fetchGeree(userId);
          final gereeList = GereeResponse.fromJson(gereeResponse);
          
          print('📞 [CONTACT] Geree count: ${gereeList.jagsaalt.length}');

          // Get suhUtas from the first geree (or combine from all)
          for (var geree in gereeList.jagsaalt) {
            if (geree.suhUtas.isNotEmpty) {
              for (var phone in geree.suhUtas) {
                if (phone.isNotEmpty && !staffPhones.contains(phone)) {
                  staffPhones.add(phone);
                }
              }
            }
          }
          
          print('📞 [CONTACT] Ajiltan phones from geree.suhUtas: $staffPhones');
        }
      } catch (e) {
        print('❌ [CONTACT] Error loading geree: $e');
      }

      print('📞 [CONTACT] СӨХ phones: $baiguullagaPhones');
      print('📞 [CONTACT] Ajiltan phones count: ${staffPhones.length}');

      if (mounted) {
        setState(() {
          suhPhoneNumbers = baiguullagaPhones;
          ajiltanPhones = staffPhones;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [CONTACT] Error loading contact info: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
              fontSize: 16.sp,
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
                // СӨХ contacts section - expandable
                if (isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                  )
                else if (suhPhoneNumbers.isNotEmpty || ajiltanPhones.isNotEmpty) ...[
                  _buildExpandableSuhSection(context),
                  SizedBox(height: 16.h),
                ],

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

  Widget _buildExpandableSuhSection(BuildContext context) {
    final hasSuhPhone = suhPhoneNumbers.isNotEmpty;
    final hasAjiltan = ajiltanPhones.isNotEmpty;
    final displayPhone = hasSuhPhone ? suhPhoneNumbers.first : '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, organizationName ?? 'СӨХ'),
        SizedBox(height: 8.h),
        
        // СӨХ phone tile - shows phone number, expandable to show ajiltan
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasAjiltan ? () {
              setState(() {
                isExpanded = !isExpanded;
              });
            } : (hasSuhPhone ? () => _launchPhone(displayPhone) : null),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF252525)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.deepGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      color: AppColors.deepGreen,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSuhPhone ? displayPhone : 'СӨХ утас',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          hasAjiltan 
                            ? (isExpanded ? 'Хураах' : '${ajiltanPhones.length} ажилтан харах')
                            : 'СӨХ утас',
                          style: TextStyle(
                            color: hasAjiltan ? AppColors.deepGreen : context.textSecondaryColor,
                            fontSize: 12.sp,
                            fontWeight: hasAjiltan ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasAjiltan) ...[
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.deepGreen,
                        size: 20.sp,
                      ),
                    ),
                  ] else if (hasSuhPhone) ...[
                    Icon(
                      Icons.call,
                      color: AppColors.deepGreen,
                      size: 18.sp,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        // Show additional СӨХ phones if there are more than one
        if (hasSuhPhone && suhPhoneNumbers.length > 1 && !isExpanded) ...[
          SizedBox(height: 8.h),
          ...suhPhoneNumbers.skip(1).map((phone) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _buildSimplePhoneItem(context, phone: phone, label: 'СӨХ утас'),
          )),
        ],
        
        // Expanded content with ajiltan phone numbers
        if (hasAjiltan)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                    child: Text(
                      'СӨХ ажилтнууд',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...ajiltanPhones.asMap().entries.map((entry) {
                    final index = entry.key;
                    final phone = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < ajiltanPhones.length - 1 ? 8.h : 0),
                      child: _buildAjiltanPhoneItem(
                        context,
                        phone: phone,
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
      ],
    );
  }

  Widget _buildSimplePhoneItem(BuildContext context, {required String phone, required String label}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchPhone(phone),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.deepGreen.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: AppColors.deepGreen,
                size: 16.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.call,
                color: AppColors.deepGreen,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAjiltanPhoneItem(BuildContext context, {required String phone}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchPhone(phone),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.deepGreen.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Person icon
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.deepGreen,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  phone,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.call,
                color: AppColors.deepGreen,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneItem(
    BuildContext context, {
    required String phone,
    String? staffName,
    String? position,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchPhone(phone),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.deepGreen.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Person icon
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.deepGreen,
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (staffName != null) ...[
                      Text(
                        staffName,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      phone,
                      style: TextStyle(
                        color: staffName != null ? context.textSecondaryColor : context.textPrimaryColor,
                        fontSize: staffName != null ? 10.sp : 12.sp,
                        fontWeight: staffName != null ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    if (position != null) ...[
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          position,
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.call,
                color: AppColors.deepGreen,
                size: 16.sp,
              ),
            ],
          ),
        ),
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
              fontSize: 13.sp,
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
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
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
                Icons.call,
                color: accentColor,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

