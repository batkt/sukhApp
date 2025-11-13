import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'burtguulekh_khoyor.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/core/auth_config.dart';
import 'package:sukh_app/widgets/app_logo.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(decoration: const BoxDecoration(), child: child);
  }
}

class Burtguulekh_Neg extends StatefulWidget {
  const Burtguulekh_Neg({super.key});

  @override
  State<Burtguulekh_Neg> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Neg> {
  final _formKey = GlobalKey<FormState>();

  String? selectedDistrict;
  String? selectedKhotkhon;
  String? selectedSOKH;
  String? selectedBair;
  String? selectedBaiguullagiinId;
  String? selectedDistrictCode;
  String? selectedHorooKod;

  bool isDistrictOpen = false;
  bool isKhotkhonOpen = false;
  bool isSOKHOpen = false;

  List<String> districts = [];
  List<Map<String, String>> khotkhons = [];
  List<String> sokhs = [];
  List<String> bairOptions = [];

  List<Map<String, dynamic>> locationData = [];
  Map<String, dynamic>? buildingDetailsData;

  final TextEditingController tootController = TextEditingController();

  bool isLoadingDistricts = false;
  bool isLoadingKhotkhon = false;
  bool isLoadingSOKH = false;
  bool isLoadingBuildingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    setState(() {
      isLoadingDistricts = true;
    });

    try {
      final data = await ApiService.fetchLocationData();

      if (mounted) {
        setState(() {
          locationData = data;

          // Flatten barilguud from all baiguullaga objects
          final Set<String> districtSet = {};

          for (var baiguullaga in data) {
            if (baiguullaga['barilguud'] != null &&
                baiguullaga['barilguud'] is List) {
              for (var barilga in baiguullaga['barilguud']) {
                if (barilga is Map &&
                    barilga['duuregNer'] != null &&
                    barilga['duuregNer'].toString().isNotEmpty) {
                  districtSet.add(barilga['duuregNer'].toString());
                }
              }
            }
          }

          districts = districtSet.toList();
          isLoadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDistricts = false;
        });
        showGlassSnackBar(
          context,
          message: 'Дүүрэг мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadKhotkhons(String district) async {
    setState(() {
      isLoadingKhotkhon = true;
      selectedKhotkhon = null;
      selectedSOKH = null;
      selectedBaiguullagiinId = null;
      selectedHorooKod = null;
      khotkhons = [];
      sokhs = [];
    });

    try {
      final uniqueHoroos = <String, String>{};
      String? districtBaiguullagiinId;

      for (var baiguullaga in locationData) {
        if (baiguullaga['barilguud'] != null &&
            baiguullaga['barilguud'] is List) {
          for (var barilga in baiguullaga['barilguud']) {
            if (barilga is Map &&
                barilga['duuregNer'] == district &&
                barilga['horoo'] != null &&
                barilga['horoo']['ner'] != null &&
                barilga['horoo']['ner'].toString().isNotEmpty &&
                barilga['sohNer'] != null &&
                barilga['sohNer'].toString().isNotEmpty) {
              // Only show Хороо that contain at least one valid СӨХ
              final horooNer = barilga['horoo']['ner'].toString();
              final horooKod = barilga['horoo']['kod'].toString();
              uniqueHoroos[horooNer] = horooKod;

              // Get baiguullagiinId from the first matching record
              if (districtBaiguullagiinId == null &&
                  baiguullaga['baiguullagiinId'] != null) {
                districtBaiguullagiinId = baiguullaga['baiguullagiinId']
                    .toString();
              }
            }
          }
        }
      }

      final horooList = uniqueHoroos.entries
          .map((e) => {'ner': e.key, 'kod': e.value})
          .toList();

      if (mounted) {
        setState(() {
          khotkhons = horooList;
          selectedBaiguullagiinId = districtBaiguullagiinId;
          isLoadingKhotkhon = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingKhotkhon = false;
        });
        showGlassSnackBar(
          context,
          message: 'Хороо мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadSOKHs(String horooNer) async {
    setState(() {
      isLoadingSOKH = true;
      selectedSOKH = null;
      selectedBaiguullagiinId = null;
      sokhs = [];
    });

    try {
      // Only show СӨХ that are valid (non-null, non-empty)
      final Set<String> uniqueSOKHs = {};

      for (var baiguullaga in locationData) {
        if (baiguullaga['barilguud'] != null &&
            baiguullaga['barilguud'] is List) {
          for (var barilga in baiguullaga['barilguud']) {
            if (barilga is Map &&
                barilga['duuregNer'] == selectedDistrict &&
                barilga['horoo'] != null &&
                barilga['horoo']['ner'] == horooNer &&
                barilga['sohNer'] != null &&
                barilga['sohNer'].toString().isNotEmpty) {
              // Add this valid СӨХ to the list
              uniqueSOKHs.add(barilga['sohNer'].toString());
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          sokhs = uniqueSOKHs.toList();
          isLoadingSOKH = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingSOKH = false;
        });
        showGlassSnackBar(
          context,
          message: 'СӨХ мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  // Get baiguullagiinId when SOKh is selected
  void _updateBaiguullagiinId() {
    if (selectedDistrict != null &&
        selectedKhotkhon != null &&
        selectedSOKH != null) {
      // Find matching barilga in the nested structure
      for (var baiguullaga in locationData) {
        if (baiguullaga['barilguud'] != null &&
            baiguullaga['barilguud'] is List) {
          for (var barilga in baiguullaga['barilguud']) {
            if (barilga is Map &&
                barilga['duuregNer'] == selectedDistrict &&
                barilga['horoo'] != null &&
                barilga['horoo']['ner'] == selectedKhotkhon &&
                barilga['sohNer'] == selectedSOKH) {
              setState(() {
                selectedBaiguullagiinId = baiguullaga['baiguullagiinId']
                    ?.toString();
                selectedDistrictCode = barilga['districtCode']?.toString();
                selectedHorooKod = barilga['horoo']['kod']?.toString();
              });

              _loadBuildingDetails(); // Load building details after getting ID
              return; // Found the match, exit
            }
          }
        }
      }
    }
  }

  Future<void> _loadBuildingDetails() async {
    if (selectedBaiguullagiinId == null) {
      return;
    }

    setState(() {
      isLoadingBuildingDetails = true;
      selectedBair = null;
      bairOptions = [];
    });

    try {
      final buildingDetails = await ApiService.fetchBuildingDetails(
        baiguullagiinId: selectedBaiguullagiinId!,
      );

      if (mounted) {
        setState(() {
          if (buildingDetails['barilguud'] != null &&
              buildingDetails['barilguud'] is List) {
            final bairSet = <String>{};

            for (var barilga in buildingDetails['barilguud']) {
              if (barilga is Map &&
                  barilga['bairniiNer'] != null &&
                  barilga['bairniiNer'].toString().isNotEmpty) {
                // Filter by selected Хороо and СӨХ
                bool matchesHoroo =
                    selectedKhotkhon == null ||
                    (barilga['horoo'] != null &&
                        barilga['horoo']['ner'] == selectedKhotkhon);

                bool matchesSOKH =
                    selectedSOKH == null || (barilga['sohNer'] == selectedSOKH);

                // Only add Байр that matches the selected Хороо and СӨХ
                if (matchesHoroo && matchesSOKH) {
                  bairSet.add(barilga['bairniiNer'].toString());
                }
              }
            }

            bairOptions = bairSet.toList()..sort();
          }
          isLoadingBuildingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingBuildingDetails = false;
        });
        showGlassSnackBar(
          context,
          message: 'Барилгын мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  void _showBairSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Байр сонгох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: bairOptions.length,
                  itemBuilder: (context, index) {
                    final bair = bairOptions[index];
                    final isSelected = bair == selectedBair;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedBair = bair;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFe6ff00).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFe6ff00)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.apartment,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                bair,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFe6ff00),
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateAndSubmit(BuildContext context) async {
    if (selectedBaiguullagiinId != null &&
        selectedDistrict != null &&
        selectedKhotkhon != null &&
        selectedSOKH != null &&
        selectedBair != null &&
        tootController.text.isNotEmpty) {
      // Validate if the entered toot exists in the selected building
      try {
        final buildingDetails = await ApiService.fetchBuildingDetails(
          baiguullagiinId: selectedBaiguullagiinId!,
        );

        bool tootExistsInDavkhariinToonuud = false;

        print('=== Building Details Debug ===');
        print('Building Details: $buildingDetails');

        if (buildingDetails['barilguud'] != null &&
            buildingDetails['barilguud'] is List) {
          for (var barilga in buildingDetails['barilguud']) {
            print(
              'Checking barilga: ${barilga['bairniiNer']} against selectedBair: $selectedBair',
            );

            if (barilga is Map && barilga['bairniiNer'] == selectedBair) {
              print('Found matching bair!');
              print(
                'davkhariinToonuud exists: ${barilga['davkhariinToonuud'] != null}',
              );

              // Check if davkhariinToonuud exists directly on barilga
              if (barilga['davkhariinToonuud'] != null &&
                  barilga['davkhariinToonuud'] is Map) {
                final davkhariinToonuud = barilga['davkhariinToonuud'] as Map;
                final enteredToot = tootController.text.trim();

                print('davkhariinToonuud: $davkhariinToonuud');
                print('Entered toot: $enteredToot');

                for (var davkharKey in davkhariinToonuud.keys) {
                  final roomsList = davkhariinToonuud[davkharKey];
                  print(
                    'Floor $davkharKey - roomsList: $roomsList (type: ${roomsList.runtimeType})',
                  );

                  if (roomsList is List) {
                    for (var roomsString in roomsList) {
                      print(
                        'roomsString: $roomsString (type: ${roomsString.runtimeType})',
                      );

                      if (roomsString is String) {
                        // Split comma-separated room numbers
                        final rooms = roomsString
                            .split(',')
                            .map((r) => r.trim())
                            .toList();

                        print('Rooms after split: $rooms');

                        if (rooms.contains(enteredToot)) {
                          print(
                            'FOUND! Toot $enteredToot exists in floor $davkharKey',
                          );
                          tootExistsInDavkhariinToonuud = true;
                          break;
                        }
                      }
                    }
                  }

                  if (tootExistsInDavkhariinToonuud) break;
                }
              } else {
                print('davkhariinToonuud NOT FOUND in barilga!');
              }
              break;
            }
          }
        }

        print(
          'Final result: tootExistsInDavkhariinToonuud = $tootExistsInDavkhariinToonuud',
        );

        if (!mounted) return;

        if (!tootExistsInDavkhariinToonuud) {
          showGlassSnackBar(
            context,
            message: 'Тухайн байранд уг тооттой айл бүртгэгдээгүй байна',
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        // Initialize AuthConfig with selected location (async operation)
        AuthConfig.instance.initialize(
          duureg: selectedDistrict,
          districtCode: selectedHorooKod,
          sohNer: selectedSOKH,
        );

        // Store location data to pass to next screen
        final locationDataToPass = {
          'duureg': selectedDistrict,
          'horoo': selectedHorooKod,
          'soh': selectedSOKH,
          'bairniiNer': selectedBair,
          'toot': tootController.text.trim(),
          'baiguullagiinId': selectedBaiguullagiinId,
        };

        if (!mounted) return;

        showGlassSnackBar(
          context,
          message: 'Амжилттай!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        // Store navigator before async gap
        final navigator = Navigator.of(context);

        // Navigate to next screen with location data
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (context) =>
                  Burtguulekh_Khoyor(locationData: locationDataToPass),
            ),
          );
        });
      } catch (e) {
        if (!mounted) return;
        showGlassSnackBar(
          context,
          message: 'Тоот шалгахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } else {
      showGlassSnackBar(
        context,
        message: 'Бүх талбарыг бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  void _showDistrictSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Дүүрэг сонгох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: districts.length,
                  itemBuilder: (context, index) {
                    final district = districts[index];
                    final isSelected = district == selectedDistrict;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDistrict = district;
                        });
                        Navigator.pop(context);
                        _loadKhotkhons(district);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFe6ff00).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFe6ff00)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                district,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFe6ff00),
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _showKhotkhonSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Хороо сонгох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: khotkhons.length,
                  itemBuilder: (context, index) {
                    final khotkhon = khotkhons[index];
                    final isSelected = khotkhon['ner'] == selectedKhotkhon;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedKhotkhon = khotkhon['ner'];
                        });
                        Navigator.pop(context);
                        _loadSOKHs(khotkhon['ner']!);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFe6ff00).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFe6ff00)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.home_work_rounded,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                khotkhon['ner']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFe6ff00),
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _showSOKHSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'СӨХ сонгох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: sokhs.length,
                  itemBuilder: (context, index) {
                    final sokh = sokhs[index];
                    final isSelected = sokh == selectedSOKH;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSOKH = sokh;
                        });
                        Navigator.pop(context);
                        _updateBaiguullagiinId();
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFe6ff00).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFe6ff00)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                sokh,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFe6ff00),
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40.w,
                              vertical: 24.h,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppLogo(),
                                  SizedBox(height: 20.h),
                                  Text(
                                    'Бүртгэл',
                                    style: TextStyle(
                                      color: AppColors.grayColor,
                                      fontSize: 28.sp,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                  SizedBox(height: 18.h),

                                  // District field - Always visible
                                  GestureDetector(
                                    onTap: isLoadingDistricts
                                        ? null
                                        : _showDistrictSelectionModal,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        color: AppColors.inputGrayColor
                                            .withOpacity(0.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            offset: const Offset(0, 10),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 14.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              size: 20.sp,
                                              color: selectedDistrict != null
                                                  ? Colors.white.withOpacity(
                                                      0.7,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                selectedDistrict ??
                                                    'Дүүрэг сонгох',
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  color:
                                                      selectedDistrict != null
                                                      ? Colors.white
                                                      : Colors.white70,
                                                  fontWeight:
                                                      selectedDistrict != null
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white,
                                              size: 24.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Khotkhon field - Show only after district selected
                                  if (selectedDistrict != null) ...[
                                    SizedBox(height: 14.h),
                                    GestureDetector(
                                      onTap: isLoadingKhotkhon
                                          ? null
                                          : _showKhotkhonSelectionModal,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          color: AppColors.inputGrayColor
                                              .withOpacity(0.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 10),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLoadingKhotkhon
                                                    ? Icons
                                                          .hourglass_empty_rounded
                                                    : Icons.home_work_rounded,
                                                size: 20.sp,
                                                color: selectedKhotkhon != null
                                                    ? Colors.white.withOpacity(
                                                        0.7,
                                                      )
                                                    : Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  isLoadingKhotkhon
                                                      ? 'Уншиж байна...'
                                                      : (selectedKhotkhon ??
                                                            'Хороо сонгох'),
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color:
                                                        selectedKhotkhon != null
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontWeight:
                                                        selectedKhotkhon != null
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white,
                                                size: 24.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // SOKH field - Show only after khotkhon selected
                                  if (selectedKhotkhon != null) ...[
                                    SizedBox(height: 14.h),
                                    GestureDetector(
                                      onTap: isLoadingSOKH
                                          ? null
                                          : _showSOKHSelectionModal,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          color: AppColors.inputGrayColor
                                              .withOpacity(0.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 10),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLoadingSOKH
                                                    ? Icons
                                                          .hourglass_empty_rounded
                                                    : Icons.apartment_rounded,
                                                size: 20.sp,
                                                color: selectedSOKH != null
                                                    ? Colors.white.withOpacity(
                                                        0.7,
                                                      )
                                                    : Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  isLoadingSOKH
                                                      ? 'Уншиж байна...'
                                                      : (selectedSOKH ??
                                                            'СӨХ сонгох'),
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color: selectedSOKH != null
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontWeight:
                                                        selectedSOKH != null
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white,
                                                size: 24.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Bair field - Show only after SOKH selected
                                  if (selectedSOKH != null) ...[
                                    SizedBox(height: 14.h),
                                    GestureDetector(
                                      onTap: isLoadingBuildingDetails
                                          ? null
                                          : _showBairSelectionModal,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          color: AppColors.inputGrayColor
                                              .withOpacity(0.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 10),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLoadingBuildingDetails
                                                    ? Icons
                                                          .hourglass_empty_rounded
                                                    : Icons.apartment,
                                                size: 20.sp,
                                                color: selectedBair != null
                                                    ? Colors.white.withOpacity(
                                                        0.7,
                                                      )
                                                    : Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  isLoadingBuildingDetails
                                                      ? 'Уншиж байна...'
                                                      : (selectedBair ??
                                                            'Байр сонгох'),
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color: selectedBair != null
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontWeight:
                                                        selectedBair != null
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white,
                                                size: 24.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Toot field - Show only after bair selected
                                  if (selectedBair != null) ...[
                                    SizedBox(height: 14.h),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        color: AppColors.inputGrayColor
                                            .withOpacity(0.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            offset: const Offset(0, 10),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 4.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.meeting_room,
                                              size: 20.sp,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: TextFormField(
                                                controller: tootController,
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Тоот оруулах',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 15.sp,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        vertical: 10.h,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Continue button - Show only when all fields selected
                                  if (selectedDistrict != null &&
                                      selectedKhotkhon != null &&
                                      selectedSOKH != null &&
                                      selectedBair != null &&
                                      tootController.text.isNotEmpty) ...[
                                    SizedBox(height: 14.h),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            offset: const Offset(0, 10),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _validateAndSubmit(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFCAD2DB,
                                            ),
                                            foregroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 14.h,
                                              horizontal: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            shadowColor: Colors.black
                                                .withOpacity(0.3),
                                            elevation: 8,
                                          ),
                                          child: Text(
                                            'Үргэлжлүүлэх',
                                            style: TextStyle(fontSize: 15.sp),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.only(left: 7),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            context.pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
