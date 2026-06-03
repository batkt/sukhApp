import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:go_router/go_router.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  String? _currentAddress;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCurrentAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getUserProfile();

      if (response['success'] == true && response['result'] != null) {
        final userData = response['result'];

        setState(() {
          _userData = userData;
          _nameController.text = userData['ner']?.toString() ?? '';

          if (userData['utas'] != null) {
            final utas = userData['utas'];
            if (utas is List && utas.isNotEmpty) {
              _phoneController.text = utas.first.toString();
            } else {
              _phoneController.text = utas.toString();
            }
          }
          _emailController.text = userData['mail']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Хэрэглэгчийн мэдээлэл татахад алдаа гарлаа: $e',
          icon: Icons.error,
        );
      }
    }
  }

  Future<void> _loadCurrentAddress() async {
    try {
      final response = await ApiService.getUserProfile();

      if (response['success'] == true && response['result'] != null) {
        final userData = response['result'];
        String? addressText;

        if (userData['bairniiNer'] != null &&
            userData['bairniiNer'].toString().isNotEmpty) {
          addressText = userData['bairniiNer'].toString();
          if (userData['walletDoorNo'] != null &&
              userData['walletDoorNo'].toString().isNotEmpty) {
            addressText += ', ${userData['walletDoorNo']}';
          }
        } else {
          final bairId = await StorageService.getWalletBairId();
          final doorNo = await StorageService.getWalletDoorNo();
          if (bairId != null && doorNo != null) {
            addressText = 'Хаяг хадгалагдсан (Тоот: $doorNo)';
          }
        }

        if (mounted) {
          setState(() {
            _currentAddress = addressText;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleUpdateAddress() async {
    final result = await context.push('/address_selection');

    if (result == true && mounted) {
      await _loadCurrentAddress();
      await _loadUserProfile();
      showGlassSnackBar(
        context,
        message: 'Хаяг амжилттай шинэчлэгдлээ',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    }
  }

  Future<void> _handleRemoveToot(Map<String, dynamic> tootData) async {
    final residentId = _userData?['_id'];
    final baiguullagiinId = tootData['baiguullagiinId'];
    final barilgiinId = tootData['barilgiinId'];
    final toot = tootData['toot'];

    if (residentId == null || baiguullagiinId == null || toot == null) {
      showGlassSnackBar(
        context,
        message: 'Мэдээлэл дутуу байна',
        icon: Icons.error,
      );
      return;
    }

    final isDark = context.isDarkMode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Бүртгэл цуцлах',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$toot тоот бүртгэлийг цуцлахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Үгүй',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Тийм, цуцлах',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.removeToot(
        residentId: residentId.toString(),
        baiguullagiinId: baiguullagiinId.toString(),
        barilgiinId: barilgiinId?.toString(),
        toot: toot.toString(),
      );

      showGlassSnackBar(
        context,
        message: 'Бүртгэл амжилттай цуцлагдлаа',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      await _loadUserProfile();
      await _loadCurrentAddress();
    } catch (e) {
      showGlassSnackBar(
        context,
        message: 'Алдаа гарлаа: $e',
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.deepGreen,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Address Info
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.deepGreen.withOpacity(0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.4) : AppColors.deepGreen.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildSubSectionTitle('Хаягийн мэдээлэл'),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => _handleUpdateAddress(),
                                      icon: Icon(
                                        Icons.edit_location_alt_rounded,
                                        size: 14.sp,
                                      ),
                                      label: Text(
                                        'Солих',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.deepGreen,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 4.h,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                if (_userData != null)
                                  _buildUserDataGrid()
                                else
                                  _buildAddressPlaceholder(context),
                              ],
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // Section 2: Basic Info
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.deepGreen.withOpacity(0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.4) : AppColors.deepGreen.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSubSectionTitle('Үндсэн мэдээлэл'),
                                SizedBox(height: 16.h),
                                _buildModernTextField(
                                  controller: _nameController,
                                  label: 'Нэр',
                                  icon: Icons.person_outline_rounded,
                                  enabled: true,
                                  hint: 'Нэр оруулах',
                                ),
                                SizedBox(height: 16.h),
                                _buildModernTextField(
                                  controller: _phoneController,
                                  label: 'Утасны дугаар',
                                  icon: Icons.phone_android_rounded,
                                  enabled: true,
                                  hint: 'Утасны дугаар оруулна уу',
                                  keyboardType: TextInputType.phone,
                                ),
                                SizedBox(height: 16.h),
                                _buildModernTextField(
                                  controller: _emailController,
                                  label: 'И-мэйл хаяг',
                                  icon: Icons.alternate_email_rounded,
                                  enabled: true,
                                  hint: 'И-мэйл хаяг оруулах',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                SizedBox(height: 24.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_phoneController.text.trim().isEmpty) {
                                        showGlassSnackBar(
                                          context,
                                          message: 'Утасны дугаараа оруулна уу',
                                          icon: Icons.warning,
                                        );
                                        return;
                                      }
                                      if (_emailController.text.isNotEmpty) {
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(_emailController.text)) {
                                          showGlassSnackBar(
                                            context,
                                            message: 'Зөв и-мэйл хаяг оруулна уу',
                                            icon: Icons.error,
                                          );
                                          return;
                                        }
                                      }

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        final response = await ApiService.updateUserProfile({
                                          'ner': _nameController.text.trim(),
                                          'mail': _emailController.text.trim(),
                                          'utas': _phoneController.text.trim(),
                                        });
                                        if (response['success'] == true || response['_id'] != null) {
                                          showGlassSnackBar(
                                            context,
                                            message: 'Мэдээлэл амжилттай хадгалагдлаа',
                                            icon: Icons.check_circle,
                                            iconColor: Colors.green,
                                          );
                                          await _loadUserProfile();
                                        }
                                      } catch (e) {
                                        showGlassSnackBar(
                                          context,
                                          message: 'Алдаа гарлаа: $e',
                                          icon: Icons.error,
                                        );
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepGreen,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Хадгалах',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildHeader() {
    final isDark = context.isDarkMode;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.deepGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Хувийн мэдээлэл',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : context.textPrimaryColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textSecondaryColor,
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAddressPlaceholder(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: () => _handleUpdateAddress(),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.deepGreen,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentAddress != null && _currentAddress!.isNotEmpty
                        ? _currentAddress!
                        : 'Хаяг бүртгэгдээгүй байна',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_currentAddress == null || _currentAddress!.isEmpty)
                    Text(
                      'Энд дарж хаягаа сонгоно уу',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataGrid() {
    if (_userData == null) return const SizedBox.shrink();

    List<Map<String, dynamic>> dataItems = [];

    final List toots = (_userData!['toots'] != null && _userData!['toots'] is List)
        ? List.from(_userData!['toots'])
        : [];

    if (toots.isNotEmpty) {
      for (var t in toots) {
        final bName = t['bairniiNer'] ?? t['baiguullagiinNer'] ?? 'Тодорхойгүй';
        final tNo = t['toot'] ?? '???';

        dataItems.add({
          'icon': Icons.home_rounded,
          'label': '$bName',
          'value': '$tNo тоот',
          'action': toots.length > 1
              ? () {
                  _handleRemoveToot(Map<String, dynamic>.from(t));
                }
              : null,
          'isRemovable': toots.length > 1,
        });
      }
    } else {
      String? bairText;
      if (_userData!['bairniiNer'] != null &&
          _userData!['bairniiNer'].toString().isNotEmpty) {
        bairText = _userData!['bairniiNer'].toString();
      }

      final hasAddress = bairText != null && bairText.isNotEmpty;
      dataItems.add({
        'icon': Icons.location_on_outlined,
        'label': 'Байр',
        'value': hasAddress ? bairText! : 'Хаяг сонгох',
        'action': !hasAddress
            ? () {
                _handleUpdateAddress();
              }
            : null,
        'isLink': !hasAddress,
      });

      String? tootText;
      if (_userData!['walletDoorNo'] != null &&
          _userData!['walletDoorNo'].toString().isNotEmpty) {
        tootText = _userData!['walletDoorNo'].toString();
      }
      if (tootText != null && tootText.isNotEmpty) {
        dataItems.add({
          'icon': Icons.home_outlined,
          'label': 'Тоот',
          'value': tootText,
        });
      }
    }

    if (dataItems.isEmpty) {
      return Text(
        'Мэдээлэл олдсонгүй',
        style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
      );
    }

    final isDark = context.isDarkMode;

    return Column(
      children: dataItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == dataItems.length - 1;
        final action = item['action'] as VoidCallback?;
        final isLink = item['isLink'] == true;
        final isRemovable = item['isRemovable'] == true;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isRemovable ? Colors.red.withOpacity(0.1) : AppColors.deepGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: isRemovable ? Colors.red[400] : AppColors.deepGreen,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item['value'] as String,
                      style: TextStyle(
                        color: isLink ? AppColors.deepGreen : (isDark ? Colors.white : Colors.black87),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isLink)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.deepGreen,
                  size: 20.sp,
                ),
              if (isRemovable)
                IconButton(
                  onPressed: action,
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red[400],
                    size: 20.sp,
                  ),
                  tooltip: 'Цуцлах',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.r,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? hint,
    VoidCallback? onTap,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = context.isDarkMode;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: isPassword,
      onTap: onTap,
      readOnly: !enabled || onTap != null,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      autofocus: false,
      style: TextStyle(
        color: enabled ? context.textPrimaryColor : context.textSecondaryColor,
        fontSize: 13.sp,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.6)
              : AppColors.lightTextSecondary,
          fontSize: 12.sp,
        ),
        prefixIcon: Icon(icon, color: AppColors.deepGreen, size: 18.sp),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF8F8F8),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : AppColors.deepGreen.withOpacity(0.3),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.deepGreen.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 1.5.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.w),
          borderSide: BorderSide(color: Colors.red, width: 1.5.w),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: context.textSecondaryColor.withOpacity(0.5),
          fontSize: 13.sp,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Энэ талбарыг бөглөнө үү';
        }
        return null;
      },
    );
  }
}
