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

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _loadInvitedGuests();
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

  Future<void> _loadInvitedGuests() async {
    try {
      setState(() => _isLoadingHistory = true);
      
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final userId = await StorageService.getUserId();
      
      if (baiguullagiinId != null && userId != null) {
        final response = await ApiService.fetchZochinTuukh(
          baiguullagiinId: baiguullagiinId,
          ezenId: userId,
        );
        
        if (mounted) {
          // Try both 'jagsaalt' and 'tuukh' keys since API might return data in either
          final jagsaalt = response['jagsaalt'] as List? ?? [];
          final tuukh = response['tuukh'] as List? ?? [];
          final combinedList = jagsaalt.isNotEmpty ? jagsaalt : tuukh;
          
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
      
      if (baiguullagiinId == null) {
        throw Exception('Байгууллагын мэдээлэл олдсонгүй');
      }

      await ApiService.zochinHadgalya(
        mashiniiDugaar: _mashiniiDugaarController.text.trim().toUpperCase(),
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        ezemshigchiinUtas: _ezemshigchiinUtasController.text.trim(),
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
        
        // Reload history
        _loadInvitedGuests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.deepGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor,
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5)),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16.sp,
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
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor.withOpacity(0.5),
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5)),
                        ),
                        style: TextStyle(
                          color: context.textPrimaryColor.withOpacity(0.7),
                          fontSize: 16.sp,
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _inviteGuest,
                          icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.person_add_outlined),
                          label: Text(
                            _isLoading ? 'Уриж байна...' : 'Зочин урих',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 17,
                                veryNarrow: 13,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepGreen,
                            foregroundColor: Colors.white,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                      small: 32,
                      medium: 36,
                      large: 40,
                      tablet: 44,
                      veryNarrow: 24,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Урьсан зочин байхгүй',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14.sp,
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
                    separatorBuilder: (context, index) => SizedBox(height: 12),
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

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    final mashiniiDugaar = guest['mashiniiDugaar'] ?? guest['urisanMashiniiDugaar'] ?? '-';
    final createdAt = guest['createdAt'];
    String dateStr = '';
    
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        dateStr = createdAt.toString();
      }
    }
    
    return Container(
      padding: context.responsivePadding(
        small: 16,
        medium: 18,
        large: 20,
        tablet: 22,
        veryNarrow: 12,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.directions_car,
              color: AppColors.deepGreen,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mashiniiDugaar,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    dateStr,
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
            Icons.check_circle,
            color: AppColors.deepGreen,
            size: 20,
          ),
        ],
      ),
    );
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
