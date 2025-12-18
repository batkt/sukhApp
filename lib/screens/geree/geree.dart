import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/models/geree_model.dart' as model;
import 'package:sukh_app/models/ajiltan_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class Geree extends StatefulWidget {
  const Geree({super.key});

  @override
  State<Geree> createState() => _GereeState();
}

class _GereeState extends State<Geree> {
  bool _isLoading = true;
  String? _errorMessage;
  model.GereeResponse? _gereeData;
  AjiltanResponse? _ajiltanData;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchGereeData();
    _fetchAjiltanData();
  }

  Future<void> _fetchGereeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final response = await ApiService.fetchGeree(userId);
      setState(() {
        _gereeData = model.GereeResponse.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAjiltanData() async {
    try {
      final response = await ApiService.fetchAjiltan();
      setState(() {
        _ajiltanData = AjiltanResponse.fromJson(response);
      });
    } catch (e) {
      // Silently fail - ajiltan data is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: buildStandardAppBar(
        context,
        title: 'Гэрээ',
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: context.responsiveSpacing(
                  small: 20,
                  medium: 24,
                  large: 28,
                  tablet: 32,
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: context.responsivePadding(
            small: 20,
            medium: 22,
            large: 24,
            tablet: 26,
          ),
          child: OptimizedGlass(
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(
                small: 22,
                medium: 24,
                large: 26,
                tablet: 28,
              ),
            ),
            opacity: 0.10,
            child: Padding(
              padding: context.responsivePadding(
                small: 24,
                medium: 26,
                large: 28,
                tablet: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.withOpacity(0.8),
                    size: context.responsiveIconSize(
                      small: 48,
                      medium: 52,
                      large: 56,
                      tablet: 60,
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                    ),
                  ),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 17,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 24,
                      medium: 28,
                      large: 32,
                      tablet: 36,
                    ),
                  ),
                  OptimizedGlass(
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                      ),
                    ),
                    opacity: 0.10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _fetchGereeData,
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 24,
                              medium: 28,
                              large: 32,
                              tablet: 36,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                            ),
                          ),
                          child: Text(
                            'Дахин оролдох',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 17,
                              ),
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w600,
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
        ),
      );
    }

    if (_gereeData == null || _gereeData!.jagsaalt.isEmpty) {
      return Center(
        child: Padding(
          padding: context.responsivePadding(
            small: 20,
            medium: 22,
            large: 24,
            tablet: 26,
          ),
          child: OptimizedGlass(
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(
                small: 22,
                medium: 24,
                large: 26,
                tablet: 28,
              ),
            ),
            opacity: 0.10,
            child: Padding(
              padding: context.responsivePadding(
                small: 24,
                medium: 26,
                large: 28,
                tablet: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: context.textSecondaryColor,
                    size: context.responsiveIconSize(
                      small: 48,
                      medium: 52,
                      large: 56,
                      tablet: 60,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Гэрээний мэдээлэл олдсонгүй',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildInvoicePage();
  }

  Widget _buildInvoicePage() {
    if (_gereeData == null || _gereeData!.jagsaalt.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show full invoice for the first contract
    final geree = _gereeData!.jagsaalt.first;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Hero Card with Gradient
          _buildHeroCard(geree),
          SizedBox(height: 24.h),

          SizedBox(height: 20.h),

          // Customer Information Section
          _buildSection(
            title: 'ОРШИН СУУГЧИЙН МЭДЭЭЛЭЛ',
            icon: Icons.person_outline_rounded,
            children: [
              _buildInvoiceDetailRow(
                icon: Icons.badge_outlined,
                label: 'Овог нэр',
                value: '${geree.ovog} ${geree.ner}',
              ),
              _buildInvoiceDetailRow(
                icon: Icons.phone_outlined,
                label: 'Утас',
                value: geree.utas.isNotEmpty ? geree.utas.join(', ') : '-',
              ),
              if (geree.temdeglel.isNotEmpty)
                _buildInvoiceDetailRow(
                  icon: Icons.note_outlined,
                  label: 'Тэмдэглэл',
                  value: geree.temdeglel,
                ),
              if (geree.suhUtas.isNotEmpty)
                _buildInvoiceDetailRow(
                  icon: Icons.phone_android_outlined,
                  label: 'Сөх утас',
                  value: geree.suhUtas.join(', '),
                ),
            ],
          ),

          SizedBox(height: 20.h),

          // Property Information Section
          _buildSection(
            title: 'БАЙРНЫ МЭДЭЭЛЭЛ',
            icon: Icons.home_outlined,
            children: [
              _buildInvoiceDetailRow(
                icon: Icons.location_city_outlined,
                label: 'Байрны нэр',
                value: geree.bairNer,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInvoiceDetailRow(
                      icon: Icons.numbers,
                      label: 'Тоот',
                      value: geree.toot.toString(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildInvoiceDetailRow(
                      icon: Icons.layers_outlined,
                      label: 'Давхар',
                      value: geree.davkhar,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // SOH Information Section
          if (_ajiltanData != null && _ajiltanData!.jagsaalt.isNotEmpty)
            _buildSection(
              title: 'СӨХ МЭДЭЭЛЭЛ',
              icon: Icons.support_agent_outlined,
              children: [
                ..._ajiltanData!.jagsaalt.map((ajiltan) {
                  return Column(
                    children: [
                      if (_ajiltanData!.jagsaalt.indexOf(ajiltan) > 0)
                        SizedBox(height: 16.h),
                      _buildEmployeeCard(ajiltan),
                    ],
                  );
                }),
              ],
            ),

          if (_ajiltanData != null && _ajiltanData!.jagsaalt.isNotEmpty)
            SizedBox(height: 20.h),

          // If there are multiple contracts, show selector
          if (_gereeData!.jagsaalt.length > 1) ...[
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen.withOpacity(0.15),
                    AppColors.deepGreenAccent.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.deepGreen.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.deepGreen,
                          AppColors.deepGreenAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepGreen.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      'Таньд ${_gereeData!.jagsaalt.length} гэрээ байна',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  // int _calculateDaysPassed(String gereeniiOgnoo) {
  //   try {
  //     final contractDate = DateTime.parse(gereeniiOgnoo);
  //     final today = DateTime.now();
  //     final difference = today.difference(contractDate);
  //     return difference.inDays;
  //   } catch (e) {
  //     return 0;
  //   }
  // }

  // String _getNextUnitDate(String gereeniiOgnoo) {
  //   try {
  //     final contractDate = DateTime.parse(gereeniiOgnoo);
  //     // Calculate next unit date (assuming monthly units, add 1 month)
  //     final nextUnit = DateTime(
  //       contractDate.year,
  //       contractDate.month + 1,
  //       contractDate.day,
  //     );
  //     return '${nextUnit.year}-${nextUnit.month.toString().padLeft(2, '0')}-${nextUnit.day.toString().padLeft(2, '0')}';
  //   } catch (e) {
  //     return '';
  //   }
  // }

  // Widget _buildRemainingDaysWidget(model.Geree geree) {
  //   final daysPassed = _calculateDaysPassed(geree.gereeniiOgnoo);
  //   final nextUnitDate = _getNextUnitDate(geree.gereeniiOgnoo);

  //   // Use salmon-pink color similar to the image
  //   final accentColor = const Color(0xFFFF6B6B); // Salmon-pink color

  //   return Column(
  //     children: [
  //       // Large circular days display
  //       // Container(
  //       //   width: 200.w,
  //       //   height: 200.w,
  //       //   decoration: BoxDecoration(
  //       //     shape: BoxShape.circle,
  //       //     border: Border.all(
  //       //       color: accentColor,
  //       //       width: 8.w,
  //       //     ),
  //       //     color: Colors.transparent,
  //       //   ),
  //       //   child: Center(
  //       //     child: Column(
  //       //       mainAxisAlignment: MainAxisAlignment.center,
  //       //       children: [
  //       //         Text(
  //       //           '$daysPassed',
  //       //           style: TextStyle(
  //       //             fontSize: 64.sp,
  //       //             fontWeight: FontWeight.bold,
  //       //             color: accentColor,
  //       //             height: 1.0,
  //       //           ),
  //       //         ),
  //       //         SizedBox(height: 4.h),
  //       //         Text(
  //       //           'өдөр өнгөрсөн',
  //       //           style: TextStyle(
  //       //             fontSize: 14.sp,
  //       //             fontWeight: FontWeight.w600,
  //       //             color: accentColor,
  //       //           ),
  //       //         ),
  //       //       ],
  //       //     ),
  //       //   ),
  //       // ),
  //       SizedBox(height: 20.h),
  //       // Next unit date box
  //       OptimizedGlass(
  //         borderRadius: BorderRadius.circular(16.r),
  //         child: Container(
  //           padding: EdgeInsets.all(16.w),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.calendar_today_rounded,
  //                 color: accentColor,
  //                 size: 24.sp,
  //               ),
  //               SizedBox(width: 12.w),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Дараагийн нэгж',
  //                       style: TextStyle(
  //                         fontSize: 12.sp,
  //                         color: context.textSecondaryColor,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                     SizedBox(height: 4.h),
  //                     Text(
  //                       nextUnitDate,
  //                       style: TextStyle(
  //                         fontSize: 16.sp,
  //                         color: accentColor,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildHeroCard(model.Geree geree) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  AppColors.deepGreen.withOpacity(0.3),
                  AppColors.deepGreenAccent.withOpacity(0.15),
                ]
              : [
                  AppColors.deepGreen.withOpacity(0.1),
                  AppColors.deepGreenAccent.withOpacity(0.05),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.cardBackgroundColor.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.deepGreen.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.deepGreen,
                                  AppColors.deepGreenAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ГЭРЭЭНИЙ ДУГААР',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepGreen,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  geree.gereeniiDugaar,
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimaryColor,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen.withOpacity(0.2),
                        AppColors.deepGreenAccent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.deepGreen.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    geree.turul,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.surfaceElevatedColor.withOpacity(0.5)
                    : AppColors.lightAccentBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.deepGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 20.sp,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Гэрээний огноо',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDate(geree.gereeniiOgnoo),
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.cardBackgroundColor
            : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDarkMode
                    ? [
                        AppColors.deepGreen.withOpacity(0.2),
                        AppColors.deepGreenAccent.withOpacity(0.1),
                      ]
                    : [
                        AppColors.lightAccentBackground,
                        AppColors.lightAccentBackground.withOpacity(0.5),
                      ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: context.borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen,
                        AppColors.deepGreenAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepGreen.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 22.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.surfaceElevatedColor.withOpacity(0.6)
            : AppColors.lightAccentBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepGreen.withOpacity(0.2),
                  AppColors.deepGreenAccent.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: AppColors.deepGreen),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 18.sp : 15.sp,
                    fontWeight: isLarge ? FontWeight.w800 : FontWeight.w700,
                    color: valueColor ?? context.textPrimaryColor,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Ajiltan ajiltan) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  context.cardBackgroundColor,
                  context.surfaceElevatedColor.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  AppColors.lightAccentBackground.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepGreen,
                      AppColors.deepGreenAccent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 24.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ajiltan.ovog != null &&
                              ajiltan.ovog!.isNotEmpty &&
                              ajiltan.ner.isNotEmpty
                          ? '${ajiltan.ovog} ${ajiltan.ner}'
                          : ajiltan.ner.isNotEmpty
                          ? ajiltan.ner
                          : '-',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    if (ajiltan.albanTushaal != null &&
                        ajiltan.albanTushaal!.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepGreen.withOpacity(0.2),
                              AppColors.deepGreenAccent.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.deepGreen.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          ajiltan.albanTushaal!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Contact Information
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.surfaceElevatedColor.withOpacity(0.5)
                  : AppColors.lightAccentBackground.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildContactInfo(
                  icon: Icons.phone_rounded,
                  label: 'Утас',
                  value: ajiltan.utas.isNotEmpty ? ajiltan.utas : '-',
                ),
                if (ajiltan.mail != null && ajiltan.mail!.isNotEmpty) ...[
                  SizedBox(height: 11.h),
                  _buildContactInfo(
                    icon: Icons.email_rounded,
                    label: 'Имэйл',
                    value: ajiltan.mail!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepGreen.withOpacity(0.2),
                AppColors.deepGreenAccent.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 18.sp, color: AppColors.deepGreen),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
