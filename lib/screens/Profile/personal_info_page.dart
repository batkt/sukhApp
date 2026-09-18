import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/ger_bul_service.dart';
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

  // ── Оршин суугчийн БҮХ мэдээллийг нэг дэлгэцээс харуулах хэсгүүд ──────
  // Гэрээ, үлдэгдэл, гэр бүлийн гишүүд, гүйлгээг аль хэдийн байгаа
  // service-үүдээр татна (шинэ endpoint шаардахгүй). Профайл ачаалагдсаны
  // ДАРАА зэрэгцээ татагдана — эс тэгвээс үндсэн мэдээлэл хүлээгдэнэ.
  bool _kholbootoiUnshij = false;
  List<Map<String, dynamic>> _gereenuud = [];
  List<Map<String, dynamic>> _gishuud = [];
  List<Map<String, dynamic>> _guilgeenuud = [];
  /// gereeniiId -> үлдэгдэл
  final Map<String, num> _uldegdluud = {};

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

        // Профайл гарт орсны дараа холбоотой бүх мэдээллийг татна.
        _kholbootoiMedeelelTataya();
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

  /// Гэрээ, үлдэгдэл, гэр бүлийн гишүүд, гүйлгээг татна.
  Future<void> _kholbootoiMedeelelTataya() async {
    final orshinSuugchId = _userData?['_id']?.toString();
    if (orshinSuugchId == null || orshinSuugchId.isEmpty) return;
    if (!mounted) return;
    setState(() => _kholbootoiUnshij = true);

    final baiguullagiinId =
        (await StorageService.getBaiguullagiinId()) ??
        _userData?['baiguullagiinId']?.toString();

    // Гишүүдийг гэрээнээс хамааралгүйгээр зэрэг татна.
    final gishuudFuture = _gishuudTataya();

    List<Map<String, dynamic>> gereenuud = [];
    try {
      final resp = await ApiService.fetchGeree(orshinSuugchId);
      final jagsaalt = resp['jagsaalt'] ?? resp['result'] ?? resp['data'];
      if (jagsaalt is List) {
        gereenuud = jagsaalt
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}

    // Гэрээ тус бүрийн үлдэгдэл. Гэрээ олон байж болох тул зэрэгцээ.
    if (baiguullagiinId != null && baiguullagiinId.isNotEmpty) {
      await Future.wait(
        gereenuud.map((g) async {
          final gid = g['_id']?.toString();
          if (gid == null || gid.isEmpty) return;
          try {
            final resp = await ApiService.fetchUldegdelBodyo(
              gereeniiId: gid,
              baiguullagiinId: baiguullagiinId,
            );
            final dun = resp['uldegdel'] ?? resp['dun'] ?? resp['result'];
            if (dun is num) _uldegdluud[gid] = dun;
          } catch (_) {}
        }),
      );
    }

    // Гүйлгээг ИДЭВХТЭЙ (эсвэл хамгийн эхний) гэрээнээс авна.
    List<Map<String, dynamic>> guilgeenuud = [];
    final undsenGeree = gereenuud.isNotEmpty ? gereenuud.first : null;
    final undsenGereeId = undsenGeree?['_id']?.toString();
    if (undsenGereeId != null &&
        undsenGereeId.isNotEmpty &&
        baiguullagiinId != null &&
        baiguullagiinId.isNotEmpty) {
      try {
        final resp = await ApiService.fetchGuilgeeAvlaguud(
          gereeniiId: undsenGereeId,
          baiguullagiinId: baiguullagiinId,
          khuudasniiKhemjee: 50,
        );
        final jagsaalt = resp['jagsaalt'] ?? resp['result'] ?? resp['data'];
        if (jagsaalt is List) {
          guilgeenuud = jagsaalt
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    final gishuud = await gishuudFuture;

    if (!mounted) return;
    setState(() {
      _gereenuud = gereenuud;
      _guilgeenuud = guilgeenuud;
      _gishuud = gishuud;
      _kholbootoiUnshij = false;
    });
  }

  Future<List<Map<String, dynamic>>> _gishuudTataya() async {
    try {
      final garalt = await GerBulService.gishuudAvya();
      final dynamic khureelen = garalt;
      // Моделийн бүтэц өөрчлөгдвөл ч дэлгэц унахгүй байхаар хамгаалав.
      final dynamic gishuud = khureelen.gishuud;
      if (gishuud is List) {
        return gishuud
            .map<Map<String, dynamic>>(
              (g) => <String, dynamic>{
                'ner': _dynTekst(g, 'ner'),
                'ovog': _dynTekst(g, 'ovog'),
                'utas': _dynTekst(g, 'utas'),
                'kholboo': _dynTekst(g, 'gishuuniiKholboo'),
                'tuluv': _dynTekst(g, 'gishuuniiTuluv'),
                'erkh': _dynTekst(g, 'gishuuniiErkh'),
              },
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static String? _dynTekst(dynamic obj, String talbar) {
    try {
      if (obj is Map) return obj[talbar]?.toString();
      final utga = (obj as dynamic);
      switch (talbar) {
        case 'ner':
          return utga.ner?.toString();
        case 'ovog':
          return utga.ovog?.toString();
        case 'utas':
          return utga.utas?.toString();
        case 'gishuuniiKholboo':
          return utga.gishuuniiKholboo?.toString();
        case 'gishuuniiTuluv':
          return utga.gishuuniiTuluv?.toString();
        case 'gishuuniiErkh':
          return utga.gishuuniiErkh?.toString();
      }
    } catch (_) {}
    return null;
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

                          // ── Оршин суугчийн БҮХ мэдээлэл нэг дэлгэцэд ──
                          // Тоот, гэрээ, үлдэгдэл, гэр бүл, гүйлгээ — бүгд
                          // энэ дэлгэцээс харагдана (вебийн 'нүд' товчны
                          // модалтай ижил агуулга, оршин суугчийн өөрийнх).
                          _buildKhesegKart(
                            'Тоот / хаягийн дэлгэрэнгүй',
                            _buildTootuudKheseg(),
                          ),
                          _buildKhesegKart('Гэрээ', _buildGereeKheseg()),
                          _buildKhesegKart(
                            'Гэр бүлийн гишүүд',
                            _buildGishuudKheseg(),
                          ),
                          _buildKhesegKart(
                            'Сүүлийн гүйлгээ',
                            _buildGuilgeeKheseg(),
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

  /// Уншигдахуйц тоо (1,234,567)
  static String _tooKharuul(dynamic utga) {
    final too = utga is num ? utga : num.tryParse(utga?.toString() ?? '');
    if (too == null) return '—';
    final butarkhaigui = too.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < butarkhaigui.length; i++) {
      if (i > 0 && (butarkhaigui.length - i) % 3 == 0) buf.write(',');
      buf.write(butarkhaigui[i]);
    }
    return "${too < 0 ? '-' : ''}$buf";
  }

  static String _tekstUtga(dynamic utga) {
    if (utga == null) return '—';
    final s = utga.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  static String _ognooKharuul(dynamic utga) {
    if (utga == null) return '—';
    final o = DateTime.tryParse(utga.toString());
    if (o == null) return '—';
    final sar = o.month.toString().padLeft(2, '0');
    final odor = o.day.toString().padLeft(2, '0');
    return '${o.year}-$sar-$odor';
  }

  /// Бусад хэсгүүдтэй ижил харагдацтай карт.
  Widget _buildKhesegKart(String garchig, Widget kheseg) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.deepGreen.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.deepGreen.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubSectionTitle(garchig),
          SizedBox(height: 12.h),
          kheseg,
        ],
      ),
    );
  }

  Widget _buildMur(String ner, String utga) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              ner,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              utga,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhooson(String bichig) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        bichig,
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }

  /// Тоот бүрийн бүрэн мэдээлэл (олон тоотыг бүгдийг харуулна).
  Widget _buildTootuudKheseg() {
    final List toots =
        (_userData?['toots'] is List) ? List.from(_userData!['toots']) : [];
    if (toots.isEmpty) return _buildKhooson('Бүртгэлтэй тоот алга');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in toots.whereType<Map>())
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMur('Тоот', _tekstUtga(t['toot'])),
                _buildMur('Төрөл', _tekstUtga(t['turul'])),
                _buildMur('Байр', _tekstUtga(t['bairniiNer'])),
                _buildMur(
                  'Давхар / орц',
                  "${_tekstUtga(t['davkhar'])} / ${_tekstUtga(t['orts'])}",
                ),
                _buildMur(
                  'Дүүрэг / СӨХ',
                  "${_tekstUtga(t['duureg'])} / ${_tekstUtga(t['soh'])}",
                ),
                _buildMur(
                  'Үлдэгдэл',
                  "${_tooKharuul(t['uldegdel'] ?? t['ekhniiUldegdel'] ?? 0)}₮",
                ),
                _buildMur('Цахилгааны заалт', _tekstUtga(t['tsahilgaaniiZaalt'])),
                if (toots.length > 1) Divider(height: 16.h),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGereeKheseg() {
    if (_kholbootoiUnshij && _gereenuud.isEmpty) {
      return _buildKhooson('Уншиж байна...');
    }
    if (_gereenuud.isEmpty) return _buildKhooson('Гэрээ олдсонгүй');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in _gereenuud)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMur('Дугаар', _tekstUtga(g['gereeniiDugaar'])),
                _buildMur('Тоот', _tekstUtga(g['toot'])),
                _buildMur('Төлөв', _tekstUtga(g['tuluv'])),
                _buildMur(
                  'Хугацаа',
                  "${_ognooKharuul(g['ekhlekhOgnoo'])} — ${_ognooKharuul(g['duusakhOgnoo'])}",
                ),
                _buildMur(
                  'Үлдэгдэл',
                  "${_tooKharuul(_uldegdluud[g['_id']?.toString()] ?? g['ekhniiUldegdel'] ?? 0)}₮",
                ),
                if (_gereenuud.length > 1) Divider(height: 16.h),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGishuudKheseg() {
    if (_kholbootoiUnshij && _gishuud.isEmpty) {
      return _buildKhooson('Уншиж байна...');
    }
    if (_gishuud.isEmpty) return _buildKhooson('Гишүүн бүртгэгдээгүй');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in _gishuud)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMur(
                  'Нэр',
                  "${_tekstUtga(g['ovog'])} ${_tekstUtga(g['ner'])}",
                ),
                _buildMur('Утас', _tekstUtga(g['utas'])),
                _buildMur('Холбоо', _tekstUtga(g['kholboo'])),
                _buildMur(
                  'Төлөв / эрх',
                  "${_tekstUtga(g['tuluv'])} · ${_tekstUtga(g['erkh'])}",
                ),
                if (_gishuud.length > 1) Divider(height: 16.h),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGuilgeeKheseg() {
    if (_kholbootoiUnshij && _guilgeenuud.isEmpty) {
      return _buildKhooson('Уншиж байна...');
    }
    if (_guilgeenuud.isEmpty) return _buildKhooson('Гүйлгээ олдсонгүй');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in _guilgeenuud.take(20))
          _buildMur(
            _ognooKharuul(g['ognoo']),
            "${_tekstUtga(g['turul'])} · ${_tooKharuul(g['dun'])}₮",
          ),
      ],
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
