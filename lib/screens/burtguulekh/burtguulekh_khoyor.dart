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
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/page_transitions.dart';

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
                        _loadOrtsOptions(bair);
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

  void _showOrtsSelectionModal() {
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
                      'Орц сонгох',
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
                  itemCount: ortsOptions.length,
                  itemBuilder: (context, index) {
                    final orts = ortsOptions[index];
                    final isSelected = orts == selectedOrts;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOrts = orts;
                        });
                        Navigator.pop(context);
                        if (selectedBair != null) {
                          _loadDavkharOptions(selectedBair!, orts);
                        }
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
                              Icons.meeting_room,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                orts,
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

  void _showDavkharSelectionModal() {
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
                      'Давхар сонгох',
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
                  itemCount: davkharOptions.length,
                  itemBuilder: (context, index) {
                    final davkhar = davkharOptions[index];
                    final isSelected = davkhar == selectedDavkhar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDavkhar = davkhar;
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
                              Icons.stairs,
                              size: 24.sp,
                              color: isSelected
                                  ? const Color(0xFFe6ff00)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                davkhar,
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
        PageTransitions.createRoute(Burtguulekh_Guraw(locationData: allData)),
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

                              // Bair field - Always visible
                              GestureDetector(
                                onTap: isLoadingBuildingDetails
                                    ? null
                                    : _showBairSelectionModal,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: AppColors.inputGrayColor.withOpacity(
                                      0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 10),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.apartment,
                                          size: 20.sp,
                                          color: selectedBair != null
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.white.withOpacity(0.5),
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
                                              fontWeight: selectedBair != null
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

                              // Orts field - Show only after bair selected
                              if (selectedBair != null) ...[
                                SizedBox(height: 14.h),
                                GestureDetector(
                                  onTap: _showOrtsSelectionModal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 10),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.meeting_room,
                                            size: 20.sp,
                                            color: selectedOrts != null
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.white.withOpacity(0.5),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              selectedOrts ?? 'Орц сонгох',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                color: selectedOrts != null
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight: selectedOrts != null
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

                              // Davkhar field - Show only after orts selected
                              if (selectedOrts != null) ...[
                                SizedBox(height: 14.h),
                                GestureDetector(
                                  onTap: _showDavkharSelectionModal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 10),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.stairs,
                                            size: 20.sp,
                                            color: selectedDavkhar != null
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.white.withOpacity(0.5),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              selectedDavkhar ??
                                                  'Давхар сонгох',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                color: selectedDavkhar != null
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight:
                                                    selectedDavkhar != null
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

                              // Last 3 inputs - Show only when all 3 selections made
                              if (selectedBair != null &&
                                  selectedOrts != null &&
                                  selectedDavkhar != null) ...[
                                SizedBox(height: 14.h),
                                // Тоот input
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: AppColors.inputGrayColor.withOpacity(
                                      0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 10),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
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
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      hintText: 'Тоот',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Тоот оруулна уу'
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: AppColors.inputGrayColor.withOpacity(
                                      0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 10),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
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
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      hintText: 'Овог',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Овог оруулна уу'
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: AppColors.inputGrayColor.withOpacity(
                                      0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 10),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: nerController,
                                    focusNode: nerFocus,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      hintText: 'Нэр',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15.sp,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Нэр оруулна уу'
                                        : null,
                                  ),
                                ),
                              ],

                              // Continue button - Show only when all fields filled
                              if (selectedBair != null &&
                                  selectedOrts != null &&
                                  selectedDavkhar != null &&
                                  tootController.text.isNotEmpty &&
                                  ovogController.text.isNotEmpty &&
                                  nerController.text.isNotEmpty) ...[
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
