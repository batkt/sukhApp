import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';

class ZochinUrikhPage extends StatefulWidget {
  const ZochinUrikhPage({super.key});

  @override
  State<ZochinUrikhPage> createState() => _ZochinUrikhPageState();
}

class _ZochinUrikhPageState extends State<ZochinUrikhPage> {
  final _formKey = GlobalKey<FormState>();
  final _mashiniiDugaarController = TextEditingController();
  final _ezemshigchiinUtasController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _invitedGuests = [];
  bool _isLoadingHistory = true;
  String? _userPhoneNumber;
  Map<String, dynamic>? _quotaStatus;
  bool _isLoadingQuota = true;
  String? _quotaError;
  bool _hasQuota = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _loadInvitedGuests();
    _loadQuotaStatus();
  }

  Future<void> _loadQuotaStatus() async {
    try {
      if (mounted) setState(() {
        _isLoadingQuota = true;
        _quotaError = null;
      });
      
      final status = await ApiService.fetchZochinQuotaStatus();
      debugPrint('📊 [QUOTA] Received status: $status');
      
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
            _hasQuota = total == 0 || remaining > 0;
          }
          
          _isLoadingQuota = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [QUOTA] Error loading quota status: $e');
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
          final combinedList = ezenList.isNotEmpty ? ezenList : jagsaalt;
          
          setState(() {
            _invitedGuests = List<Map<String, dynamic>>.from(combinedList);
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingHistory = false);
        }
      }
    } catch (e) {
      print('Error loading invited guests: $e');
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
                        inputFormatters: [
                          CarPlateFormatter(),
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
              
              // History section
              Text(
                'Урьсан зочдын түүх',
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
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 10,
              )),
              
              if (_isLoadingHistory)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.deepGreen,
                    ),
                  ),
                )
              else if (_invitedGuests.isEmpty)
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: context.responsivePadding(
                      small: 28,
                      medium: 32,
                      large: 36,
                      tablet: 40,
                      veryNarrow: 20,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 10,
                      )),
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: context.responsiveIconSize(
                            small: 40,
                            medium: 44,
                            large: 48,
                            tablet: 52,
                            veryNarrow: 36,
                          ),
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: context.responsiveSpacing(
                          small: 10,
                          medium: 12,
                          large: 14,
                          tablet: 16,
                          veryNarrow: 8,
                        )),
                        Text(
                          'Урьсан зочин байхгүй',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Center(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _invitedGuests.length,
                    separatorBuilder: (context, index) => SizedBox(height: context.responsiveSpacing(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                      veryNarrow: 8,
                    )),
                    itemBuilder: (context, index) {
                      final guest = _invitedGuests[index];
                      return _buildGuestCard(guest);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
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
          _invitedGuests.removeWhere((item) => item['_id'] == id);
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
    final mashiniiDugaar = guest['urisanMashiniiDugaar'] ?? guest['mashiniiDugaar'] ?? '-';
    final rawDate = guest['ognoo'] ?? guest['createdAt'] ?? guest['ognooStr'];
    final tuluv = guest['tuluv'] ?? 0;
    String dateStr = '';
    
    if (rawDate != null) {
      try {
        final date = DateTime.parse(rawDate.toString());
        dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        dateStr = rawDate.toString();
      }
    }

    // Status logic based on documentation
    String statusText = 'Хүлээгдэж буй';
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;

    switch (tuluv) {
      case 0:
        statusText = 'Хүлээгдэж буй';
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 1:
        statusText = 'Зогсоолд байгаа';
        statusColor = Colors.blue;
        statusIcon = Icons.local_parking;
        break;
      case 2:
        statusText = 'Дууссан';
        statusColor = AppColors.deepGreen;
        statusIcon = Icons.check_circle;
        break;
      case -1:
        statusText = 'Цуцлагдсан';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Тодорхойгүй';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    final cardContent = Container(
      padding: context.responsivePadding(
        small: 16,
        medium: 18,
        large: 20,
        tablet: 22,
        veryNarrow: 12,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
          small: 10,
          medium: 12,
          large: 14,
          tablet: 16,
          veryNarrow: 8,
        )),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            )),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 8,
                medium: 10,
                large: 12,
                tablet: 14,
                veryNarrow: 6,
              )),
            ),
            child: Icon(
              Icons.directions_car,
              color: statusColor,
              size: context.responsiveIconSize(
                small: 20,
                medium: 22,
                large: 24,
                tablet: 26,
                veryNarrow: 18,
              ),
            ),
          ),
          SizedBox(width: context.responsiveSpacing(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mashiniiDugaar,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                      veryNarrow: 13,
                    ),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  SizedBox(height: context.responsiveSpacing(
                    small: 3,
                    medium: 4,
                    large: 5,
                    tablet: 6,
                    veryNarrow: 2,
                  )),
                  Text(
                    dateStr,
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
                ],
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: context.responsiveIconSize(
                  small: 18,
                  medium: 20,
                  large: 22,
                  tablet: 24,
                  veryNarrow: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(
                    small: 8,
                    medium: 9,
                    large: 10,
                    tablet: 11,
                    veryNarrow: 7,
                  ),
                  color: statusColor,
                ),
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
class CarPlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && buffer.length < 7; i++) {
      final char = text[i];
      
      if (buffer.length < 4) {
        // First 4 characters must be digits
        if (RegExp(r'[0-9]').hasMatch(char)) {
          buffer.write(char);
        }
      } else {
        // Last 3 characters must be letters (Cyrillic or Latin)
        if (RegExp(r'[A-ZА-Я]').hasMatch(char)) {
          buffer.write(char);
        }
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
