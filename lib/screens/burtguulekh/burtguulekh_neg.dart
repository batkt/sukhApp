import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'burtguulekh_khoyor.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
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
  final GlobalKey<FormFieldState<String>> _districtFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _khotkhonFieldKey =
      GlobalKey<FormFieldState<String>>();

  String? selectedDistrict;
  String? selectedKhotkhon;
  String? selectedSOKH;
  String? selectedBaiguullagiinId;
  String? selectedDistrictCode;
  String? selectedHorooKod;

  bool isDistrictOpen = false;
  bool isKhotkhonOpen = false;
  bool isSOKHOpen = false;

  List<String> districts = [];
  List<Map<String, String>> khotkhons = [];
  List<String> sokhs = [];

  List<Map<String, dynamic>> locationData = [];

  bool isLoadingDistricts = false;
  bool isLoadingKhotkhon = false;
  bool isLoadingSOKH = false;

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
      // Flatten and filter barilguud by district
      final uniqueHoroos = <String, String>{};
      String? districtBaiguullagiinId;

      for (var baiguullaga in locationData) {
        if (baiguullaga['barilguud'] != null &&
            baiguullaga['barilguud'] is List) {
          for (var barilga in baiguullaga['barilguud']) {
            if (barilga is Map &&
                barilga['duuregNer'] == district &&
                barilga['horoo'] != null &&
                barilga['horoo']['ner'] != null) {
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
      // Flatten and filter barilguud by district and horoo
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
              return; // Found the match, exit
            }
          }
        }
      }
    }
  }

  void _validateAndSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Validate baiguullagiinId is available
      if (selectedBaiguullagiinId != null) {
        // Initialize AuthConfig with selected location (async operation)
        AuthConfig.instance.initialize(
          duureg: selectedDistrict,
          districtCode:
              selectedHorooKod, // Use horoo.kod (may be null if not selected yet)
          sohNer: selectedSOKH,
        );

        // Store location data to pass to next screen
        final locationDataToPass = {
          'duureg': selectedDistrict,
          'horoo': selectedHorooKod, // Pass horoo.kod for API (may be null)
          'soh': selectedSOKH,
          'baiguullagiinId':
              selectedBaiguullagiinId, // This is now set when district is selected
        };

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
      } else {
        showGlassSnackBar(
          context,
          message: 'Байгууллагын мэдээлэл олдсонгүй',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
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

                                  // District dropdown
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 10),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: DropdownButtonFormField2<String>(
                                      key: _districtFieldKey,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: AppColors.inputGrayColor
                                            .withOpacity(0.5),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.grayColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorStyle: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13.sp,
                                        ),
                                        errorMaxLines: 1,
                                        helperText: '',
                                        helperStyle: const TextStyle(height: 0),
                                      ),
                                      hint: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              size: 20.sp,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(
                                              'Дүүрэг сонгох',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      items: districts
                                          .map(
                                            (
                                              district,
                                            ) => DropdownMenuItem<String>(
                                              value: district,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_city_rounded,
                                                    size: 20.sp,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    district,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      selectedItemBuilder: (context) {
                                        return districts.map((district) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_city_rounded,
                                                  size: 20.sp,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                                SizedBox(width: 12.w),
                                                Text(
                                                  district,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList();
                                      },
                                      value: selectedDistrict,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDistrict = value;
                                        });
                                        _districtFieldKey.currentState
                                            ?.validate();
                                        if (value != null) {
                                          _loadKhotkhons(value);
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Дүүрэг сонгоно уу';
                                        }
                                        return null;
                                      },
                                      buttonStyleData: ButtonStyleData(
                                        height: 52.h,
                                        padding: EdgeInsets.only(right: 11.w),
                                      ),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 300.h,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputGrayColor
                                              .withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 8),
                                              blurRadius: 24,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                      menuItemStyleData: MenuItemStyleData(
                                        height: 46.h,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        overlayColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return Colors.white.withOpacity(
                                                  0.1,
                                                );
                                              }
                                              if (states.contains(
                                                WidgetState.focused,
                                              )) {
                                                return Colors.white.withOpacity(
                                                  0.15,
                                                );
                                              }
                                              return null;
                                            }),
                                      ),
                                      iconStyleData: IconStyleData(
                                        icon: Icon(
                                          isDistrictOpen
                                              ? Icons.arrow_drop_up
                                              : Icons.arrow_drop_down,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onMenuStateChange: (isOpen) {
                                        setState(() {
                                          isDistrictOpen = isOpen;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 14.h),

                                  // Khotkhon dropdown
                                  GestureDetector(
                                    onTap: () {
                                      if (selectedDistrict == null) {
                                        _districtFieldKey.currentState
                                            ?.validate();
                                        _districtFieldKey.currentState
                                            ?.didChange(selectedDistrict);
                                        setState(() {});
                                      }
                                    },
                                    child: AbsorbPointer(
                                      absorbing: selectedDistrict == null,
                                      child: Container(
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
                                            ),
                                          ],
                                        ),
                                        child: DropdownButtonFormField2<String>(
                                          key: _khotkhonFieldKey,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.zero,
                                            filled: true,
                                            fillColor: AppColors.inputGrayColor
                                                .withOpacity(0.5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                            errorStyle: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13.sp,
                                            ),
                                            errorMaxLines: 1,
                                            helperText: '',
                                            helperStyle: const TextStyle(
                                              height: 0,
                                            ),
                                          ),
                                          hint: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLoadingKhotkhon
                                                      ? Icons
                                                            .hourglass_empty_rounded
                                                      : Icons.home_work_rounded,
                                                  size: 20.sp,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                SizedBox(width: 12.w),
                                                Text(
                                                  isLoadingKhotkhon
                                                      ? 'Уншиж байна...'
                                                      : 'Хороо сонгох',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 15.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          items: khotkhons
                                              .map(
                                                (
                                                  khotkhon,
                                                ) => DropdownMenuItem<String>(
                                                  value: khotkhon['ner'],
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.home_work_rounded,
                                                        size: 20.sp,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                      SizedBox(width: 12.w),
                                                      Text(
                                                        khotkhon['ner']!,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15.sp,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          selectedItemBuilder: (context) {
                                            return khotkhons.map((khotkhon) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.home_work_rounded,
                                                      size: 20.sp,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Text(
                                                      khotkhon['ner']!,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                          value: selectedKhotkhon,
                                          onChanged:
                                              (selectedDistrict == null ||
                                                  isLoadingKhotkhon)
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    selectedKhotkhon = value;
                                                  });
                                                  _khotkhonFieldKey.currentState
                                                      ?.validate();
                                                  if (value != null) {
                                                    _loadSOKHs(value);
                                                  }
                                                },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Хороо сонгоно уу';
                                            }
                                            return null;
                                          },
                                          buttonStyleData: ButtonStyleData(
                                            height: 52.h,
                                            padding: EdgeInsets.only(
                                              right: 11.w,
                                            ),
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            maxHeight: 300.h,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputGrayColor
                                                  .withOpacity(0.95),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  offset: const Offset(0, 8),
                                                  blurRadius: 24,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                          menuItemStyleData: MenuItemStyleData(
                                            height: 46.h,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            overlayColor:
                                                WidgetStateProperty.resolveWith<
                                                  Color?
                                                >((Set<WidgetState> states) {
                                                  if (states.contains(
                                                    WidgetState.hovered,
                                                  )) {
                                                    return Colors.white
                                                        .withOpacity(0.1);
                                                  }
                                                  if (states.contains(
                                                    WidgetState.focused,
                                                  )) {
                                                    return Colors.white
                                                        .withOpacity(0.15);
                                                  }
                                                  return null;
                                                }),
                                          ),
                                          iconStyleData: IconStyleData(
                                            icon: Icon(
                                              isKhotkhonOpen
                                                  ? Icons.arrow_drop_up
                                                  : Icons.arrow_drop_down,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onMenuStateChange: (isOpen) {
                                            setState(() {
                                              isKhotkhonOpen = isOpen;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14.h),

                                  // SOKH dropdown
                                  GestureDetector(
                                    onTap: () {
                                      if (selectedDistrict == null) {
                                        _districtFieldKey.currentState
                                            ?.validate();
                                        _districtFieldKey.currentState
                                            ?.didChange(selectedDistrict);
                                        setState(() {});
                                      } else if (selectedKhotkhon == null) {
                                        _khotkhonFieldKey.currentState
                                            ?.validate();
                                        _khotkhonFieldKey.currentState
                                            ?.didChange(selectedKhotkhon);
                                        setState(() {});
                                      }
                                    },
                                    child: AbsorbPointer(
                                      absorbing:
                                          selectedDistrict == null ||
                                          selectedKhotkhon == null,
                                      child: Container(
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
                                            ),
                                          ],
                                        ),
                                        child: DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.zero,
                                            filled: true,
                                            fillColor: AppColors.inputGrayColor
                                                .withOpacity(0.5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              borderSide: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                            errorStyle: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13.sp,
                                            ),
                                            errorMaxLines: 1,
                                            helperText: '',
                                            helperStyle: const TextStyle(
                                              height: 0,
                                            ),
                                          ),
                                          hint: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLoadingSOKH
                                                      ? Icons
                                                            .hourglass_empty_rounded
                                                      : Icons.apartment_rounded,
                                                  size: 20.sp,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                SizedBox(width: 12.w),
                                                Text(
                                                  isLoadingSOKH
                                                      ? 'Уншиж байна...'
                                                      : 'СӨХ сонгох',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 15.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          items: sokhs.map((sokh) {
                                            return DropdownMenuItem<String>(
                                              value: sokh,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.apartment_rounded,
                                                    size: 20.sp,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    sokh,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          selectedItemBuilder: (context) {
                                            return sokhs.map((sokh) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.apartment_rounded,
                                                      size: 20.sp,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Text(
                                                      sokh,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                          value: selectedSOKH,
                                          onChanged:
                                              (selectedDistrict == null ||
                                                  isLoadingSOKH)
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    selectedSOKH = value;
                                                  });
                                                  _updateBaiguullagiinId();
                                                },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'СӨХ сонгоно уу';
                                            }
                                            return null;
                                          },
                                          buttonStyleData: ButtonStyleData(
                                            height: 52.h,
                                            padding: EdgeInsets.only(
                                              right: 11.w,
                                            ),
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            maxHeight: 300.h,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputGrayColor
                                                  .withOpacity(0.95),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  offset: const Offset(0, 8),
                                                  blurRadius: 24,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                          menuItemStyleData: MenuItemStyleData(
                                            height: 46.h,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            overlayColor:
                                                WidgetStateProperty.resolveWith<
                                                  Color?
                                                >((Set<WidgetState> states) {
                                                  if (states.contains(
                                                    WidgetState.hovered,
                                                  )) {
                                                    return Colors.white
                                                        .withOpacity(0.1);
                                                  }
                                                  if (states.contains(
                                                    WidgetState.focused,
                                                  )) {
                                                    return Colors.white
                                                        .withOpacity(0.15);
                                                  }
                                                  return null;
                                                }),
                                          ),
                                          iconStyleData: IconStyleData(
                                            icon: Icon(
                                              isSOKHOpen
                                                  ? Icons.arrow_drop_up
                                                  : Icons.arrow_drop_down,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onMenuStateChange: (isOpen) {
                                            setState(() {
                                              isSOKHOpen = isOpen;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14.h),

                                  // Continue button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
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
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                          ),
                                          shadowColor: Colors.black.withOpacity(
                                            0.3,
                                          ),
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
