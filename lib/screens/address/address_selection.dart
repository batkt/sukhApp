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
import 'package:sukh_app/widgets/standard_app_bar.dart';

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
  bool _isFetchingDistricts = false;
  bool _isFetchingKhoroos = false;
  bool _isFetchingBuildings = false;
  bool _isFetchingToots = false;
  
  bool _isTootValid = false;
  List<String> _toots = [];
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
      showGlassSnackBar(
        context,
        message: 'Мэдээлэл авахад алдаа гарлаа',
        icon: Icons.error,
      );
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
        setState(() => _isFetchingDistricts = true);
        final districts = await ApiService.getWalletDistricts(cityId);
        setState(() {
          _districts = districts;
          _isFetchingDistricts = false;
        });
      }
    } catch (_) {
      setState(() => _isFetchingDistricts = false);
    }
  }

  Future<void> _onDistrictSelected(Map<String, dynamic> district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedKhoroo = null;
      _selectedBuilding = null;
      _khoroos = [];
    });

    try {
      final districtId =
          district['id']?.toString() ?? district['_id']?.toString();
      if (districtId != null) {
        setState(() => _isFetchingKhoroos = true);
        final khoroos = await ApiService.getWalletKhoroos(districtId);
        // Filter out "0-р хороо" or similar placeholder entries
        setState(() {
          _khoroos =
              khoroos.where((k) {
                final name = (k['name'] ?? k['khorooName'] ?? '')
                    .toString()
                    .trim();
                return name != '0-р хороо' && name != '0';
              }).toList()..sort(
                (a, b) => _numericCompare(
                  _getKhorooDisplayName(a),
                  _getKhorooDisplayName(b),
                ),
              );
          _isFetchingKhoroos = false;
        });
      }
    } catch (_) {
      setState(() => _isFetchingKhoroos = false);
    }
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
        setState(() => _isFetchingBuildings = true);
        final buildings = await ApiService.getWalletBuildings(khorooId);
        setState(() {
          _buildings = _sortBuildingsNumeric(buildings);
          _isFetchingBuildings = false;
        });
      }
    } catch (_) {
      setState(() => _isFetchingBuildings = false);
    }
  }

  List<Map<String, dynamic>> _sortBuildingsNumeric(
    List<Map<String, dynamic>> buildings,
  ) {
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
    final rawName = (district['districtName'] ?? district['name'] ?? '')
        .toString()
        .toUpperCase();
    return _districtFullNames[rawName] ?? rawName;
  }

  String _getKhorooDisplayName(Map<String, dynamic>? khoroo) {
    if (khoroo == null) return 'Сонгох';
    String name =
        (khoroo['name'] ?? khoroo['khorooName'] ?? khoroo['ner'] ?? '')
            .toString();

    for (final entry in _districtFullNames.entries) {
      if (name.toUpperCase().startsWith(entry.key)) {
        return name.replaceFirst(
          RegExp(entry.key, caseSensitive: false),
          entry.value,
        );
      }
    }

    return name;
  }

  int _numericCompare(String a, String b) {
    final aStr = a.toLowerCase();
    final bStr = b.toLowerCase();

    final RegExp regExp = RegExp(r'(\d+|\D+)');
    final Iterable<Match> aMatches = regExp.allMatches(aStr);
    final Iterable<Match> bMatches = regExp.allMatches(bStr);

    final List<String> aParts = aMatches.map((m) => m.group(0)!).toList();
    final List<String> bParts = bMatches.map((m) => m.group(0)!).toList();

    final int minLen = aParts.length < bParts.length
        ? aParts.length
        : bParts.length;

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
      _toots = [];
    });

    try {
      final bairId = building['id']?.toString() ?? building['_id']?.toString();
      if (bairId != null) {
        setState(() => _isFetchingToots = true);
        final toots = await ApiService.getWalletToots(bairId);
        setState(() {
          _toots = toots;
          _isFetchingToots = false;
        });
      }
    } catch (_) {
      setState(() => _isFetchingToots = false);
    }
  }

  Future<void> _handleAddressSubmit() async {
    // Prevent double submissions
    if (_isSaving) {
      print('🔍 [DEBUG] Already submitting, ignoring duplicate call');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_selectedBuilding == null || _doorNoController.text.isEmpty) {
        showGlassSnackBar(
          context,
          message: 'Мэдээллээ бүрэн оруулна уу',
          icon: Icons.warning,
        );
        return;
      }

      final source = _selectedBuilding!['source']?.toString();
      final bairId =
          _selectedBuilding!['id']?.toString() ??
          _selectedBuilding!['_id']?.toString();
      final doorNo = _doorNoController.text.trim();

      if (source == 'OWN_ORG') {
        final baiguullagiinId = _selectedBuilding!['baiguullagiinId']
            ?.toString();
        final barilgiinId =
            _selectedBuilding!['barilgiinId']?.toString() ?? bairId;

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
        final customers = await ApiService.getWalletCustomersByAddress(
          bairId: bairId!,
          doorNo: doorNo,
        );
        
        if (customers.isEmpty) {
          final manualCode = await _showManualCodeDialog();
          if (manualCode != null && manualCode.isNotEmpty) {
            // Create a pseudo-customer object for manual entry
            _selectedWalletCustomer = {
              'customerId': manualCode,
              'customerCode': manualCode,
              'customerName': 'Гар аргаар оруулсан ($manualCode)',
            };
          } else {
            throw Exception('Хаяг олдсонгүй');
          }
        } else {
          if (customers.length == 1) {
            _selectedWalletCustomer = customers[0];
          } else {
            // Don't reset _isSaving here - maintain it through customer selection
            final selectedCustomer = await _showMultiAccountSelection(customers);
            if (selectedCustomer != null) {
              setState(() => _selectedWalletCustomer = selectedCustomer);
              // Continue with the same submission
            } else {
              // User cancelled selection
              setState(() => _isSaving = false);
              return;
            }
          }
        }
      }

      // Ensure we have a customer before proceeding
      if (_selectedWalletCustomer == null && source == 'WALLET_API') {
        // This case should ideally not be reached if the logic is correct
        throw Exception('Хэрэглэгч сонгоогүй байна.');
      }

      // Use the selected customer's customerId directly
      final customerId = _selectedWalletCustomer?['customerId']?.toString();

      if (customerId == null || customerId.isEmpty) {
        throw Exception('Хэрэглэгчийн ID олдсонгүй.');
      }

      // The fetchWalletBilling API call handles adding the address to the user's toots array on the backend.
      // The response from this API will contain the updated user profile, which is then saved.

      print('🔍 [DEBUG] Sending to fetchWalletBilling:');
      print('   - bairId: $bairId');
      print('   - doorNo: $doorNo');
      print('   - customerId: $customerId');
      print('   - customerCode: ${_selectedWalletCustomer?['customerCode']}');
      print('   - customerName: ${_selectedWalletCustomer?['customerName']}');

      final response = await ApiService.fetchWalletBilling(
        bairId: bairId!,
        doorNo: doorNo,
        baiguullagiinId: _selectedBuilding!['baiguullagiinId']?.toString(),
        customerId: customerId,
        customerCode: _selectedWalletCustomer?['customerCode']?.toString(),
        // Pass resident name to be saved in the new toot entry
        ovog: _selectedWalletCustomer?['ovog']?.toString(),
        ner: _selectedWalletCustomer?['ner']?.toString(),
      );

      print('🔍 [DEBUG] Response from fetchWalletBilling:');
      print('   - billingInfo: ${response['billingInfo']}');

      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Амжилттай хадгалагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        if (widget.fromMenu) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/nuur');
          }
        } else {
          // Check for onboarding
          final taniltsuulgaKharakhEsekh =
              await StorageService.getTaniltsuulgaKharakhEsekh();
          if (mounted) {
            if (taniltsuulgaKharakhEsekh) {
              context.go('/ekhniikh');
            } else {
              context.go('/nuur');
            }
          }
        }
      }
    } catch (e) {
      showGlassSnackBar(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<Map<String, dynamic>?> _showMultiAccountSelection(
    List<Map<String, dynamic>> customers,
  ) {
    return showModalBottomSheet<Map<String, dynamic>?>(
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
            Text('Хэрэглэгч сонгох', style: TextStyle(fontSize: 18.sp)),
            SizedBox(height: 16.h),
            ...customers.map(
              (c) => ListTile(
                title: Text(c['customerName'] ?? 'Нэргүй'),
                subtitle: Text(c['customerAddress'] ?? ''),
                onTap: () {
                  Navigator.pop(context, c); // Return the selected customer
                },
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<String?> _showManualCodeDialog() {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Хаяг олдсонгүй'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Бид таны оруулсан хаягаар мэдээлэл олсонгүй. Та хэрэглэгчийн кодоо гараар оруулах уу?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Хэрэглэгчийн код / Гэрээний №',
                hintText: 'Жишээ: 1234567',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Оруулах'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildStandardAppBar(context, title: 'Хаяг тохируулах'),
      body: CustomPaint(
        painter: SharedBgPainter(
          isDark: isDark,
          brandColor: AppColors.deepGreen,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
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
          child: Icon(
            Icons.location_on_rounded,
            color: AppColors.deepGreen,
            size: 32.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Үйлчилгээ авах хаягаа сонгоно уу',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
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
            onTap: () => _showPicker(
              'Хот / Аймаг сонгох',
              () => _cities,
              (val) => _onCitySelected(val),
            ),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Дүүрэг / Сум',
            value: _getDistrictDisplayName(_selectedDistrict),
            icon: Icons.map_rounded,
            isLoading: _isFetchingDistricts,
            onTap: _selectedCity == null || _isFetchingDistricts
                ? null
                : () => _showPicker(
                    'Дүүрэг сонгох',
                    () => _districts,
                    (val) => _onDistrictSelected(val),
                  ),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Хороо / Баг',
            value: _getKhorooDisplayName(_selectedKhoroo),
            icon: Icons.explore_rounded,
            isLoading: _isFetchingKhoroos,
            onTap: _selectedDistrict == null || _isFetchingKhoroos
                ? null
                : () => _showPicker(
                    'Хороо сонгох',
                    () => _khoroos,
                    (val) => _onKhorooSelected(val),
                  ),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildSelectionField(
            label: 'Барилга / Хотхон',
            value:
                _selectedBuilding?['name'] ??
                _selectedBuilding?['ner'] ??
                'Сонгох',
            icon: Icons.apartment_rounded,
            isLoading: _isFetchingBuildings,
            onTap: _selectedKhoroo == null || _isFetchingBuildings
                ? null
                : () => _showPicker(
                    'Барилга сонгох',
                    () => _buildings,
                    (val) => _onBuildingSelected(val),
                    showSearch: true,
                  ),
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
    bool isLoading = false,
  }) {
    final isSelected = value != 'Сонгох';
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: onTap == null
                ? Colors.transparent
                : (isSelected
                      ? AppColors.deepGreen.withOpacity(0.3)
                      : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected
                  ? AppColors.deepGreen
                  : (isDark ? Colors.white24 : Colors.grey),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: onTap == null
                          ? (isDark ? Colors.white12 : Colors.grey.shade400)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading) ...[
              SizedBox(width: 8.w),
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.deepGreen,
                ),
              ),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: isDark ? Colors.white24 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorNoField(bool isDark) {
    if (_toots.isNotEmpty) {
      return _buildSelectionField(
        label: 'Хаалганы дугаар / Тоот',
        value: _doorNoController.text.isEmpty ? 'Сонгох' : _doorNoController.text,
        icon: Icons.meeting_room_rounded,
        isLoading: _isFetchingToots,
        onTap: _selectedBuilding == null || _isFetchingToots
            ? null
            : () => _showTootPicker(),
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Хаалганы дугаар / Тоот',
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (_isFetchingToots) ...[
              SizedBox(width: 8.w),
              SizedBox(
                width: 12.r,
                height: 12.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.deepGreen,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _doorNoController,
          keyboardType: TextInputType.text,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Жишээ: 101',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  void _showTootPicker() {
    _showPicker(
      'Тоот сонгох',
      () => _toots.map((t) => {'name': t}).toList(),
      (val) {
        setState(() {
          _doorNoController.text = val['name'].toString();
        });
      },
      showSearch: true,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 4,
          shadowColor: AppColors.deepGreen.withOpacity(0.4),
        ),
        child: _isSaving
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text('Хадгалах', style: TextStyle(fontSize: 16.sp)),
      ),
    );
  }

  void _showPicker(
    String title,
    List<Map<String, dynamic>> Function() getItems,
    Function(Map<String, dynamic>) onSelected, {
    bool showSearch = true,
  }) {
    List<Map<String, dynamic>> filteredItems = List.from(getItems());

    void updateFilteredItems(String query) {
      final items = getItems();
      if (query.isEmpty) {
        filteredItems = List.from(items);
      } else {
        final lowQuery = query.toLowerCase();
        filteredItems = items.where((i) {
          final name = (title.contains('Дүүрэг')
                  ? _getDistrictDisplayName(i)
                  : (title.contains('Хороо')
                      ? _getKhorooDisplayName(i)
                      : (i['name'] ?? i['ner'] ?? '').toString()))
              .toLowerCase();
          return name.contains(lowQuery);
        }).toList();
      }

      filteredItems.sort((a, b) {
        final nameA = title.contains('Дүүрэг')
            ? _getDistrictDisplayName(a)
            : (title.contains('Хороо')
                ? _getKhorooDisplayName(a)
                : (a['name'] ?? a['ner'] ?? '').toString());
        final nameB = title.contains('Дүүрэг')
            ? _getDistrictDisplayName(b)
            : (title.contains('Хороо')
                ? _getKhorooDisplayName(b)
                : (b['name'] ?? b['ner'] ?? '').toString());

        if (query.isNotEmpty) {
          final lowA = nameA.toLowerCase();
          final lowB = nameB.toLowerCase();
          final lowQuery = query.toLowerCase();

          bool startsA = lowA.startsWith(lowQuery);
          bool startsB = lowB.startsWith(lowQuery);

          if (startsA && !startsB) return -1;
          if (!startsA && startsB) return 1;
        }

        return _numericCompare(nameA, nameB);
      });
    }

    // Initial sort
    updateFilteredItems('');

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
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSearch)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: TextField(
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Хайх...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: primaryColor,
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 15.h,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            updateFilteredItems(val);
                          });
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) => SizedBox(height: 4.h),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final name = title.contains('Дүүрэг')
                          ? _getDistrictDisplayName(item)
                          : (title.contains('Хороо')
                                ? _getKhorooDisplayName(item)
                                : (item['name'] ?? item['ner'] ?? ''));

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
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
                                    title.contains('Барилга')
                                        ? Icons.apartment_rounded
                                        : Icons.location_on_rounded,
                                    size: 18.sp,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black87,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
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
        },
      ),
    );
  }
}
