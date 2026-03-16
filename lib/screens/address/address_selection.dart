import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';

class AddressSelectionScreen extends StatefulWidget {
  final bool fromMenu;

  const AddressSelectionScreen({super.key, this.fromMenu = false});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final TextEditingController _doorNoController = TextEditingController();
  
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _khoroos = [];
  List<Map<String, dynamic>> _buildings = [];
  
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedKhoroo;
  Map<String, dynamic>? _selectedBuilding;
  Map<String, dynamic>? _selectedWalletCustomer;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isTootValid = false;
  String? _tootValidationError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final cities = await ApiService.getWalletCities();
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
      
      // Auto-select Ulaanbaatar if available
      final ulaanbaatar = cities.firstWhere(
        (c) => c['name']?.toString().contains('УЛААНБААТАР') ?? false,
        orElse: () => cities.isNotEmpty ? cities.first : {},
      );
      if (ulaanbaatar.isNotEmpty) {
        _onCitySelected(ulaanbaatar);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showGlassSnackBar(context, message: 'Мэдээлэл авахад алдаа гарлаа', icon: Icons.error);
    }
  }

  Future<void> _onCitySelected(Map<String, dynamic> city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedKhoroo = null;
      _selectedBuilding = null;
      _districts = [];
    });
    
    try {
      final cityId = city['id']?.toString() ?? city['_id']?.toString();
      if (cityId != null) {
        final districts = await ApiService.getWalletDistricts(cityId);
        setState(() => _districts = districts);
      }
    } catch (_) {}
  }

  Future<void> _onDistrictSelected(Map<String, dynamic> district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedKhoroo = null;
      _selectedBuilding = null;
      _khoroos = [];
    });
    
    try {
      final districtId = district['id']?.toString() ?? district['_id']?.toString();
      if (districtId != null) {
        final khoroos = await ApiService.getWalletKhoroos(districtId);
        setState(() => _khoroos = khoroos);
      }
    } catch (_) {}
  }

  Future<void> _onKhorooSelected(Map<String, dynamic> khoroo) async {
    setState(() {
      _selectedKhoroo = khoroo;
      _selectedBuilding = null;
      _buildings = [];
    });
    
    try {
      final khorooId = khoroo['id']?.toString() ?? khoroo['_id']?.toString();
      if (khorooId != null) {
        final buildings = await ApiService.getWalletBuildings(khorooId);
        setState(() => _buildings = _sortBuildingsNumeric(buildings));
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _sortBuildingsNumeric(List<Map<String, dynamic>> buildings) {
    final sorted = List<Map<String, dynamic>>.from(buildings);
    sorted.sort((a, b) {
      final aName = a['name']?.toString() ?? a['ner']?.toString() ?? '';
      final bName = b['name']?.toString() ?? b['ner']?.toString() ?? '';
      return _numericCompare(aName, bName);
    });
    return sorted;
  }

  static const Map<String, String> _districtFullNames = {
    'ХУД': 'Хан-Уул дүүрэг',
    'БГД': 'Баянгол дүүрэг',
    'БЗД': 'Баянзүрх дүүрэг',
    'СБД': 'Сүхбаатар дүүрэг',
    'СХД': 'Сонгинохайрхан дүүрэг',
    'ЧД': 'Чингэлтэй дүүрэг',
    'НАЛАЙХ': 'Налайх дүүрэг',
    'БАГАНУУР': 'Багануур дүүрэг',
    'БАГАХАНГАЙ': 'Багахангай дүүрэг',
  };

  String _getDistrictDisplayName(Map<String, dynamic>? district) {
    if (district == null) return 'Сонгох';
    final rawName = (district['districtName'] ?? district['name'] ?? '').toString().toUpperCase();
    return _districtFullNames[rawName] ?? rawName;
  }

  int _numericCompare(String a, String b) {
    final aStr = a.toLowerCase();
    final bStr = b.toLowerCase();
    
    final RegExp regExp = RegExp(r'(\d+|\D+)');
    final Iterable<Match> aMatches = regExp.allMatches(aStr);
    final Iterable<Match> bMatches = regExp.allMatches(bStr);
    
    final List<String> aParts = aMatches.map((m) => m.group(0)!).toList();
    final List<String> bParts = bMatches.map((m) => m.group(0)!).toList();
    
    final int minLen = aParts.length < bParts.length ? aParts.length : bParts.length;
    
    for (int i = 0; i < minLen; i++) {
      final aPart = aParts[i];
      final bPart = bParts[i];
      
      final bool aIsDigit = RegExp(r'^\d+$').hasMatch(aPart);
      final bool bIsDigit = RegExp(r'^\d+$').hasMatch(bPart);
      
      if (aIsDigit && bIsDigit) {
        final int aNum = int.parse(aPart);
        final int bNum = int.parse(bPart);
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        if (aPart != bPart) return aPart.compareTo(bPart);
      }
    }
    
    return aParts.length.compareTo(bParts.length);
  }

  Future<void> _onBuildingSelected(Map<String, dynamic> building) async {
    setState(() {
      _selectedBuilding = building;
      _doorNoController.clear();
      _isTootValid = building['source'] != 'OWN_ORG';
      _selectedWalletCustomer = null;
    });
  }

  Future<void> _handleAddressSubmit() async {
    if (_selectedBuilding == null || _doorNoController.text.isEmpty) {
      showGlassSnackBar(context, message: 'Мэдээллээ бүрэн оруулна уу', icon: Icons.warning);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final source = _selectedBuilding!['source']?.toString();
      final bairId = _selectedBuilding!['id']?.toString() ?? _selectedBuilding!['_id']?.toString();
      final doorNo = _doorNoController.text.trim();

      if (source == 'OWN_ORG') {
        final baiguullagiinId = _selectedBuilding!['baiguullagiinId']?.toString();
        final barilgiinId = _selectedBuilding!['barilgiinId']?.toString() ?? bairId;
        
        final validate = await ApiService.validateOwnOrgToot(
          toot: doorNo,
          baiguullagiinId: baiguullagiinId!,
          barilgiinId: barilgiinId!,
        );
        
        if (validate['valid'] != true) {
          throw Exception(validate['message'] ?? 'Тоот буруу байна');
        }
      } else if (source == 'WALLET_API' && _selectedWalletCustomer == null) {
        // Fetch customers if not yet selected for Wallet API
        final customers = await ApiService.getWalletCustomersByAddress(bairId: bairId!, doorNo: doorNo);
        if (customers.isEmpty) throw Exception('Хаяг олдсонгүй');
        
        if (customers.length == 1) {
          _selectedWalletCustomer = customers[0];
        } else {
          setState(() => _isSaving = false);
          _showMultiAccountSelection(customers);
          return;
        }
      }

      // Save logic (simplified for the refactor but keeping same functionality)
      await StorageService.saveWalletAddress(
        bairId: bairId!,
        doorNo: doorNo,
        source: source,
        baiguullagiinId: _selectedBuilding!['baiguullagiinId']?.toString(),
        barilgiinId: _selectedBuilding!['barilgiinId']?.toString() ?? bairId,
        customerId: _selectedWalletCustomer?['customerId']?.toString(),
        customerName: _selectedWalletCustomer?['customerName']?.toString(),
      );

      // Connect billing
      await ApiService.fetchWalletBilling(
        bairId: bairId,
        doorNo: doorNo,
        baiguullagiinId: _selectedBuilding!['baiguullagiinId']?.toString(),
        customerId: _selectedWalletCustomer?['customerId']?.toString(),
      );

      if (mounted) {
        showGlassSnackBar(context, message: 'Амжилттай хадгалагдлаа', icon: Icons.check_circle, iconColor: Colors.green);
        context.go('/nuur');
      }
    } catch (e) {
      showGlassSnackBar(context, message: e.toString().replaceFirst('Exception: ', ''), icon: Icons.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMultiAccountSelection(List<Map<String, dynamic>> customers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Хэрэглэгч сонгох', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ...customers.map((c) => ListTile(
              title: Text(c['customerName'] ?? 'Нэргүй'),
              subtitle: Text(c['customerAddress'] ?? ''),
              onTap: () {
                setState(() => _selectedWalletCustomer = c);
                Navigator.pop(context);
                _handleAddressSubmit();
              },
            )),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Хаяг тохируулах',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomPaint(
        painter: SharedBgPainter(isDark: isDark, brandColor: AppColors.deepGreen),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
                child: Column(
                  children: [
                    _buildHeader(isDark),
                    SizedBox(height: 32.h),
                    _buildSelectionForm(isDark),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.deepGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.location_on_rounded, color: AppColors.deepGreen, size: 32.sp),
        ),
        SizedBox(height: 16.h),
        Text(
          'Үйлчилгээ авах хаягаа сонгоно уу',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Таны сонгосон хаягт үндэслэн биллинг болон бусад үйлчилгээ харагдах болно.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionForm(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSelectionField(
            label: 'Хот / Аймаг',
            value: _selectedCity?['name'] ?? 'Сонгох',
            icon: Icons.location_city_rounded,
            onTap: () => _showPicker('Хот / Аймаг сонгох', _cities, (val) => _onCitySelected(val)),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Дүүрэг / Сум',
            value: _getDistrictDisplayName(_selectedDistrict),
            icon: Icons.map_rounded,
            onTap: _selectedCity == null ? null : () => _showPicker('Дүүрэг сонгох', _districts, (val) => _onDistrictSelected(val)),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Хороо / Баг',
            value: _selectedKhoroo?['name'] ?? 'Сонгох',
            icon: Icons.explore_rounded,
            onTap: _selectedDistrict == null ? null : () => _showPicker('Хороо сонгох', _khoroos, (val) => _onKhorooSelected(val)),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Барилга / Хотхон',
            value: _selectedBuilding?['name'] ?? _selectedBuilding?['ner'] ?? 'Сонгох',
            icon: Icons.apartment_rounded,
            onTap: _selectedKhoroo == null ? null : () => _showPicker('Барилга сонгох', _buildings, (val) => _onBuildingSelected(val), showSearch: true),
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          _buildDoorNoField(isDark),
        ],
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final isSelected = value != 'Сонгох';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: onTap == null ? Colors.transparent : (isSelected ? AppColors.deepGreen.withOpacity(0.3) : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: isSelected ? AppColors.deepGreen : (isDark ? Colors.white24 : Colors.grey)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.white38 : Colors.grey)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: onTap == null ? (isDark ? Colors.white12 : Colors.grey.shade400) : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: isDark ? Colors.white24 : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorNoField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Хаалганы дугаар / Тоот', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
        SizedBox(height: 8.h),
        TextField(
          controller: _doorNoController,
          keyboardType: TextInputType.text,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Жишээ: 101',
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleAddressSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 4,
          shadowColor: AppColors.deepGreen.withOpacity(0.4),
        ),
        child: _isSaving
            ? SizedBox(width: 24.r, height: 24.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Хадгалах', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPicker(String title, List<Map<String, dynamic>> items, Function(Map<String, dynamic>) onSelected, {bool showSearch = true}) {
    List<Map<String, dynamic>> filteredItems = List.from(items);
    
    // Initial sort
    filteredItems.sort((a, b) {
      final nameA = title.contains('Дүүрэг') ? _getDistrictDisplayName(a) : (a['name'] ?? a['ner'] ?? '').toString();
      final nameB = title.contains('Дүүрэг') ? _getDistrictDisplayName(b) : (b['name'] ?? b['ner'] ?? '').toString();
      return _numericCompare(nameA, nameB);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = context.isDarkMode;
          final primaryColor = AppColors.deepGreen;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                ),
                if (showSearch)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: TextField(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'Хайх...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14.sp),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            if (val.isEmpty) {
                              filteredItems = List.from(items);
                            } else {
                              final query = val.toLowerCase();
                              filteredItems = items.where((i) {
                                final name = (title.contains('Дүүрэг') 
                                    ? _getDistrictDisplayName(i)
                                    : (i['name'] ?? i['ner'] ?? '').toString()).toLowerCase();
                                return name.contains(query);
                              }).toList();
                            }
                            
                            filteredItems.sort((a, b) {
                              final nameA = title.contains('Дүүрэг') ? _getDistrictDisplayName(a) : (a['name'] ?? a['ner'] ?? '').toString();
                              final nameB = title.contains('Дүүрэг') ? _getDistrictDisplayName(b) : (b['name'] ?? b['ner'] ?? '').toString();
                              
                              if (val.isNotEmpty) {
                                final lowA = nameA.toLowerCase();
                                final lowB = nameB.toLowerCase();
                                final lowQuery = val.toLowerCase();
                                
                                bool startsA = lowA.startsWith(lowQuery);
                                bool startsB = lowB.startsWith(lowQuery);
                                
                                if (startsA && !startsB) return -1;
                                if (!startsA && startsB) return 1;
                              }
                              
                              return _numericCompare(nameA, nameB);
                            });
                          });
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) => SizedBox(height: 4.h),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final name = title.contains('Дүүрэг') 
                          ? _getDistrictDisplayName(item)
                          : (item['name'] ?? item['ner'] ?? '');
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    title.contains('Барилга') ? Icons.apartment_rounded : Icons.location_on_rounded,
                                    size: 18.sp,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          );
        }
      ),
    );
  }
}
