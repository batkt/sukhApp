import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/models/geree_model.dart' as model;
import 'package:sukh_app/models/ajiltan_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';

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
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header with liquid glass styling
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Row(
                  children: [
                    // Menu Button with liquid glass
                    SizedBox(
                      height: 48.h,
                      child: OptimizedGlass(
                        borderRadius: BorderRadius.circular(11.r),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            borderRadius: BorderRadius.circular(11.r),
                            child: Padding(
                              padding: EdgeInsets.all(11.w),
                              child: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Title with liquid glass card
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: OptimizedGlass(
                          borderRadius: BorderRadius.circular(11.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description_rounded,
                                    color: AppColors.goldPrimary,
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 11.w),
                                  Text(
                                    'Гэрээ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Back button with liquid glass
                    SizedBox(
                      height: 48.h,
                      child: OptimizedGlass(
                        borderRadius: BorderRadius.circular(11.r),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(11.r),
                            child: Padding(
                              padding: EdgeInsets.all(11.w),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
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
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: OptimizedGlass(
            borderRadius: BorderRadius.circular(22.r),
            opacity: 0.10,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.withOpacity(0.8),
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  OptimizedGlass(
                    borderRadius: BorderRadius.circular(12.r),
                    opacity: 0.10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _fetchGereeData,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          child: Text(
                            'Дахин оролдох',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
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
          padding: EdgeInsets.all(20.w),
          child: OptimizedGlass(
            borderRadius: BorderRadius.circular(22.r),
            opacity: 0.10,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Colors.white.withOpacity(0.6),
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Гэрээний мэдээлэл олдсонгүй',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
          // Invoice Header Section (optimized glass)
          OptimizedGlass(
            borderRadius: BorderRadius.circular(22.r),
            opacity: 0.10,
            child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
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
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.goldPrimary.withOpacity(
                                              0.3,
                                            ),
                                            AppColors.goldPrimary.withOpacity(
                                              0.15,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          11.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
                                        color: AppColors.goldPrimary,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 11.w),
                                    Text(
                                      'ГЭРЭЭНИЙ ДУГААР',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryAccent,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 11.h),
                                Text(
                                  geree.gereeniiDugaar,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withOpacity(0.2),
                                  AppColors.goldPrimary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.w),
                              border: Border.all(
                                color: AppColors.goldPrimary.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              geree.turul,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(11.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18.sp,
                              color: AppColors.goldPrimary,
                            ),
                            SizedBox(width: 11.w),
                            Text(
                              'Гэрээний огноо: ${_formatDate(geree.gereeniiOgnoo)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),

          SizedBox(height: 20.h),

          // Customer Information Section
          _buildSection(
            title: 'ХАРИЛЦАГЧИЙН МЭДЭЭЛЭЛ',
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
            OptimizedGlass(
              borderRadius: BorderRadius.circular(18.r),
              opacity: 0.10,
              child: Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryAccent.withOpacity(0.15),
                          AppColors.secondaryAccent.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: AppColors.secondaryAccent.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(11.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondaryAccent.withOpacity(0.3),
                                AppColors.secondaryAccent.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(11.r),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.secondaryAccent,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Таньд ${_gereeData!.jagsaalt.length} гэрээ байна',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return OptimizedGlass(
      borderRadius: BorderRadius.circular(22.r),
      opacity: 0.10,
      child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(18.w),
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
                      Container(
                        padding: EdgeInsets.all(11.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.goldPrimary.withOpacity(0.3),
                              AppColors.goldPrimary.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Icon(
                          icon,
                          size: 20.sp,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ),
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
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.goldPrimary),
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
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 18.sp : 14.sp,
                    fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? Colors.white,
                    letterSpacing: -0.3,
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
    return OptimizedGlass(
      borderRadius: BorderRadius.circular(18.r),
      opacity: 0.10,
      child: Container(
            padding: EdgeInsets.all(18.w),
            margin: EdgeInsets.only(bottom: 11.h),
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
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name with icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(11.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldPrimary.withOpacity(0.3),
                            AppColors.goldPrimary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 22.sp,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                    SizedBox(width: 12.w),
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
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (ajiltan.albanTushaal != null &&
                              ajiltan.albanTushaal!.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondaryAccent.withOpacity(0.2),
                                    AppColors.secondaryAccent.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.secondaryAccent.withOpacity(
                                    0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                ajiltan.albanTushaal!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.secondaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Contact Information
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(11.r),
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
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.goldPrimary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
