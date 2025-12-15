import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final TextEditingController _doorNoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _khoroos = [];
  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _filteredBuildings = [];
  String _searchQuery = '';

  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedKhoroo;
  Map<String, dynamic>? _selectedBuilding;

  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingKhoroos = false;
  bool _isLoadingBuildings = false;
  bool _isSaving = false;
  bool _isValidatingToot = false;
  String? _tootValidationError;
  List<String>? _availableToonuud;
  bool _isTootValid = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
    // Add listener to validate toot when door number changes
    _doorNoController.addListener(() {
      final source = _selectedBuilding?['source']?.toString();
      if (source == 'OWN_ORG') {
        // Debounce validation - validate after user stops typing
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _doorNoController.text == _doorNoController.text) {
            _validateToot(_doorNoController.text);
          }
        });
      } else {
        // Reset validation state for non-OWN_ORG bair
        setState(() {
          _isTootValid = true;
          _tootValidationError = null;
          _availableToonuud = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _doorNoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Numeric sorting function - properly handles numeric sorting
  int _numericCompare(String a, String b) {
    // Try to extract the first number from each string
    final aMatch = RegExp(r'\d+').firstMatch(a);
    final bMatch = RegExp(r'\d+').firstMatch(b);

    // If both have numbers, compare numerically
    if (aMatch != null && bMatch != null) {
      final aNum = int.tryParse(aMatch.group(0) ?? '') ?? 0;
      final bNum = int.tryParse(bMatch.group(0) ?? '') ?? 0;

      // Primary comparison: numeric value
      if (aNum != bNum) {
        return aNum.compareTo(bNum);
      }

      // If numbers are equal, compare the remaining string part
      final aRemaining = a.substring(aMatch.end);
      final bRemaining = b.substring(bMatch.end);
      if (aRemaining != bRemaining) {
        return aRemaining.compareTo(bRemaining);
      }

      // If everything is equal, compare the full string
      return a.compareTo(b);
    }

    // If only one has a number, number comes first
    if (aMatch != null) return -1;
    if (bMatch != null) return 1;

    // If neither has a number, compare as strings
    return a.compareTo(b);
  }

  // Sort buildings numerically
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

  void _filterBuildings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBuildings = _sortBuildingsNumeric(_buildings);
      } else {
        final filtered = _buildings.where((building) {
          final name =
              building['name']?.toString() ?? building['ner']?.toString() ?? '';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();
        _filteredBuildings = _sortBuildingsNumeric(filtered);
      }
    });
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final cities = await ApiService.getWalletCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
        showGlassSnackBar(
          context,
          message: 'Хот авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _khoroos = [];
      _buildings = [];
      _selectedDistrict = null;
      _selectedKhoroo = null;
      _selectedBuilding = null;
    });

    try {
      final districts = await ApiService.getWalletDistricts(cityId);
      if (mounted) {
        setState(() {
          _districts = districts;
          _isLoadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
        showGlassSnackBar(
          context,
          message: 'Дүүрэг авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadKhoroos(String districtId) async {
    setState(() {
      _isLoadingKhoroos = true;
      _khoroos = [];
      _buildings = [];
      _selectedKhoroo = null;
      _selectedBuilding = null;
    });

    try {
      final khoroos = await ApiService.getWalletKhoroos(districtId);
      if (mounted) {
        setState(() {
          _khoroos = khoroos;
          _isLoadingKhoroos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingKhoroos = false;
        });
        showGlassSnackBar(
          context,
          message: 'Хороо авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadBuildings(String khorooId) async {
    setState(() {
      _isLoadingBuildings = true;
      _buildings = [];
      _selectedBuilding = null;
    });

    try {
      final buildings = await ApiService.getWalletBuildings(khorooId);
      if (mounted) {
        // Sort buildings numerically
        final sortedBuildings = _sortBuildingsNumeric(buildings);
        setState(() {
          _buildings = sortedBuildings;
          _filteredBuildings = sortedBuildings;
          _isLoadingBuildings = false;
        });
        // Clear search when new buildings are loaded
        _searchController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBuildings = false;
        });
        showGlassSnackBar(
          context,
          message: 'Барилга авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _validateToot(String toot) async {
    // Only validate if OWN_ORG bair is selected
    if (_selectedBuilding == null) {
      if (mounted) {
        setState(() {
          _isTootValid = false;
          _tootValidationError = null;
          _availableToonuud = null;
        });
      }
      return;
    }

    final source = _selectedBuilding!['source']?.toString();
    if (source != 'OWN_ORG') {
      if (mounted) {
        setState(() {
          _isTootValid = true;
          _tootValidationError = null;
          _availableToonuud = null;
        });
      }
      return;
    }

    if (toot.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isTootValid = false;
          _tootValidationError = null;
          _availableToonuud = null;
        });
      }
      return;
    }

    final baiguullagiinId = _selectedBuilding!['baiguullagiinId']?.toString();
    final barilgiinId =
        _selectedBuilding!['barilgiinId']?.toString() ??
        _selectedBuilding!['id']?.toString();

    if (baiguullagiinId == null || barilgiinId == null) {
      if (mounted) {
        setState(() {
          _tootValidationError = 'Барилгын мэдээлэл дутуу байна';
          _isTootValid = false;
          _isValidatingToot = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isValidatingToot = true;
        _tootValidationError = null;
        _availableToonuud = null;
        _isTootValid = false;
      });
    }

    try {
      final result = await ApiService.validateOwnOrgToot(
        toot: toot.trim(),
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
      );

      if (mounted) {
        setState(() {
          _isValidatingToot = false;
          if (result['valid'] == true) {
            _isTootValid = true;
            _tootValidationError = null;
            _availableToonuud = null;
          } else {
            _isTootValid = false;
            _tootValidationError = result['message'] ?? 'Тоот буруу байна';
            if (result['availableToonuud'] != null &&
                result['availableToonuud'] is List) {
              _availableToonuud = List<String>.from(result['availableToonuud']);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingToot = false;
          _isTootValid = false;
          String errorMsg = e.toString();
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring(11);
          }
          _tootValidationError = errorMsg;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (_selectedBuilding == null || _doorNoController.text.trim().isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Барилга болон хаалганы дугаар сонгоно уу',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // Validate toot for OWN_ORG bair before saving
    final source = _selectedBuilding!['source']?.toString();
    if (source == 'OWN_ORG') {
      if (!_isTootValid) {
        showGlassSnackBar(
          context,
          message: 'Зөв тоот оруулна уу',
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bairId =
          _selectedBuilding!['id']?.toString() ??
          _selectedBuilding!['_id']?.toString();

      if (bairId == null) {
        throw Exception('Барилгын ID олдсонгүй');
      }

      final doorNo = _doorNoController.text.trim();

      // Check if this is an OWN_ORG bair
      final source = _selectedBuilding!['source']?.toString();
      final isOwnOrg = source == 'OWN_ORG';

      String? baiguullagiinId;
      String? barilgiinId;

      if (isOwnOrg) {
        baiguullagiinId = _selectedBuilding!['baiguullagiinId']?.toString();
        barilgiinId = _selectedBuilding!['barilgiinId']?.toString() ?? bairId;

        if (baiguullagiinId == null || baiguullagiinId.isEmpty) {
          throw Exception('OWN_ORG барилгын байгууллагын ID олдсонгүй');
        }
      }

      // Save address to storage (with OWN_ORG fields if applicable)
      await StorageService.saveWalletAddress(
        bairId: bairId,
        doorNo: doorNo,
        source: source,
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
      );

      // If this is OWN_ORG bair and user is logged in, update user profile with OWN_ORG IDs
      if (isOwnOrg && baiguullagiinId != null && barilgiinId != null) {
        final isLoggedIn = await StorageService.isLoggedIn();
        if (isLoggedIn) {
          try {
            // Get user phone number to call login endpoint
            final savedPhone = await StorageService.getSavedPhoneNumber();
            if (savedPhone != null && savedPhone.isNotEmpty) {
              // Call login endpoint again with OWN_ORG IDs to update user profile
              await ApiService.loginUser(
                utas: savedPhone,
                bairId: bairId,
                doorNo: doorNo,
                baiguullagiinId: baiguullagiinId,
                barilgiinId: barilgiinId,
                duureg:
                    _selectedDistrict?['name']?.toString() ??
                    _selectedDistrict?['ner']?.toString(),
                horoo:
                    _selectedKhoroo?['name']?.toString() ??
                    _selectedKhoroo?['ner']?.toString(),
                soh: _selectedKhoroo?['soh']?.toString(),
              );
            }
          } catch (e) {
            // Failed to update user profile with OWN_ORG IDs
            // Don't fail the address save if profile update fails
          }
        }
      }

      // Fetch billing by address and automatically connect it
      // The /walletBillingHavakh endpoint automatically connects billing
      // Include OWN_ORG IDs if this is an OWN_ORG bair
      try {
        final billingResponse = await ApiService.fetchWalletBilling(
          bairId: bairId,
          doorNo: doorNo,
          duureg:
              _selectedDistrict?['name']?.toString() ??
              _selectedDistrict?['ner']?.toString(),
          horoo:
              _selectedKhoroo?['name']?.toString() ??
              _selectedKhoroo?['ner']?.toString(),
          soh: _selectedKhoroo?['soh']?.toString(),
          baiguullagiinId: isOwnOrg ? baiguullagiinId : null,
          barilgiinId: isOwnOrg ? barilgiinId : null,
        );

        // Save billingId if available (for Wallet API)
        if (billingResponse['billingId'] != null) {
          await StorageService.saveWalletBillingId(
            billingResponse['billingId'].toString(),
          );
        } else if (billingResponse['data']?['billingId'] != null) {
          await StorageService.saveWalletBillingId(
            billingResponse['data']['billingId'].toString(),
          );
        }

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          showGlassSnackBar(
            context,
            message: 'Хаяг болон биллингийн мэдээлэл амжилттай хадгалагдлаа',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          context.pop(true);
        }
      } catch (billingError) {
        // Address saved but billing fetch/connect failed - still return success
        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          final errorMessage = billingError.toString().contains('олдсонгүй')
              ? 'Хаяг хадгалагдлаа. Биллингийн мэдээлэл олдсонгүй.'
              : 'Хаяг хадгалагдлаа. Биллинг холбоход алдаа гарлаа: $billingError';

          showGlassSnackBar(
            context,
            message: errorMessage,
            icon: Icons.warning,
            iconColor: Colors.orange,
          );

          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        showGlassSnackBar(
          context,
          message: 'Хаяг хадгалахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  void _showSelectionModal({
    required String title,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selected,
    required Function(Map<String, dynamic>) onSelect,
    String? searchHint,
  }) {
    List<Map<String, dynamic>> filteredItems = items;
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.goldPrimary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                if (searchHint != null)
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12.r,
                            spreadRadius: 0,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (query) {
                          setModalState(() {
                            if (query.isEmpty) {
                              filteredItems = items;
                            } else {
                              filteredItems = items.where((item) {
                                final name =
                                    item['name']?.toString() ??
                                    item['ner']?.toString() ??
                                    '';
                                return name.toLowerCase().contains(
                                  query.toLowerCase(),
                                );
                              }).toList();
                            }
                          });
                        },
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.goldPrimary,
                            size: 22.sp,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 20.sp,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {
                                      filteredItems = items;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.goldPrimary.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // List
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 64.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Олдсонгүй',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final name =
                                item['name']?.toString() ??
                                item['ner']?.toString() ??
                                '';
                            final isSelected =
                                selected != null &&
                                (selected['id']?.toString() ??
                                        selected['_id']?.toString()) ==
                                    (item['id']?.toString() ??
                                        item['_id']?.toString());

                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.goldPrimary.withOpacity(
                                            0.2,
                                          ),
                                          AppColors.goldPrimary.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.08),
                                          Colors.white.withOpacity(0.03),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.goldPrimary.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.15),
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    onSelect(item);
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(18.w),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.goldPrimary,
                                            size: 24.sp,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selected,
    required ValueChanged<Map<String, dynamic>?> onChanged,
    required bool isLoading,
  }) {
    final selectedName = selected != null
        ? (selected['name']?.toString() ?? selected['ner']?.toString() ?? '')
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12.r,
            spreadRadius: 0,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading
              ? null
              : () {
                  _showSelectionModal(
                    title: label,
                    items: items,
                    selected: selected,
                    onSelect: (item) => onChanged(item),
                    searchHint: '$label хайх...',
                  );
                },
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        selectedName ?? 'Сонгох...',
                        style: TextStyle(
                          color: selectedName != null
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.goldPrimary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 24.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Хаяг сонгох',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Хаягаа сонгосноор таны мэдээлэл автоматаар бүртгэгдэнэ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Search Bar
                  if (_selectedKhoroo != null && _buildings.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12.r,
                            spreadRadius: 0,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterBuildings,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: 'Барилга хайх...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.goldPrimary,
                            size: 22.sp,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 20.sp,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterBuildings('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.goldPrimary.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdown(
                      label: 'Хот',
                      items: _cities,
                      selected: _selectedCity,
                      onChanged: (city) {
                        if (city != null) {
                          setState(() {
                            _selectedCity = city;
                          });
                          final cityId =
                              city['id']?.toString() ?? city['_id']?.toString();
                          if (cityId != null && cityId.isNotEmpty) {
                            _loadDistricts(cityId);
                          }
                        }
                      },
                      isLoading: _isLoadingCities,
                    ),
                    if (_selectedCity != null)
                      _buildDropdown(
                        label: 'Дүүрэг',
                        items: _districts,
                        selected: _selectedDistrict,
                        onChanged: (district) {
                          if (district != null) {
                            setState(() {
                              _selectedDistrict = district;
                            });
                            final districtId =
                                district['id']?.toString() ??
                                district['_id']?.toString();
                            if (districtId != null && districtId.isNotEmpty) {
                              _loadKhoroos(districtId);
                            }
                          }
                        },
                        isLoading: _isLoadingDistricts,
                      ),
                    if (_selectedDistrict != null)
                      _buildDropdown(
                        label: 'Хороо',
                        items: _khoroos,
                        selected: _selectedKhoroo,
                        onChanged: (khoroo) {
                          if (khoroo != null) {
                            setState(() {
                              _selectedKhoroo = khoroo;
                            });
                            final khorooId =
                                khoroo['id']?.toString() ??
                                khoroo['_id']?.toString();
                            if (khorooId != null && khorooId.isNotEmpty) {
                              _loadBuildings(khorooId);
                            }
                          }
                        },
                        isLoading: _isLoadingKhoroos,
                      ),
                    if (_selectedKhoroo != null)
                      _buildDropdown(
                        label: 'Барилга',
                        items: _filteredBuildings.isNotEmpty
                            ? _filteredBuildings
                            : _buildings,
                        selected: _selectedBuilding,
                        onChanged: (building) {
                          if (building != null) {
                            setState(() {
                              _selectedBuilding = building;
                              // Reset validation when building changes
                              _isTootValid = false;
                              _tootValidationError = null;
                              _availableToonuud = null;
                            });
                            // If OWN_ORG and door number already entered, validate
                            final source = building['source']?.toString();
                            if (source == 'OWN_ORG' &&
                                _doorNoController.text.trim().isNotEmpty) {
                              _validateToot(_doorNoController.text);
                            } else if (source != 'OWN_ORG') {
                              setState(() {
                                _isTootValid = true;
                              });
                            }
                          }
                        },
                        isLoading: _isLoadingBuildings,
                      ),
                    if (_selectedBuilding != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12.r,
                              spreadRadius: 0,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _doorNoController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            // Validation is handled by the listener in initState
                            // But we can trigger it immediately for better UX
                            final source = _selectedBuilding?['source']
                                ?.toString();
                            if (source == 'OWN_ORG' &&
                                value.trim().isNotEmpty) {
                              _validateToot(value);
                            }
                          },
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Хаалганы дугаар',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.door_front_door_rounded,
                              color: AppColors.goldPrimary,
                              size: 22.sp,
                            ),
                            suffixIcon: _isValidatingToot
                                ? Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.goldPrimary,
                                            ),
                                      ),
                                    ),
                                  )
                                : (_isTootValid &&
                                      _doorNoController.text
                                          .trim()
                                          .isNotEmpty &&
                                      _selectedBuilding?['source']
                                              ?.toString() ==
                                          'OWN_ORG')
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 22.sp,
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 18.h,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18.r),
                              borderSide: BorderSide(
                                color: _tootValidationError != null
                                    ? Colors.red
                                    : AppColors.goldPrimary.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18.r),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18.r),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            errorText: _tootValidationError,
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_selectedBuilding != null &&
                        _tootValidationError != null &&
                        _availableToonuud != null &&
                        _availableToonuud!.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Боломжтой тоотууд:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: _availableToonuud!.map((toot) {
                                return GestureDetector(
                                  onTap: () {
                                    _doorNoController.text = toot;
                                    _validateToot(toot);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.goldPrimary
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      toot,
                                      style: TextStyle(
                                        color: AppColors.goldPrimary,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    GestureDetector(
                      onTap:
                          (_isSaving ||
                              (_selectedBuilding != null &&
                                  _selectedBuilding!['source']?.toString() ==
                                      'OWN_ORG' &&
                                  !_isTootValid &&
                                  _doorNoController.text.trim().isNotEmpty))
                          ? null
                          : _saveAddress,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (_isSaving ||
                                      (_selectedBuilding != null &&
                                          _selectedBuilding!['source']
                                                  ?.toString() ==
                                              'OWN_ORG' &&
                                          !_isTootValid &&
                                          _doorNoController.text
                                              .trim()
                                              .isNotEmpty))
                                  ? AppColors.goldPrimary.withOpacity(0.5)
                                  : AppColors.goldPrimary,
                              (_isSaving ||
                                      (_selectedBuilding != null &&
                                          _selectedBuilding!['source']
                                                  ?.toString() ==
                                              'OWN_ORG' &&
                                          !_isTootValid &&
                                          _doorNoController.text
                                              .trim()
                                              .isNotEmpty))
                                  ? AppColors.goldPrimary.withOpacity(0.4)
                                  : AppColors.goldPrimary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldPrimary.withOpacity(0.3),
                              blurRadius: 20.r,
                              spreadRadius: 0,
                              offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: _isSaving
                            ? Center(
                                child: SizedBox(
                                  height: 22.h,
                                  width: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Хадгалах',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
