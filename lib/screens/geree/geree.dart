import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/models/geree_model.dart' as model;
import 'package:sukh_app/models/ajiltan_model.dart';

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
      print('Error fetching ajiltan data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Гэрээ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe6ff00)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.6),
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _fetchGereeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe6ff00),
                foregroundColor: const Color(0xFF0a0e27),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('Дахин оролдох', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      );
    }

    if (_gereeData == null || _gereeData!.jagsaalt.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ],
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
          // Invoice Header Section
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.w),
              border: Border.all(
                color: const Color(0xFFe6ff00).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ГЭРЭЭНИЙ ДУГААР',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFe6ff00),
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          geree.gereeniiDugaar,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.w),
                      ),
                      child: Text(
                        geree.turul,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Гэрээний огноо: ${_formatDate(geree.gereeniiOgnoo)}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Customer Information Section
          _buildSection(
            title: 'ХАРИЛЦАГЧИЙН МЭДЭЭЛЭЛ',
            icon: Icons.person_outline,
            children: [
              _buildInvoiceDetailRow(
                icon: Icons.badge_outlined,
                label: 'Овог нэр',
                value: '${geree.ovog} ${geree.ner}',
              ),
              Divider(color: Colors.white10, height: 24.h),
              _buildInvoiceDetailRow(
                icon: Icons.phone_outlined,
                label: 'Утас',
                value: geree.utas.isNotEmpty ? geree.utas.join(', ') : '-',
              ),
              if (geree.temdeglel.isNotEmpty) ...[
                Divider(color: Colors.white10, height: 24.h),
                _buildInvoiceDetailRow(
                  icon: Icons.note_outlined,
                  label: 'Тэмдэглэл',
                  value: geree.temdeglel,
                ),
              ],
              if (geree.suhUtas.isNotEmpty) ...[
                Divider(color: Colors.white10, height: 24.h),
                _buildInvoiceDetailRow(
                  icon: Icons.phone_android_outlined,
                  label: 'Сөх утас',
                  value: geree.suhUtas.join(', '),
                ),
              ],
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
              Divider(color: Colors.white10, height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _buildInvoiceDetailRow(
                      icon: Icons.numbers,
                      label: 'Тоот',
                      value: geree.toot.toString(),
                    ),
                  ),
                  SizedBox(width: 16.w),
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
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFe6ff00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: const Color(0xFFe6ff00).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFe6ff00),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Таньд ${_gereeData!.jagsaalt.length} гэрээ байна',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.sp,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: const Color(0xFFe6ff00)),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFe6ff00),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: Colors.white.withOpacity(0.4)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 18.sp : 14.sp,
                  fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Ajiltan ajiltan) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFe6ff00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Icon(
                  Icons.person,
                  size: 20.sp,
                  color: const Color(0xFFe6ff00),
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
                      ),
                    ),
                    if (ajiltan.albanTushaal != null &&
                        ajiltan.albanTushaal!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        ajiltan.albanTushaal!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFe6ff00).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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
          Row(
            children: [
              Expanded(
                child: _buildContactInfo(
                  icon: Icons.phone,
                  label: 'Утас',
                  value: ajiltan.utas.isNotEmpty ? ajiltan.utas : '-',
                ),
              ),
            ],
          ),

          if (ajiltan.mail != null && ajiltan.mail!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildContactInfo(
              icon: Icons.email,
              label: 'Имэйл',
              value: ajiltan.mail!,
            ),
          ],
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
        Icon(icon, size: 14.sp, color: Colors.white.withOpacity(0.5)),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
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
    );
  }
}
