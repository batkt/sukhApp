import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'burtguulekh_khoyor.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/core/auth_config.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/img/background_image.png'),
          fit: BoxFit.none,
          scale: 3,
        ),
      ),
      child: child,
    );
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

  bool isDistrictOpen = false;
  bool isKhotkhonOpen = false;
  bool isSOKHOpen = false;

  List<String> districts = [];
  List<String> khotkhons = [];
  List<String> sokhs = [];

  // Store full location data from API
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
          // Extract unique districts
          districts = data
              .where(
                (item) =>
                    item['duureg'] != null &&
                    item['duureg'].toString().isNotEmpty,
              )
              .map((item) => item['duureg'].toString())
              .toSet()
              .toList();
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
      khotkhons = [];
      sokhs = [];
    });

    try {
      // Filter location data by selected district
      final filteredData = locationData
          .where(
            (item) =>
                item['duureg'] == district &&
                item['districtCode'] != null &&
                item['districtCode'].toString().isNotEmpty,
          )
          .toList();

      final uniqueKhotkhons = filteredData
          .map((item) => item['districtCode'].toString())
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          khotkhons = uniqueKhotkhons;
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
          message: 'Хотхон мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadSOKHs(String khotkhon) async {
    setState(() {
      isLoadingSOKH = true;
      selectedSOKH = null;
      selectedBaiguullagiinId = null;
      sokhs = [];
    });

    try {
      // Filter location data by selected district and khotkhon
      final filteredData = locationData
          .where(
            (item) =>
                item['duureg'] == selectedDistrict &&
                item['districtCode'] == khotkhon &&
                item['sohCode'] != null &&
                item['sohCode'].toString().isNotEmpty,
          )
          .toList();

      // Extract unique SOKHs (sohCode)
      final uniqueSOKHs = filteredData
          .map((item) => item['sohCode'].toString())
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          sokhs = uniqueSOKHs;
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
      // Find matching location data
      final matchingData = locationData.firstWhere(
        (item) =>
            item['duureg'] == selectedDistrict &&
            item['districtCode'] == selectedKhotkhon &&
            item['sohCode'] == selectedSOKH,
        orElse: () => {},
      );

      if (matchingData.isNotEmpty && matchingData['baiguullagiinId'] != null) {
        setState(() {
          selectedBaiguullagiinId = matchingData['baiguullagiinId'].toString();
        });
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
          districtCode: selectedKhotkhon,
          sohCode: selectedSOKH,
        );

        // Store location data to pass to next screen
        final locationDataToPass = {
          'duureg': selectedDistrict,
          'horoo': selectedKhotkhon,
          'soh': selectedSOKH,
          'baiguullagiinId': selectedBaiguullagiinId,
        };

        showGlassSnackBar(
          context,
          message: 'Бүх мэдээлэл зөв байна!',
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 40,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 80,
                                      maxHeight: 154,
                                      minWidth: 154,
                                      maxWidth: 154,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(36),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10,
                                            sigmaY: 10,
                                          ),
                                          child: Container(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Бүртгэл',
                                    style: TextStyle(
                                      color: AppColors.grayColor,
                                      fontSize: 36,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),

                                  const SizedBox(height: 20),
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
                                        errorStyle: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 14,
                                        ),
                                      ),
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              size: 20,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Дүүрэг сонгох',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15,
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
                                                    size: 20,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    district,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_city_rounded,
                                                  size: 20,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  district,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
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
                                          return '                                            Дүүрэг сонгоно уу';
                                        }
                                        return null;
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        height: 56,
                                        padding: EdgeInsets.only(right: 11),
                                      ),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 300,
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
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
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
                                  const SizedBox(height: 16),

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
                                            errorStyle: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 14,
                                            ),
                                          ),
                                          hint: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLoadingKhotkhon
                                                      ? Icons
                                                            .hourglass_empty_rounded
                                                      : Icons.home_work_rounded,
                                                  size: 20,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  isLoadingKhotkhon
                                                      ? 'Уншиж байна...'
                                                      : 'Хотхон сонгох',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 15,
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
                                                  value: khotkhon,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.home_work_rounded,
                                                        size: 20,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        khotkhon,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.home_work_rounded,
                                                      size: 20,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      khotkhon,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
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
                                              return '                                           Хотхон сонгоно уу';
                                            }
                                            return null;
                                          },
                                          buttonStyleData:
                                              const ButtonStyleData(
                                                height: 56,
                                                padding: EdgeInsets.only(
                                                  right: 11,
                                                ),
                                              ),
                                          dropdownStyleData: DropdownStyleData(
                                            maxHeight: 300,
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
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
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

                                  const SizedBox(height: 16),

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
                                            errorStyle: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 14,
                                            ),
                                            errorMaxLines: 2,
                                          ),
                                          hint: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLoadingSOKH
                                                      ? Icons
                                                            .hourglass_empty_rounded
                                                      : Icons.apartment_rounded,
                                                  size: 20,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  isLoadingSOKH
                                                      ? 'Уншиж байна...'
                                                      : 'СӨХ сонгох',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 15,
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
                                                    size: 20,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    sokh,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.apartment_rounded,
                                                      size: 20,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      sokh,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
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
                                              return '                                                СӨХ сонгоно уу';
                                            }
                                            return null;
                                          },
                                          buttonStyleData:
                                              const ButtonStyleData(
                                                height: 56,
                                                padding: EdgeInsets.only(
                                                  right: 11,
                                                ),
                                              ),
                                          dropdownStyleData: DropdownStyleData(
                                            maxHeight: 300,
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
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
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

                                  const SizedBox(height: 16),

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
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
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
                                        child: const Text(
                                          'Үргэлжлүүлэх',
                                          style: TextStyle(fontSize: 14),
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
