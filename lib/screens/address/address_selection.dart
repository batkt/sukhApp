import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

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
  bool _hasBaiguullagiinId = false;
  bool _hasExistingAddress = false;
  bool _isCheckingAddress = true;

  @override
  void initState() {
    super.initState();
    _checkUserAddressStatus();
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

  Future<void> _checkUserAddressStatus() async {
    try {
      // Check if user already has address on the server
      try {
        final profile = await ApiService.getUserProfile();
        if (profile['result'] != null) {
          final userData = profile['result'];
          final walletBairId = userData['walletBairId']?.toString();
          final walletDoorNo = userData['walletDoorNo']?.toString();

          // If user has both walletBairId and walletDoorNo, they already have address
          if (walletBairId != null &&
              walletBairId.isNotEmpty &&
              walletDoorNo != null &&
              walletDoorNo.isNotEmpty) {
            // User already has address - redirect to main page instead of showing the page
            if (mounted) {
              // Use post-frame callback to ensure navigation happens after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Redirect to main page for existing users
                  context.go('/nuur');
                }
              });
            }
            return;
          }
        }
      } catch (e) {
        // Ignore error, continue checking baiguullagiinId
      }

      // Check if user has baiguullagiinId in storage
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId != null && baiguullagiinId.isNotEmpty) {
        // Check if user is already logged in - if so, redirect to main page
        final isLoggedIn = await StorageService.isLoggedIn();
        if (isLoggedIn) {
          // Existing logged-in user with baiguullagiinId - redirect to main page
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go('/nuur');
              }
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _hasBaiguullagiinId = true;
            _isCheckingAddress = false;
          });
        }
      } else {
        // Also check from API profile
        try {
          final profile = await ApiService.getUserProfile();
          if (profile['result']?['baiguullagiinId'] != null &&
              profile['result']['baiguullagiinId'].toString().isNotEmpty) {
            // Check if user is already logged in - if so, redirect to main page
            final isLoggedIn = await StorageService.isLoggedIn();
            if (isLoggedIn) {
              // Existing logged-in user with baiguullagiinId - redirect to main page
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go('/nuur');
                  }
                });
              }
              return;
            }
            if (mounted) {
              setState(() {
                _hasBaiguullagiinId = true;
                _isCheckingAddress = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _isCheckingAddress = false;
              });
            }
          }
        } catch (e) {
          // Ignore error, user doesn't have baiguullagiinId
          if (mounted) {
            setState(() {
              _isCheckingAddress = false;
            });
          }
        }
      }
    } catch (e) {
      // Ignore error
      if (mounted) {
        setState(() {
          _isCheckingAddress = false;
        });
      }
    }
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
    // If user already has address on server or has baiguullagiinId, they don't need to fill address fields
    // Just save and return success
    if (_hasExistingAddress || _hasBaiguullagiinId) {
      setState(() {
        _isSaving = true;
      });

      try {
        // User with baiguullagiinId doesn't need address, just save success
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Small delay for UX

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          showGlassSnackBar(
            context,
            message: 'Мэдээлэл амжилттай хадгалагдлаа',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );

          // Pop with true to indicate success
          context.pop(true);
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
        return;
      }
    }

    // For users without baiguullagiinId, require address fields
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
              // Get saved password for re-login (only if biometric is enabled)
              final savedPassword =
                  await StorageService.getSavedPasswordForBiometric();

              // Only proceed if we have a password (required by backend)
              if (savedPassword != null && savedPassword.isNotEmpty) {
                // Call login endpoint again with OWN_ORG IDs to update user profile
                await ApiService.loginUser(
                  utas: savedPhone,
                  nuutsUg: savedPassword,
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
              // Note: If password is not available, we skip the profile update
              // The address is already saved, so this is not critical
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

          // Only pop with true if save was successful
          if (mounted) {
            context.pop(true);
          }
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

          // Only pop with true if address was saved (even if billing failed)
          if (mounted) {
            context.pop(true);
          }
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
          final isDark = context.isDarkMode;
          return Container(
            height: context.responsiveModalHeight(
              small: 0.8,
              medium: 0.75,
              large: 0.70,
              tablet: 0.65,
            ),
            constraints: BoxConstraints(
              maxHeight: context.isTablet ? 700.h : double.infinity,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? context.cardBackgroundColor
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  context.responsiveBorderRadius(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                  ),
                ),
                topRight: Radius.circular(
                  context.responsiveBorderRadius(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                  ),
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: context
                      .responsiveHorizontalPadding(
                        small: 20,
                        medium: 24,
                        large: 28,
                        tablet: 32,
                      )
                      .copyWith(
                        top: context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                        ),
                        bottom: context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                        ),
                      ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.surfaceElevatedColor
                        : AppColors.lightSurface,
                    border: Border(
                      bottom: BorderSide(color: context.borderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: context.textPrimaryColor,
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
                            color: context.accentBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: context.textPrimaryColor,
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
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 15.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.deepGreen,
                            size: 22.sp,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: context.textSecondaryColor,
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
                          fillColor: context.cardBackgroundColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: context.borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.deepGreen.withOpacity(0.8),
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
                                color: context.textSecondaryColor,
                                size: 64.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Олдсонгүй',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
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
                                color: isSelected
                                    ? AppColors.deepGreen.withOpacity(0.2)
                                    : context.cardBackgroundColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.deepGreen.withOpacity(0.5)
                                      : context.borderColor,
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
                                              color: context.textPrimaryColor,
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
                                            color: AppColors.deepGreen,
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
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.borderColor, width: 1.5),
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
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        selectedName ?? 'Сонгох...',
                        style: TextStyle(
                          color: selectedName != null
                              ? context.textPrimaryColor
                              : context.textSecondaryColor,
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
                    color: context.textSecondaryColor,
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
    // If checking address status, show loading (will auto-pop if address exists)
    if (_isCheckingAddress) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Хаяг сонгох',
        onBackPressed: () {
          // Navigate back to login screen
          context.pop(false);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subtitle
            Container(
              padding: context
                  .responsiveHorizontalPadding(
                    small: 20,
                    medium: 24,
                    large: 28,
                    tablet: 32,
                  )
                  .copyWith(
                    top: context.responsiveSpacing(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                    ),
                    bottom: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 24,
                    ),
                  ),
              child: Text(
                (_hasExistingAddress || _hasBaiguullagiinId)
                    ? 'Таны хаягийн мэдээлэл автоматаар хадгалагдах тул хадгалах товч дарж үргэлжлүүлнэ үү'
                    : 'Хаягаа сонгосноор таны мэдээлэл автоматаар бүртгэгдэнэ',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: context.responsiveFontSize(
                    small: 13,
                    medium: 14,
                    large: 15,
                    tablet: 16,
                  ),
                ),
              ),
            ),
            // Search Bar
            if (_selectedKhoroo != null && _buildings.isNotEmpty) ...[
              Padding(
                padding: context.responsiveHorizontalPadding(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                ),
                child: SizedBox(
                  height: context.responsiveSpacing(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                  ),
                ),
              ),
              Padding(
                padding: context.responsiveHorizontalPadding(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 16,
                        medium: 18,
                        large: 20,
                        tablet: 22,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: context.responsiveSpacing(
                          small: 12,
                          medium: 14,
                          large: 16,
                          tablet: 18,
                        ),
                        spreadRadius: 0,
                        offset: Offset(
                          0,
                          context.responsiveSpacing(
                            small: 4,
                            medium: 5,
                            large: 6,
                            tablet: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterBuildings,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 15,
                        medium: 16,
                        large: 17,
                        tablet: 18,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Барилга хайх...',
                      hintStyle: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 15,
                          medium: 16,
                          large: 17,
                          tablet: 18,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.deepGreen,
                        size: context.responsiveIconSize(
                          small: 22,
                          medium: 24,
                          large: 26,
                          tablet: 28,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: context.textSecondaryColor,
                                size: context.responsiveIconSize(
                                  small: 20,
                                  medium: 22,
                                  large: 24,
                                  tablet: 26,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterBuildings('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.cardBackgroundColor,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(
                          small: 20,
                          medium: 22,
                          large: 24,
                          tablet: 26,
                        ),
                        vertical: context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 22,
                          ),
                        ),
                        borderSide: BorderSide(
                          color: context.borderColor,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 22,
                          ),
                        ),
                        borderSide: BorderSide(
                          color: AppColors.deepGreen.withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: context.responsivePadding(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Only show address fields if user doesn't have existing address or baiguullagiinId
                    if (!_hasExistingAddress && !_hasBaiguullagiinId) ...[
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
                                city['id']?.toString() ??
                                city['_id']?.toString();
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
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 8,
                            medium: 10,
                            large: 12,
                            tablet: 14,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: context.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 18,
                                medium: 20,
                                large: 22,
                                tablet: 24,
                              ),
                            ),
                            border: Border.all(
                              color: context.borderColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: context.responsiveSpacing(
                                  small: 12,
                                  medium: 14,
                                  large: 16,
                                  tablet: 18,
                                ),
                                spreadRadius: 0,
                                offset: Offset(
                                  0,
                                  context.responsiveSpacing(
                                    small: 4,
                                    medium: 5,
                                    large: 6,
                                    tablet: 7,
                                  ),
                                ),
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
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 16,
                                medium: 17,
                                large: 18,
                                tablet: 19,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Хаалганы дугаар',
                              labelStyle: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 14,
                                  medium: 15,
                                  large: 16,
                                  tablet: 17,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Icon(
                                Icons.door_front_door_rounded,
                                color: AppColors.deepGreen,
                                size: context.responsiveIconSize(
                                  small: 22,
                                  medium: 24,
                                  large: 26,
                                  tablet: 28,
                                ),
                              ),
                              suffixIcon: _isValidatingToot
                                  ? Padding(
                                      padding: EdgeInsets.all(
                                        context.responsiveSpacing(
                                          small: 12,
                                          medium: 14,
                                          large: 16,
                                          tablet: 18,
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: context.responsiveSpacing(
                                          small: 20,
                                          medium: 22,
                                          large: 24,
                                          tablet: 26,
                                        ),
                                        height: context.responsiveSpacing(
                                          small: 20,
                                          medium: 22,
                                          large: 24,
                                          tablet: 26,
                                        ),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.deepGreen,
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
                                      size: context.responsiveIconSize(
                                        small: 22,
                                        medium: 24,
                                        large: 26,
                                        tablet: 28,
                                      ),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.responsiveSpacing(
                                  small: 20,
                                  medium: 22,
                                  large: 24,
                                  tablet: 26,
                                ),
                                vertical: context.responsiveSpacing(
                                  small: 18,
                                  medium: 20,
                                  large: 22,
                                  tablet: 24,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 18,
                                    medium: 20,
                                    large: 22,
                                    tablet: 24,
                                  ),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 18,
                                    medium: 20,
                                    large: 22,
                                    tablet: 24,
                                  ),
                                ),
                                borderSide: BorderSide(
                                  color: _tootValidationError != null
                                      ? Colors.red
                                      : AppColors.deepGreen.withOpacity(0.8),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 18,
                                    medium: 20,
                                    large: 22,
                                    tablet: 24,
                                  ),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 18,
                                    medium: 20,
                                    large: 22,
                                    tablet: 24,
                                  ),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              errorText: _tootValidationError,
                              errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                ),
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
                                  color: context.textPrimaryColor,
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
                                        color: AppColors.deepGreen.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.deepGreen
                                              .withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        toot,
                                        style: TextStyle(
                                          color: AppColors.deepGreen,
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
                    ],
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 24,
                        medium: 28,
                        large: 32,
                        tablet: 36,
                      ),
                    ),
                    GestureDetector(
                      onTap: (_hasExistingAddress || _hasBaiguullagiinId)
                          ? (_isSaving ? null : _saveAddress)
                          : (_isSaving ||
                                (_selectedCity == null ||
                                    _selectedDistrict == null ||
                                    _selectedKhoroo == null ||
                                    _selectedBuilding == null ||
                                    _doorNoController.text.trim().isEmpty ||
                                    (_selectedBuilding!['source']?.toString() ==
                                            'OWN_ORG' &&
                                        !_isTootValid)))
                          ? null
                          : _saveAddress,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 22,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: (_hasExistingAddress || _hasBaiguullagiinId)
                              ? (_isSaving
                                    ? AppColors.deepGreen.withOpacity(0.5)
                                    : AppColors.deepGreen)
                              : (_isSaving ||
                                    (_selectedCity == null ||
                                        _selectedDistrict == null ||
                                        _selectedKhoroo == null ||
                                        _selectedBuilding == null ||
                                        _doorNoController.text.trim().isEmpty ||
                                        (_selectedBuilding!['source']
                                                    ?.toString() ==
                                                'OWN_ORG' &&
                                            !_isTootValid)))
                              ? AppColors.deepGreen.withOpacity(0.5)
                              : AppColors.deepGreen,
                          borderRadius: BorderRadius.circular(
                            context.responsiveBorderRadius(
                              small: 18,
                              medium: 20,
                              large: 22,
                              tablet: 24,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepGreen.withOpacity(0.3),
                              blurRadius: context.responsiveSpacing(
                                small: 20,
                                medium: 24,
                                large: 28,
                                tablet: 32,
                              ),
                              spreadRadius: 0,
                              offset: Offset(
                                0,
                                context.responsiveSpacing(
                                  small: 8,
                                  medium: 10,
                                  large: 12,
                                  tablet: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: _isSaving
                            ? Center(
                                child: SizedBox(
                                  height: context.responsiveSpacing(
                                    small: 22,
                                    medium: 24,
                                    large: 26,
                                    tablet: 28,
                                  ),
                                  width: context.responsiveSpacing(
                                    small: 22,
                                    medium: 24,
                                    large: 26,
                                    tablet: 28,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.textPrimaryColor,
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: context.textPrimaryColor,
                                    size: context.responsiveIconSize(
                                      small: 20,
                                      medium: 22,
                                      large: 24,
                                      tablet: 26,
                                    ),
                                  ),
                                  SizedBox(
                                    width: context.responsiveSpacing(
                                      small: 8,
                                      medium: 10,
                                      large: 12,
                                      tablet: 14,
                                    ),
                                  ),
                                  Text(
                                    'Хадгалах',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: context.responsiveFontSize(
                                        small: 16,
                                        medium: 17,
                                        large: 18,
                                        tablet: 19,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 20,
                        medium: 24,
                        large: 28,
                        tablet: 32,
                      ),
                    ),
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
