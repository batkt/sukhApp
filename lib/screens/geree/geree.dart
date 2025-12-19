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
                  veryNarrow: 16,
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
                      veryNarrow: 12,
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
                        veryNarrow: 12,
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
                      veryNarrow: 18,
                    ),
                  ),
                  OptimizedGlass(
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 12,
                        medium: 14,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 10,
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
                              veryNarrow: 18,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
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
                                veryNarrow: 12,
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
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                  ),
                  Text(
                    'Гэрээний мэдээлэл олдсонгүй',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 17,
                        veryNarrow: 12,
                      ),
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
      padding: context.responsivePadding(
        small: 20,
        medium: 22,
        large: 24,
        tablet: 26,
        veryNarrow: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Hero Card with Gradient
          _buildHeroCard(geree),
          SizedBox(
            height: context.responsiveSpacing(
              small: 24,
              medium: 28,
              large: 32,
              tablet: 36,
              veryNarrow: 16,
            ),
          ),

          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),

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

          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),

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
                  SizedBox(
                    width: context.responsiveSpacing(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 8,
                    ),
                  ),
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

          SizedBox(
            height: context.responsiveSpacing(
              small: 20,
              medium: 24,
              large: 28,
              tablet: 32,
              veryNarrow: 14,
            ),
          ),

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
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 22,
                            veryNarrow: 12,
                          ),
                        ),
                      _buildEmployeeCard(ajiltan),
                    ],
                  );
                }),
              ],
            ),

          if (_ajiltanData != null && _ajiltanData!.jagsaalt.isNotEmpty)
            SizedBox(
              height: context.responsiveSpacing(
                small: 20,
                medium: 24,
                large: 28,
                tablet: 32,
                veryNarrow: 14,
              ),
            ),

          // If there are multiple contracts, show selector
          if (_gereeData!.jagsaalt.length > 1) ...[
            SizedBox(
              height: context.responsiveSpacing(
                small: 24,
                medium: 28,
                large: 32,
                tablet: 36,
                veryNarrow: 16,
              ),
            ),
            Container(
              padding: context.responsivePadding(
                small: 20,
                medium: 22,
                large: 24,
                tablet: 26,
                veryNarrow: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen.withOpacity(0.15),
                    AppColors.deepGreenAccent.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 16,
                  ),
                ),
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
                    padding: context.responsivePadding(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.deepGreen,
                          AppColors.deepGreenAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 14,
                          medium: 16,
                          large: 18,
                          tablet: 20,
                          veryNarrow: 12,
                        ),
                      ),
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
                      size: context.responsiveIconSize(
                        small: 22,
                        medium: 24,
                        large: 26,
                        tablet: 28,
                        veryNarrow: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: context.responsiveSpacing(
                      small: 14,
                      medium: 16,
                      large: 18,
                      tablet: 20,
                      veryNarrow: 10,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Таньд ${_gereeData!.jagsaalt.length} гэрээ байна',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 15,
                          medium: 16,
                          large: 17,
                          tablet: 18,
                          veryNarrow: 13,
                        ),
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
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 24,
            medium: 26,
            large: 28,
            tablet: 30,
            veryNarrow: 18,
          ),
        ),
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
        padding: context.responsivePadding(
          small: 24,
          medium: 26,
          large: 28,
          tablet: 30,
          veryNarrow: 18,
        ),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.cardBackgroundColor.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 24,
              medium: 26,
              large: 28,
              tablet: 30,
              veryNarrow: 18,
            ),
          ),
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
                            padding: context.responsivePadding(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 10,
                    ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.deepGreen,
                                  AppColors.deepGreenAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 14,
                          medium: 16,
                          large: 18,
                          tablet: 20,
                          veryNarrow: 12,
                        ),
                      ),
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
                              size: context.responsiveIconSize(
                              small: 24,
                              medium: 26,
                              large: 28,
                              tablet: 30,
                              veryNarrow: 20,
                            ),
                            ),
                          ),
                          SizedBox(
                    width: context.responsiveSpacing(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 8,
                    ),
                  ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ГЭРЭЭНИЙ ДУГААР',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(
                                      small: 11,
                                      medium: 12,
                                      large: 13,
                                      tablet: 14,
                                      veryNarrow: 10,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepGreen,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(
                                  height: context.responsiveSpacing(
                                    small: 6,
                                    medium: 8,
                                    large: 10,
                                    tablet: 12,
                                    veryNarrow: 4,
                                  ),
                                ),
                                Text(
                                  geree.gereeniiDugaar,
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(
                                      small: 24,
                                      medium: 26,
                                      large: 28,
                                      tablet: 30,
                                      veryNarrow: 20,
                                    ),
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
                    horizontal: context.responsiveSpacing(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                    vertical: context.responsiveSpacing(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                      veryNarrow: 8,
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen.withOpacity(0.2),
                        AppColors.deepGreenAccent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 20,
                        medium: 22,
                        large: 24,
                        tablet: 26,
                        veryNarrow: 16,
                      ),
                    ),
                    border: Border.all(
                      color: AppColors.deepGreen.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    geree.turul,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(
                        small: 13,
                        medium: 14,
                        large: 15,
                        tablet: 16,
                        veryNarrow: 11,
                      ),
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: context.responsiveSpacing(
                small: 20,
                medium: 24,
                large: 28,
                tablet: 32,
                veryNarrow: 14,
              ),
            ),
            Container(
                  padding: context.responsivePadding(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.surfaceElevatedColor.withOpacity(0.5)
                    : AppColors.lightAccentBackground,
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
                ),
                border: Border.all(
                  color: AppColors.deepGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: context.responsivePadding(
                      small: 10,
                      medium: 12,
                      large: 14,
                      tablet: 16,
                      veryNarrow: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
              ),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: context.responsiveIconSize(
                        small: 20,
                        medium: 22,
                        large: 24,
                        tablet: 26,
                        veryNarrow: 18,
                      ),
                      color: AppColors.deepGreen,
                    ),
                  ),
                  SizedBox(
                    width: context.responsiveSpacing(
                      small: 14,
                      medium: 16,
                      large: 18,
                      tablet: 20,
                      veryNarrow: 10,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Гэрээний огноо',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                          small: 11,
                          medium: 12,
                          large: 13,
                          tablet: 14,
                          veryNarrow: 10,
                        ),
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: context.responsiveSpacing(
                            small: 4,
                            medium: 6,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 3,
                          ),
                        ),
                        Text(
                          _formatDate(geree.gereeniiOgnoo),
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                          small: 15,
                          medium: 16,
                          large: 17,
                          tablet: 18,
                          veryNarrow: 13,
                        ),
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
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 24,
          medium: 28,
          large: 32,
          tablet: 36,
          veryNarrow: 16,
        ),
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.cardBackgroundColor
            : Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 24,
            medium: 26,
            large: 28,
            tablet: 30,
            veryNarrow: 18,
          ),
        ),
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
            padding: context.responsivePadding(
              small: 20,
              medium: 22,
              large: 24,
              tablet: 26,
              veryNarrow: 14,
            ),
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
                topLeft: Radius.circular(
                  context.responsiveBorderRadius(
                    small: 24,
                    medium: 26,
                    large: 28,
                    tablet: 30,
                    veryNarrow: 18,
                  ),
                ),
                topRight: Radius.circular(
                  context.responsiveBorderRadius(
                    small: 24,
                    medium: 26,
                    large: 28,
                    tablet: 30,
                    veryNarrow: 18,
                  ),
                ),
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
                  padding: context.responsivePadding(
                    small: 12,
                    medium: 14,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen,
                        AppColors.deepGreenAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 14,
                        medium: 16,
                        large: 18,
                        tablet: 20,
                        veryNarrow: 12,
                      ),
                    ),
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
                SizedBox(
                  width: context.responsiveSpacing(
                    small: 14,
                    medium: 16,
                    large: 18,
                    tablet: 20,
                    veryNarrow: 10,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                      veryNarrow: 12,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: context.responsivePadding(
              small: 20,
              medium: 22,
              large: 24,
              tablet: 26,
              veryNarrow: 14,
            ),
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
                  padding: context.responsivePadding(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 8,
        ),
      ),
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
            padding: context.responsivePadding(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepGreen.withOpacity(0.2),
                  AppColors.deepGreenAccent.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: context.responsiveIconSize(
                small: 20,
                medium: 22,
                large: 24,
                tablet: 26,
                veryNarrow: 18,
              ),
              color: AppColors.deepGreen,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                      veryNarrow: 11,
                    ),
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge
                        ? context.responsiveFontSize(
                            small: 18,
                            medium: 20,
                            large: 22,
                            tablet: 24,
                            veryNarrow: 16,
                          )
                        : context.responsiveFontSize(
                            small: 15,
                            medium: 16,
                            large: 17,
                            tablet: 18,
                            veryNarrow: 13,
                          ),
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
            padding: context.responsivePadding(
              small: 20,
              medium: 22,
              large: 24,
              tablet: 26,
              veryNarrow: 14,
            ),
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 22,
          veryNarrow: 12,
        ),
      ),
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
                  size: context.responsiveIconSize(
                    small: 24,
                    medium: 26,
                    large: 28,
                    tablet: 30,
                    veryNarrow: 20,
                  ),
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
                        fontSize: context.responsiveFontSize(
                          small: 18,
                          medium: 20,
                          large: 22,
                          tablet: 24,
                          veryNarrow: 16,
                        ),
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    if (ajiltan.albanTushaal != null &&
                        ajiltan.albanTushaal!.isNotEmpty) ...[
                      SizedBox(
                  height: context.responsiveSpacing(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  ),
                ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                          vertical: context.responsiveSpacing(
                            small: 6,
                            medium: 8,
                            large: 10,
                            tablet: 12,
                            veryNarrow: 4,
                          ),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepGreen.withOpacity(0.2),
                              AppColors.deepGreenAccent.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            context.responsiveBorderRadius(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            ),
                          ),
                          border: Border.all(
                            color: AppColors.deepGreen.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          ajiltan.albanTushaal!,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                      veryNarrow: 11,
                    ),
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

          SizedBox(
            height: context.responsiveSpacing(
              small: 18,
              medium: 20,
              large: 22,
              tablet: 24,
              veryNarrow: 14,
            ),
          ),

          // Contact Information
          Container(
                  padding: context.responsivePadding(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
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
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 11,
                      medium: 13,
                      large: 15,
                      tablet: 17,
                      veryNarrow: 8,
                    ),
                  ),
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
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 10,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: context.responsiveIconSize(
              small: 18,
              medium: 20,
              large: 22,
              tablet: 24,
              veryNarrow: 16,
            ),
            color: AppColors.deepGreen,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(
                height: context.responsiveSpacing(
                  small: 6,
                  medium: 8,
                  large: 10,
                  tablet: 12,
                  veryNarrow: 4,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 17,
                          veryNarrow: 12,
                        ),
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
