import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';

import 'package:intl/intl.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/utils/logger.dart';

class ZochinUrikhPage extends StatefulWidget {
  const ZochinUrikhPage({super.key});

  @override
  State<ZochinUrikhPage> createState() => _ZochinUrikhPageState();
}

class _ZochinUrikhPageState extends State<ZochinUrikhPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mashiniiDugaarController = TextEditingController();
  final _ezemshigchiinUtasController = TextEditingController();
  
  bool _isLoading = false;
  
  // Lists for different statuses
  List<Map<String, dynamic>> _pendingGuests = [];
  List<Map<String, dynamic>> _activeGuests = [];
  List<Map<String, dynamic>> _exitedGuests = [];
  
  late TabController _tabController;
  bool _isLoadingHistory = true;
  String? _userPhoneNumber;
  Map<String, dynamic>? _quotaStatus;
  bool _isLoadingQuota = true;
  String? _quotaError;
  bool _hasQuota = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPhone();
    _loadInvitedGuests();
    _loadQuotaStatus();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    SocketService.instance.setNotificationCallback(_handleSocketMessage);
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    // Reload list on any relevant notification
    // Optimize this later if we know specific event types for car updates
    AppLogger.log('🔔 Socket message received in ZochinUrikhPage, reloading list...');
    _loadInvitedGuests(showLoading: false);
    _loadQuotaStatus();
  }

  Future<void> _loadQuotaStatus() async {
    try {
      if (mounted) setState(() {
        _isLoadingQuota = true;
        _quotaError = null;
      });
      
      final status = await ApiService.fetchZochinQuotaStatus();
      AppLogger.log('📊 [QUOTA] Received status: $status');
      
      if (mounted) {
        setState(() {
          // Handle various response formats (flat or wrapped in 'data'/'result')
          Map<String, dynamic> data;
          if (status['total'] != null) {
            data = status;
          } else if (status['data'] != null && status['data'] is Map) {
            data = Map<String, dynamic>.from(status['data']);
          } else if (status['result'] != null && status['result'] is Map) {
            data = Map<String, dynamic>.from(status['result']);
          } else {
            data = status;
          }
          
          // Map potential different key names for robustness
          _quotaStatus = {
            'total': data['total'] ?? data['zochinErkhiinToo'] ?? 0,
            'used': data['used'] ?? data['ashiglasanToo'] ?? 0,
            'remaining': data['remaining'] ?? data['uldsenToo'] ?? 0,
            'period': data['period'] ?? 'saraar',
            'freeMinutesPerGuest': data['freeMinutesPerGuest'] ?? data['zochinTusBurUneguiMinut'] ?? 0,
          };
          
          // Check success flag to determine if user can invite
          if (status['success'] == false) {
            _hasQuota = false;
          } else {
            // Even if success is true, if remaining is 0 we should disable
            final remaining = _quotaStatus!['remaining'] as int;
            final total = _quotaStatus!['total'] as int;
            final freeMinutes = _quotaStatus!['freeMinutesPerGuest'] as int? ?? 0;
            _hasQuota = total == 0 || remaining > 0 || freeMinutes > 0;
          }
          
          _isLoadingQuota = false;
        });
      }
    } catch (e) {
      AppLogger.log('❌ [QUOTA] Error loading quota status: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuota = false;
          _hasQuota = true; // Fallback to allow attempt if we can't check
          _quotaError = e.toString();
        });
      }
    }
  }

  Future<void> _loadUserPhone() async {
    final phone = await StorageService.getSavedPhoneNumber();
    if (mounted && phone != null) {
      setState(() {
        _userPhoneNumber = phone;
        _ezemshigchiinUtasController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    SocketService.instance.removeNotificationCallback(_handleSocketMessage);
    _tabController.dispose();
    _mashiniiDugaarController.dispose();
    _ezemshigchiinUtasController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitedGuests({bool showLoading = true}) async {
    try {
      if (showLoading) setState(() => _isLoadingHistory = true);
      
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final userId = await StorageService.getUserId();
      
      if (baiguullagiinId != null && userId != null) {
        final response = await ApiService.fetchZochinTuukh(
          baiguullagiinId: baiguullagiinId,
          ezenId: userId,
        );
        
        if (mounted) {
          final ezenList = response['ezenList'] as List? ?? [];
          final jagsaalt = response['jagsaalt'] as List? ?? [];
          
          setState(() {
            // "Хүлээлгэ" (Pending) - Usually items in ezenList with tuluv 0
            _pendingGuests = List<Map<String, dynamic>>.from(
              ezenList.where((item) => (item['tuluv'] ?? 0) == 0)
            );

            // Access nested 'urisanMashin' for jagsaalt items safely
            final historyItems = List<Map<String, dynamic>>.from(jagsaalt);
            
            // "Идэвхтэй" (Active) - tuluv 1
            _activeGuests = historyItems.where((item) {
              final um = item['urisanMashin'];
              final tuluv = um != null ? (um['tuluv'] ?? 0) : 0;
              return tuluv == 1;
            }).toList();

            // "Гарсан" (Exited) - tuluv 2
            _exitedGuests = historyItems.where((item) {
              final um = item['urisanMashin'];
              final tuluv = um != null ? (um['tuluv'] ?? 0) : 0;
              return tuluv == 2;
            }).toList();

            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingHistory = false);
        }
      }
    } catch (e) {
      AppLogger.log('Error loading invited guests: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _inviteGuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();
      final userId = await StorageService.getUserId();
      
      if (baiguullagiinId == null || userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      await ApiService.inviteGuest(
        urisanMashiniiDugaar: _mashiniiDugaarController.text.trim().toUpperCase(),
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        ezenId: userId,
      );

      if (mounted) {
        // Clear only the car plate field (phone stays as user's phone)
        _mashiniiDugaarController.clear();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Зочин амжилттай урилаа'),
            backgroundColor: AppColors.deepGreen,
          ),
        );
        
        // Reload history and quota
        _loadInvitedGuests();
        _loadQuotaStatus();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Clean up common technical prefixes
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        if (errorMessage.contains('Зочин хадгалахад алдаа гарлаа:')) {
          errorMessage = errorMessage.replaceFirst('Зочин хадгалахад алдаа гарлаа:', '').trim();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );

        // If it was a quota error (403), refresh to disable button
        if (e.toString().contains('403') || e.toString().contains('лимит')) {
          _loadQuotaStatus();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Зочин урих'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding(
            small: 16,
            medium: 20,
            large: 24,
            tablet: 28,
            veryNarrow: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quota status card
              if (_isLoadingQuota)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepGreen.withOpacity(0.5),
                    ),
                  ),
                )
              else if (_quotaError != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Квот ачаалж чадсангүй',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadQuotaStatus,
                        child: Text('Дахин оролдох'),
                      ),
                    ],
                  ),
                )
              else if (_quotaStatus != null && (_quotaStatus!['total'] > 0 || _quotaStatus!['freeMinutesPerGuest'] > 0))
                _buildQuotaCard(),
              
              if (!_isLoadingQuota && _quotaError == null && _quotaStatus != null && (_quotaStatus!['total'] > 0 || _quotaStatus!['freeMinutesPerGuest'] > 0))
                SizedBox(height: context.responsiveSpacing(
                  small: 16,
                  medium: 20,
                  large: 24,
                  tablet: 28,
                  veryNarrow: 12,
                )),

              // Form card
              Container(
                padding: context.responsivePadding(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                  veryNarrow: 16,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                  border: Border.all(color: context.borderColor, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Зочны машины мэдээлэл',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing(
                        small: 20,
                        medium: 24,
                        large: 28,
                        tablet: 32,
                        veryNarrow: 16,
                      )),
                      
                      // Car plate number (4 digits + 3 letters)
                      TextFormField(
                        controller: _mashiniiDugaarController,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(7),
                          PlateNumberFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Машины дугаар',
                          hintText: '1234АБВ',
                          prefixIcon: Icon(
                            Icons.directions_car_outlined,
                            color: AppColors.deepGreen,
                            size: context.responsiveIconSize(
                              small: 22,
                              medium: 24,
                              large: 26,
                              tablet: 28,
                              veryNarrow: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: AppColors.deepGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor,
                          labelStyle: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: context.textSecondaryColor.withOpacity(0.5),
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 14,
                              medium: 16,
                              large: 18,
                              tablet: 20,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 17,
                            veryNarrow: 13,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Машины дугаар оруулна уу';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length != 7) {
                            return '4 тоо, 3 үсэг оруулна уу (жишээ: 1234АБВ)';
                          }
                          // Check first 4 characters are digits
                          final digits = trimmed.substring(0, 4);
                          if (!RegExp(r'^[0-9]{4}$').hasMatch(digits)) {
                            return 'Эхний 4 тэмдэгт тоо байх ёстой';
                          }
                          // Check last 3 characters are letters (Cyrillic or Latin)
                          final letters = trimmed.substring(4);
                          if (!RegExp(r'^[A-Za-z\u0410-\u042F\u0430-\u044F]{3}$').hasMatch(letters)) {
                            return 'Сүүлийн 3 тэмдэгт үсэг байх ёстой';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: context.responsiveSpacing(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 22,
                        veryNarrow: 12,
                      )),
                      
                      // Phone number (read-only, auto-filled with user's phone)
                      TextFormField(
                        controller: _ezemshigchiinUtasController,
                        keyboardType: TextInputType.phone,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Таны утасны дугаар',
                          hintText: _userPhoneNumber ?? 'Ачаалж байна...',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.deepGreen.withOpacity(0.6),
                            size: context.responsiveIconSize(
                              small: 22,
                              medium: 24,
                              large: 26,
                              tablet: 28,
                              veryNarrow: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: context.textSecondaryColor.withOpacity(0.5),
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 14,
                              medium: 16,
                              large: 18,
                              tablet: 20,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor.withOpacity(0.7),
                          fontSize: context.responsiveFontSize(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 17,
                            veryNarrow: 13,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing(
                        small: 24,
                        medium: 28,
                        large: 32,
                        tablet: 36,
                        veryNarrow: 20,
                      )),
                      
                      // Submit button
                        GestureDetector(
                          onTap: (_isLoading || !_hasQuota) ? null : _inviteGuest,
                         child: AnimatedContainer(
                           duration: const Duration(milliseconds: 200),
                           width: double.infinity,
                           padding: EdgeInsets.symmetric(
                             vertical: context.responsiveSpacing(
                               small: 12,
                               medium: 14,
                               large: 16,
                               tablet: 18,
                               veryNarrow: 10,
                             ),
                           ),
                           decoration: BoxDecoration(
                             gradient: (!_isLoading && _hasQuota)
                                 ? LinearGradient(
                                     colors: [AppColors.deepGreen, AppColors.deepGreenDark],
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                   )
                                 : null,
                             color: (!_isLoading && _hasQuota)
                                 ? null
                                 : Colors.grey.withOpacity(0.3),
                             borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                               small: 10,
                               medium: 12,
                               large: 14,
                               tablet: 16,
                               veryNarrow: 8,
                             )),
                             boxShadow: (!_isLoading && _hasQuota)
                                 ? [
                                     BoxShadow(
                                       color: AppColors.deepGreen.withOpacity(0.3),
                                       blurRadius: 8,
                                       offset: const Offset(0, 4),
                                     ),
                                   ]
                                 : [],
                           ),
                           child: Center(
                             child: _isLoading 
                               ? SizedBox(
                                   width: 20.sp,
                                   height: 20.sp,
                                   child: const CircularProgressIndicator(
                                     strokeWidth: 2,
                                     color: Colors.white,
                                   ),
                                 )
                               : Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(
                                       _hasQuota ? Icons.person_add_outlined : Icons.block_flipped,
                                       size: 20.sp,
                                       color: Colors.white,
                                     ),
                                     SizedBox(width: 8.w),
                                     Text(
                                       _hasQuota ? 'Зочин урих' : 'Эрх дууссан',
                                       style: TextStyle(
                                         color: Colors.white,
                                         fontSize: 15.sp,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ],
                                 ),
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: context.responsiveSpacing(
                small: 24,
                medium: 28,
                large: 32,
                tablet: 36,
                veryNarrow: 20,
              )),
              
              // History section with Tabs
              Text(
                'Урилгын түүх',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: context.responsiveFontSize(
                    small: 16,
                    medium: 17,
                    large: 18,
                    tablet: 20,
                    veryNarrow: 14,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor, // Lighter background
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(4.w),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: context.cardBackgroundColor, // Card BG for selected
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Color(0xFF3B82F6), // Active Color
                  unselectedLabelColor: context.textPrimaryColor, // Inactive Color
                  labelStyle: TextStyle(
                    fontSize: 12.sp, 
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 12.sp, 
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
                  dividerColor: Colors.transparent, // Remove default divider
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Хүлээлгийн'),
                          if (_pendingGuests.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0 ? Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${_pendingGuests.length}',
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Идэвхтэй'),
                          if (_activeGuests.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1 ? Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${_activeGuests.length}',
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Гарсан'),
                        ],
                      ),
                    ),
                  ],
                  onTap: (index) {
                     setState(() {});
                  },
                ),
              ),
              
              SizedBox(height: 16.h),

              if (_isLoadingHistory)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.deepGreen,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 400.h, // Fixed height for list or use shrinkWrap with correct physics
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGuestList(_pendingGuests, 'Хүлээлгэ'),
                      _buildGuestList(_activeGuests, 'Идэвхтэй'),
                      _buildGuestList(_exitedGuests, 'Гарсан'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestList(List<Map<String, dynamic>> guests, String type) {
    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 40.sp, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 10.h),
            Text('Машин байхгүй', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: ClampingScrollPhysics(),
      itemCount: guests.length,
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return _buildGuestCard(guests[index]);
      },
    );
  }

  Widget _buildQuotaCard() {
    final total = _quotaStatus?['total'] ?? 0;
    final used = _quotaStatus?['used'] ?? 0;
    final remaining = _quotaStatus?['remaining'] ?? 0;
    final period = _quotaStatus?['period'] == 'saraar' ? 'сард' : 'өдөрт';
    final freeMinutes = _quotaStatus?['freeMinutesPerGuest'] ?? 0;

    return Container(
      padding: context.responsivePadding(
        small: 16,
        medium: 18,
        large: 20,
        tablet: 22,
        veryNarrow: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        )),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Урилгын эрх ($period)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: context.responsiveFontSize(
                    small: 13,
                    medium: 14,
                    large: 15,
                    tablet: 16,
                    veryNarrow: 12,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remaining/$total үлдсэн',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          if (freeMinutes > 0) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Зочин бүр $freeMinutes минут үнэгүй',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFontSize(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                      veryNarrow: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteInvitation(Map<String, dynamic> guest) async {
    final id = guest['_id']?.toString();
    if (id == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Урилга цуцлах'),
        content: Text('Та энэ урилгыг цуцлахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Үгүй'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Тийм', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId == null) throw Exception('Байгууллагын ID олдсонгүй');

      await ApiService.deleteZochinInvitation(
        id: id,
        baiguullagiinId: baiguullagiinId,
      );

      if (mounted) {
        setState(() {
          _pendingGuests.removeWhere((item) => item['_id'] == id);
          _activeGuests.removeWhere((item) => item['_id'] == id);
          _exitedGuests.removeWhere((item) => item['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Урилга амжилттай цуцлагдлаа')),
        );
        _loadInvitedGuests(showLoading: false);
        _loadQuotaStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    // Try to get data from either direct structure (ezenList) or nested (jagsaalt)
    
    // For "jagsaalt" items, the guest data is in 'urisanMashin' object,
    // but the main object has 'mashiniiDugaar' etc.
    final urisanMashin = guest['urisanMashin'];
    final isHistoryItem = urisanMashin != null;
    
    final mashiniiDugaar = isHistoryItem
        ? (guest['mashiniiDugaar'] ?? urisanMashin['urisanMashiniiDugaar'] ?? '')
        : (guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? '');
        
    final tuluv = isHistoryItem 
        ? (urisanMashin['tuluv'] ?? 0)
        : (guest['tuluv'] ?? 0);
        
    final createdAt = isHistoryItem
        ? (urisanMashin['createdAt'] ?? guest['createdAt'])
        : guest['createdAt'];
        
    // Calculate entry time and duration if applicable
    String durationStr = '';
    String dateStr = '';
    
    if (createdAt != null) {
      try {
        final createdDate = DateTime.parse(createdAt.toString()).toLocal();
        dateStr = DateFormat('dd/MM/yyyy').format(createdDate);
        
        // If active (1), show duration since entry
        // For Exited (2), we could show duration if we find exit time (updateAt or tuukh)
        if (tuluv == 1) {
          // Find entry time from tuukh if possible
          DateTime? entryTime;
          if (guest['tuukh'] != null && guest['tuukh'] is List && (guest['tuukh'] as List).isNotEmpty) {
            final lastTuukh = (guest['tuukh'] as List).last;
            if (lastTuukh['tsagiinTuukh'] != null && (lastTuukh['tsagiinTuukh'] as List).isNotEmpty) {
              final entering = (lastTuukh['tsagiinTuukh'] as List).first;
              if (entering['orsonTsag'] != null) {
                entryTime = DateTime.parse(entering['orsonTsag'].toString()).toLocal();
              }
            }
          }
          
          if (entryTime != null) {
            final duration = DateTime.now().difference(entryTime);
            if (duration.inMinutes < 60) {
              durationStr = '${duration.inMinutes}м';
            } else {
              durationStr = '${duration.inHours}ц ${duration.inMinutes % 60}м';
            }
          }
        }
      } catch (e) {
        // ignore date parse errors
      }
    }

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (tuluv == 1) {
      statusText = 'Идэвхтэй';
      statusColor = Color(0xFF3B82F6); // Blue
      statusBgColor = Color(0xFF1E3A8A).withOpacity(0.3);
    } else if (tuluv == 2) {
      statusText = 'Гарсан';
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.withOpacity(0.1);
    } else {
      statusText = 'Хүлээлгэ';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    }
    
    final cardContent = Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor, // Dark card bg
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Blue Dot if Active
              if (tuluv == 1)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mashiniiDugaar,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tuluv == 1) ...[
                          Icon(Icons.location_on, size: 12.sp, color: statusColor),
                          SizedBox(width: 4.w),
                        ],
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
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
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (durationStr.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: Color(0xFF3B82F6)),
                      SizedBox(width: 4.w),
                      Text(
                        durationStr,
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 4.h),
              if (dateStr.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    // Only allow swipe-to-delete if "Waiting" (tuluv == 0)
    if (tuluv == 0) {
      return Dismissible(
        key: Key(guest['_id']?.toString() ?? UniqueKey().toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          await _deleteInvitation(guest);
          return false; // We return false because _deleteInvitation handles the logic and refresh
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Custom formatter for Mongolian car plates: 4 digits + 3 letters
class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    String result = '';

    for (int i = 0; i < text.length && i < 7; i++) {
      final char = text[i];
      if (i < 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          result += char;
        }
      } else {
        // Last 3 characters must be letters (Cyrillic or Latin)
        if (RegExp(r'[А-ЯӨҮЁA-Z]').hasMatch(char)) {
          result += char;
        }
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
