import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/core/auth_config.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sukh_app/services/api_service.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(child: child),
    );
  }
}

// ignore: camel_case_types
class Burtguulekh_Khoyor extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const Burtguulekh_Khoyor({super.key, this.locationData});

  @override
  State<Burtguulekh_Khoyor> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Khoyor> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  bool isLoadingBuildingDetails = false;

  String? selectedBair;
  String? selectedOrts;
  String? selectedDavkhar;

  List<String> bairOptions = [];
  List<String> ortsOptions = [];
  List<String> davkharOptions = [];

  bool isBairOpen = false;
  bool isOrtsOpen = false;
  bool isDavkharOpen = false;

  final TextEditingController tootController = TextEditingController();
  final TextEditingController ovogController = TextEditingController();
  final TextEditingController nerController = TextEditingController();

  final FocusNode tootFocus = FocusNode();
  final FocusNode ovogFocus = FocusNode();
  final FocusNode nerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    tootController.addListener(() => setState(() {}));
    ovogController.addListener(() => setState(() {}));
    nerController.addListener(() => setState(() {}));
    _loadBuildingDetails();
  }

  @override
  void dispose() {
    tootController.dispose();
    ovogController.dispose();
    nerController.dispose();

    tootFocus.dispose();
    ovogFocus.dispose();
    nerFocus.dispose();

    super.dispose();
  }

  Future<void> _loadBuildingDetails() async {
    if (widget.locationData?['baiguullagiinId'] == null) {
      return;
    }

    setState(() {
      isLoadingBuildingDetails = true;
    });

    try {
      final buildingDetails = await ApiService.fetchBuildingDetails(
        baiguullagiinId: widget.locationData!['baiguullagiinId'],
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
                bairSet.add(barilga['bairniiNer'].toString());
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

  void _loadOrtsOptions(String bairNer) async {
    if (widget.locationData?['baiguullagiinId'] == null) {
      return;
    }

    try {
      final buildingDetails = await ApiService.fetchBuildingDetails(
        baiguullagiinId: widget.locationData!['baiguullagiinId'],
      );

      if (mounted) {
        setState(() {
          selectedOrts = null;
          selectedDavkhar = null;
          ortsOptions = [];
          davkharOptions = [];

          // Find the barilga matching the selected bair
          if (buildingDetails['barilguud'] != null &&
              buildingDetails['barilguud'] is List) {
            for (var barilga in buildingDetails['barilguud']) {
              if (barilga is Map && barilga['bairniiNer'] == bairNer) {
                // Extract orts array from this barilga
                if (barilga['orts'] != null && barilga['orts'] is List) {
                  ortsOptions =
                      (barilga['orts'] as List)
                          .map((e) => e.toString())
                          .where((e) => e.isNotEmpty)
                          .toList()
                        ..sort();
                }
                break; // Found the matching barilga
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Орцны мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  void _loadDavkharOptions(String bairNer, String orts) async {
    if (widget.locationData?['baiguullagiinId'] == null) {
      return;
    }

    try {
      final buildingDetails = await ApiService.fetchBuildingDetails(
        baiguullagiinId: widget.locationData!['baiguullagiinId'],
      );

      if (mounted) {
        setState(() {
          selectedDavkhar = null;
          davkharOptions = [];

          // Find the barilga matching the selected bair
          if (buildingDetails['barilguud'] != null &&
              buildingDetails['barilguud'] is List) {
            for (var barilga in buildingDetails['barilguud']) {
              if (barilga is Map && barilga['bairniiNer'] == bairNer) {
                // Extract davkhar array from this barilga
                if (barilga['davkhar'] != null && barilga['davkhar'] is List) {
                  davkharOptions =
                      (barilga['davkhar'] as List)
                          .map((e) => e.toString())
                          .where((e) => e.isNotEmpty)
                          .toList()
                        ..sort();
                }
                break; // Found the matching barilga
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Давхарын мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _validateAndSubmit() async {
    // Force validation mode to show all errors immediately
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    if (!_formKey.currentState!.validate()) {
      // If invalid, show snackbar or shake animation (optional)
      showGlassSnackBar(
        context,
        message: 'Бүх талбарыг бөглөнө үү',
        icon: Icons.error,
        iconColor: Colors.redAccent,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final allData = {
        'duureg': widget.locationData?['duureg'] ?? AuthConfig.instance.duureg,
        'horoo':
            widget.locationData?['horoo'] ?? AuthConfig.instance.districtCode,
        'soh': widget.locationData?['soh'] ?? AuthConfig.instance.sohNer,
        'baiguullagiinId':
            widget.locationData?['baiguullagiinId'] ??
            AuthConfig.instance.baiguullagiinId,
        'bairniiNer': selectedBair,
        'orts': selectedOrts,
        'davkhar': selectedDavkhar,
        'toot': tootController.text,
        'ovog': ovogController.text,
        'ner': nerController.text,
      };

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              Burtguulekh_Guraw(locationData: allData),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeIn = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
            return FadeTransition(opacity: fadeIn, child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showGlassSnackBar(
        context,
        message: 'Алдаа гарлаа: $e',
        icon: Icons.error,
        iconColor: Colors.redAccent,
      );
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white70, fontSize: 15.sp),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.grayColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
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
                    final keyboardHeight = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 40.w,
                          right: 40.w,
                          top: 24.h,
                          bottom: keyboardHeight > 0
                              ? keyboardHeight + 20
                              : 24.h,
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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

                              // Байр dropdown
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: AppColors.grayColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  hint: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5.w,
                                    ),
                                    child: Text(
                                      isLoadingBuildingDetails
                                          ? 'Уншиж байна...'
                                          : 'Байр сонгох',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                  items: bairOptions
                                      .map(
                                        (bair) => DropdownMenuItem<String>(
                                          value: bair,
                                          child: Text(
                                            bair,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return bairOptions.map((bair) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Text(
                                          bair,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  value: selectedBair,
                                  onChanged: isLoadingBuildingDetails
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedBair = value;
                                          });
                                          if (value != null) {
                                            _loadOrtsOptions(value);
                                          }
                                        },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Байр сонгоно уу';
                                    }
                                    return null;
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    height: 52.h,
                                    padding: EdgeInsets.only(right: 11.w),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 300.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    height: 46.h,
                                  ),
                                  iconStyleData: IconStyleData(
                                    icon: Icon(
                                      isBairOpen
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    setState(() {
                                      isBairOpen = isOpen;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // Орц dropdown
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: AppColors.grayColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  hint: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5.w,
                                    ),
                                    child: Text(
                                      'Орц сонгох',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                  items: ortsOptions
                                      .map(
                                        (orts) => DropdownMenuItem<String>(
                                          value: orts,
                                          child: Text(
                                            orts,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return ortsOptions.map((orts) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Text(
                                          orts,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  value: selectedOrts,
                                  onChanged: selectedBair == null
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedOrts = value;
                                          });
                                          if (value != null &&
                                              selectedBair != null) {
                                            _loadDavkharOptions(
                                              selectedBair!,
                                              value,
                                            );
                                          }
                                        },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Орц сонгоно уу';
                                    }
                                    return null;
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    height: 52.h,
                                    padding: EdgeInsets.only(right: 11.w),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 300.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    height: 46.h,
                                  ),
                                  iconStyleData: IconStyleData(
                                    icon: Icon(
                                      isOrtsOpen
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    setState(() {
                                      isOrtsOpen = isOpen;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // Давхар dropdown
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: AppColors.grayColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  hint: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5.w,
                                    ),
                                    child: Text(
                                      'Давхар сонгох',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                  items: davkharOptions
                                      .map(
                                        (davkhar) => DropdownMenuItem<String>(
                                          value: davkhar,
                                          child: Text(
                                            davkhar,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return davkharOptions.map((davkhar) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Text(
                                          davkhar,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  value: selectedDavkhar,
                                  onChanged: selectedOrts == null
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedDavkhar = value;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Давхар сонгоно уу';
                                    }
                                    return null;
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    height: 52.h,
                                    padding: EdgeInsets.only(right: 11.w),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 300.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    height: 46.h,
                                  ),
                                  iconStyleData: IconStyleData(
                                    icon: Icon(
                                      isDavkharOpen
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    setState(() {
                                      isDavkharOpen = isOpen;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // Тоот input
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: tootController,
                                  focusNode: tootFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(ovogFocus);
                                  },
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _inputDecoration(
                                    'Тоот',
                                    tootController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Тоот оруулна уу'
                                      : null,
                                ),
                              ),
                              SizedBox(height: 14.h),

                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: ovogController,
                                  focusNode: ovogFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(nerFocus);
                                  },
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _inputDecoration(
                                    'Овог',
                                    ovogController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Овог оруулна уу'
                                      : null,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: nerController,
                                  focusNode: nerFocus,
                                  textInputAction: TextInputAction.next,

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _inputDecoration(
                                    'Нэр',
                                    nerController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Нэр оруулна уу'
                                      : null,
                                ),
                              ),
                              SizedBox(height: 14.h),

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
                                    onPressed: _isLoading
                                        ? null
                                        : _validateAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCAD2DB),
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
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 18.h,
                                            width: 18.w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.black),
                                                ),
                                          )
                                        : Text(
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

  BoxDecoration _boxShadowDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 10),
          blurRadius: 8,
        ),
      ],
    );
  }
}
