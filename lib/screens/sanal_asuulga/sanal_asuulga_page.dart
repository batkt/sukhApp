import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sukh_app/services/api_service.dart' show ApiService;
import 'package:sukh_app/services/storage_service.dart';

/// App Sanal Asuulga (Polls & Surveys) Screen
/// Pixel-perfect redesign inspired by modern Emerald/Mint design system.

// --- Design Palette & Tokens ---
const Color _kPrimaryEmerald = Color(0xFF00B074);
const Color _kDarkEmerald = Color(0xFF00895A);
const Color _kLightEmerald = Color(0xFFEBF7F0);
const Color _kSoftMint = Color(0xFFD6F2E3);
const Color _kDarkText = Color(0xFF1E293B);
const Color _kSubText = Color(0xFF64748B);
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kBgColor = Color(0xFFF8FAFC);

/// Date formatting helper: cleans raw ISO date strings (e.g. 2026-08-31T00:00:00.000Z -> 2026.08.31)
String _formatDateStr(dynamic raw) {
  if (raw == null) return '-';
  final s = raw.toString().trim();
  if (s.isEmpty) return '-';
  final datePart = s.contains('T') ? s.split('T').first : s.split(' ').first;
  final cleaned = datePart.replaceAll('-', '.').replaceAll('/', '.');
  return cleaned;
}

class SanalAsuulgaPage extends StatefulWidget {
  const SanalAsuulgaPage({super.key});

  @override
  State<SanalAsuulgaPage> createState() => _SanalAsuulgaPageState();
}

class _SanalAsuulgaPageState extends State<SanalAsuulgaPage> {
  bool _achaalj = true;
  String? _aldaa;
  List<dynamic> _asuulguud = [];

  String? _token;
  String? _baiguullagiinId;
  String? _barilgiinId;
  String? _orshinSuugchId;

  @override
  void initState() {
    super.initState();
    _achaalya();
  }

  Future<void> _achaalya() async {
    setState(() {
      _achaalj = true;
      _aldaa = null;
    });
    try {
      _token = await StorageService.getToken();
      _baiguullagiinId = await StorageService.getBaiguullagiinId();
      _barilgiinId = await StorageService.getBarilgiinId();
      _orshinSuugchId = await StorageService.getUserId();

      if (_token == null || _baiguullagiinId == null || _orshinSuugchId == null) {
        setState(() {
          _aldaa = 'Хэрэглэгчийн мэдээлэл дутуу байна';
          _achaalj = false;
        });
        return;
      }

      final uri = Uri.parse(
        '${ApiService.baseUrl}/orshinSuugchiinSanalAsuulga',
      ).replace(
        queryParameters: {
          'baiguullagiinId': _baiguullagiinId!,
          if (_barilgiinId != null) 'barilgiinId': _barilgiinId!,
          'orshinSuugchId': _orshinSuugchId!,
        },
      );

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode != 200) {
        setState(() {
          _aldaa = 'Асуулга татахад алдаа гарлаа';
          _achaalj = false;
        });
        return;
      }

      final body = jsonDecode(res.body);
      setState(() {
        _asuulguud = (body is Map && body['data'] is List) ? body['data'] : [];
        _achaalj = false;
      });
    } catch (e) {
      setState(() {
        _aldaa = 'Алдаа гарлаа';
        _achaalj = false;
      });
    }
  }

  Future<void> _asuulgaNeeye(Map<String, dynamic> asuulga) async {
    final khariulsan = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AsuulgaKhariultPage(
          asuulga: asuulga,
          token: _token!,
          baiguullagiinId: _baiguullagiinId!,
          barilgiinId: _barilgiinId,
          orshinSuugchId: _orshinSuugchId!,
        ),
      ),
    );
    if (khariulsan == true) _achaalya();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kDarkText, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Асуулга',
          style: TextStyle(
            color: _kDarkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _kPrimaryEmerald,
        onRefresh: _achaalya,
        child: _achaalj
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimaryEmerald),
              )
            : _aldaa != null
                ? _KhoosonKharagdats(
                    icon: Icons.error_outline_rounded,
                    tekst: _aldaa!,
                    tovch: 'Дахин оролдох',
                    onTovch: _achaalya,
                  )
                : _asuulguud.isEmpty
                    ? const _KhoosonKharagdats(
                        icon: Icons.assignment_turned_in_outlined,
                        tekst: 'Одоогоор идэвхтэй асуулга байхгүй байна',
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Featured Banner
                            _buildHeroBanner(context),
                            const SizedBox(height: 24),

                            // List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Идэвхтэй асуулга',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _kDarkText,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Бүгдийг харах',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimaryEmerald,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: _kPrimaryEmerald,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Survey Cards List
                            ..._asuulguud.map((item) {
                              final a = Map<String, dynamic>.from(item as Map);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSurveyCard(context, a),
                              );
                            }),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final firstSurvey = _asuulguud.isNotEmpty
        ? Map<String, dynamic>.from(_asuulguud.first as Map)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kLightEmerald,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kSoftMint.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Асуулга',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Манай үйлчилгээний хөгжлийн төлөө',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kSubText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    if (firstSurvey != null) {
                      _asuulgaNeeye(firstSurvey);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Оролцох',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Clipboard 3D-like illustration widget
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kPrimaryEmerald.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.assignment_rounded,
                  size: 52,
                  color: _kPrimaryEmerald.withValues(alpha: 0.9),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB800),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(BuildContext context, Map<String, dynamic> a) {
    final khariulsan = a['khariulsanEsekh'] == true;
    final title = a['garchig']?.toString() ?? 'Асуулга';
    final tailbar = a['tailbar']?.toString() ?? '';
    final asuultToo = (a['asuultuud'] as List?)?.length ?? 0;
    final duusakhText = a['duusakhText']?.toString() ?? 'Идэвхтэй';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge & Expiry text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLightEmerald,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  khariulsan ? 'Хариулсан' : 'Идэвхтэй',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _kDarkEmerald,
                  ),
                ),
              ),
              Text(
                duusakhText,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
              height: 1.3,
            ),
          ),
          if (tailbar.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tailbar,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _kSubText,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Bottom Row: Question count & Action button (Participant count removed)
          Row(
            children: [
              Text(
                '$asuultToo асуулттай',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kSubText,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _asuulgaNeeye(a),
                style: ElevatedButton.styleFrom(
                  backgroundColor: khariulsan ? _kLightEmerald : _kPrimaryEmerald,
                  foregroundColor: khariulsan ? _kPrimaryEmerald : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  khariulsan ? 'Харах' : 'Оролцох',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: khariulsan ? _kPrimaryEmerald : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREEN 2 & 3: SURVEY STEPPER & COMPLETION VIEW
// ============================================================================
class _AsuulgaKhariultPage extends StatefulWidget {
  final Map<String, dynamic> asuulga;
  final String token;
  final String baiguullagiinId;
  final String? barilgiinId;
  final String orshinSuugchId;

  const _AsuulgaKhariultPage({
    required this.asuulga,
    required this.token,
    required this.baiguullagiinId,
    required this.barilgiinId,
    required this.orshinSuugchId,
  });

  @override
  State<_AsuulgaKhariultPage> createState() => _AsuulgaKhariultPageState();
}

class _AsuulgaKhariultPageState extends State<_AsuulgaKhariultPage> {
  final Map<String, Set<String>> _songogdson = {};
  final Map<String, TextEditingController> _tekstuud = {};
  bool _ilgeej = false;
  bool _isCompleted = false;

  int _currentIndex = 0;
  final DateTime _startTime = DateTime.now();
  Duration _elapsedDuration = Duration.zero;

  bool get _khariulsanEsekh => widget.asuulga['khariulsanEsekh'] == true;

  List<Map<String, dynamic>> get _asuultuud =>
      ((widget.asuulga['asuultuud'] as List?) ?? [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();

  @override
  void initState() {
    super.initState();
    _loadPreviousAnswers();
  }

  /// Pre-populate previously submitted answers for read-only view
  Future<void> _loadPreviousAnswers() async {
    List<dynamic> miniiList = (widget.asuulga['miniiKhariult'] as List?) ??
        (widget.asuulga['khariultuud'] as List?) ??
        [];

    // If miniiList is empty but survey is answered, fetch directly from backend endpoint
    if (miniiList.isEmpty && _khariulsanEsekh) {
      try {
        final uri = Uri.parse(
          '${ApiService.baseUrl}/sanalAsuulga/${widget.asuulga['_id']}/miniiKhariult',
        ).replace(queryParameters: {
          'baiguullagiinId': widget.baiguullagiinId,
          'orshinSuugchId': widget.orshinSuugchId,
        });

        final res = await http.get(
          uri,
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] is List) {
            miniiList = body['data'];
          }
        }
      } catch (_) {}
    }

    _populateAnswersFromList(miniiList);
  }

  void _populateAnswersFromList(List<dynamic> miniiList) {
    final questions = _asuultuud;
    for (int i = 0; i < miniiList.length; i++) {
      final item = miniiList[i];
      if (item is Map) {
        final qId = item['asuultiinId']?.toString() ?? '';
        final songogdsonList = (item['songogdson'] as List?)
                ?.map((s) => s.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];
        final tekstVal = item['tekst']?.toString() ?? '';

        String targetId = qId;
        if (targetId.isEmpty || !questions.any((q) => q['_id']?.toString() == targetId)) {
          if (i < questions.length) {
            targetId = questions[i]['_id']?.toString() ?? '';
          }
        }

        if (targetId.isNotEmpty) {
          if (songogdsonList.isNotEmpty) {
            _songogdson[targetId] = Set<String>.from(songogdsonList);
          }
          if (tekstVal.isNotEmpty) {
            _tekstuud[targetId] = TextEditingController(text: tekstVal);
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  bool _isOptionSelected(String qId, String option) {
    final selected = _songogdson[qId];
    if (selected == null || selected.isEmpty) return false;
    final target = option.trim().toLowerCase();
    return selected.any((s) => s.trim().toLowerCase() == target);
  }

  @override
  void dispose() {
    for (final c in _tekstuud.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _songoyo(String asuultiinId, String songolt, bool olon) {
    if (_khariulsanEsekh) return; // View-only mode: cannot edit
    setState(() {
      final odoo = _songogdson[asuultiinId] ?? <String>{};
      if (olon) {
        if (odoo.contains(songolt)) {
          odoo.remove(songolt);
        } else {
          odoo.add(songolt);
        }
        _songogdson[asuultiinId] = odoo;
      } else {
        _songogdson[asuultiinId] = {songolt};
      }
    });
  }

  bool _isCurrentQuestionValid() {
    if (_khariulsanEsekh) return true;
    if (_asuultuud.isEmpty) return true;
    final a = _asuultuud[_currentIndex];
    if (a['zaavalEsekh'] == false) return true;
    final id = a['_id'].toString();
    final songolt = _songogdson[id] ?? <String>{};
    final tekst = _tekstuud[id]?.text.trim() ?? '';
    return songolt.isNotEmpty || tekst.isNotEmpty;
  }

  Future<void> _ilgeeye() async {
    if (_khariulsanEsekh) {
      Navigator.of(context).pop(false);
      return;
    }

    if (!_isCurrentQuestionValid()) {
      final a = _asuultuud[_currentIndex];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${a['asuult']}" асуултад хариулна уу')),
      );
      return;
    }

    setState(() => _ilgeej = true);
    try {
      final res = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/sanalAsuulga/${widget.asuulga['_id']}/khariulya',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'baiguullagiinId': widget.baiguullagiinId,
          if (widget.barilgiinId != null) 'barilgiinId': widget.barilgiinId,
          'orshinSuugchId': widget.orshinSuugchId,
          'khariultuud': _asuultuud.map((a) {
            final id = a['_id'].toString();
            return {
              'asuultiinId': id,
              'songogdson': (_songogdson[id] ?? <String>{}).toList(),
              'tekst': _tekstuud[id]?.text.trim() ?? '',
            };
          }).toList(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _elapsedDuration = DateTime.now().difference(_startTime);
          _isCompleted = true;
          _ilgeej = false;
        });
        return;
      }

      String medee = 'Илгээхэд алдаа гарлаа';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          medee = body['message'].toString();
        }
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(medee)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Илгээхэд алдаа гарлаа')),
      );
    } finally {
      if (mounted && !_isCompleted) setState(() => _ilgeej = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen(context);
    }
    return _buildStepperScreen(context);
  }

  // ==========================================================================
  // SCREEN 2: SURVEY QUESTION STEPPER
  // ==========================================================================
  Widget _buildStepperScreen(BuildContext context) {
    final title = widget.asuulga['garchig']?.toString() ?? 'Асуулгын дэлгэрэнгүй';
    final tailbar = widget.asuulga['tailbar']?.toString() ?? 'Таны үнэлгээ, санал хүсэлт нь бидний үйлчилгээ, орчныг сайжруулахад чухал юм.';
    final totalQuestions = _asuultuud.length;
    final ekhOgnoo = _formatDateStr(widget.asuulga['ekhlekhOgnoo'] ?? widget.asuulga['createdAt'] ?? '2024.05.20');
    final duusOgnoo = _formatDateStr(widget.asuulga['duusakhOgnoo'] ?? '2024.05.31');

    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kDarkText, size: 20),
          onPressed: () => Navigator.of(context).maybePop(false),
        ),
        title: Text(
          _khariulsanEsekh ? 'Асуулга (Хариулсан)' : 'Асуулгын дэлгэрэнгүй',
          style: const TextStyle(
            color: _kDarkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Mint Header Card (2-column meta row, participant count removed)
                  _buildTopMintCard(
                    title: title,
                    tailbar: tailbar,
                    ekhOgnoo: ekhOgnoo,
                    duusOgnoo: duusOgnoo,
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar Section
                  if (totalQuestions > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Нийт $totalQuestions асуулт',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _kDarkText,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1}/$totalQuestions',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _kSubText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (totalQuestions > 0)
                            ? (_currentIndex + 1) / totalQuestions
                            : 0,
                        minHeight: 6,
                        backgroundColor: _kBorderColor,
                        color: _kPrimaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Read-Only Warning Banner if already answered
                  if (_khariulsanEsekh) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kLightEmerald,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kSoftMint),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18, color: _kPrimaryEmerald),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Та энэ асуулгад хариулсан байна (Зөвхөн харах)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kDarkEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current Question Card
                  if (_asuultuud.isNotEmpty && _currentIndex < totalQuestions)
                    _buildQuestionCard(context, _currentIndex),
                ],
              ),
            ),
          ),

          // Bottom Stepper Action Bar
          _buildBottomStepperBar(context, totalQuestions),
        ],
      ),
    );
  }

  Widget _buildTopMintCard({
    required String title,
    required String tailbar,
    required String ekhOgnoo,
    required String duusOgnoo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kLightEmerald,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kSoftMint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _khariulsanEsekh ? 'Хариулсан' : 'Идэвхтэй',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _kDarkEmerald,
                  ),
                ),
              ),
              const Text(
                'Дуусах огноо',
                style: TextStyle(
                  fontSize: 11,
                  color: _kSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tailbar,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSubText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 3D Clipboard Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  size: 36,
                  color: _kPrimaryEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 Column Meta Info Row (Participant count removed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaItem(Icons.calendar_today_rounded, 'Эхэлсэн огноо', ekhOgnoo),
                Container(width: 1, height: 28, color: _kBorderColor),
                _buildMetaItem(Icons.event_available_rounded, 'Дуусах огноо', duusOgnoo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _kSubText),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: _kSubText),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _kDarkText,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final a = _asuultuud[index];
    final id = a['_id'].toString();
    final questionText = a['asuult']?.toString() ?? '';
    final turul = a['turul']?.toString() ?? 'songolt';
    final olon = turul == 'olonSongolt';
    final songoltuud = ((a['songoltuud'] as List?) ?? [])
        .map((s) => s.toString())
        .toList();

    if (turul == 'tekst') {
      _tekstuud.putIfAbsent(id, () => TextEditingController());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Title with Index
          Text(
            '${index + 1}. $questionText',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Options / Input (View-only disabled if _khariulsanEsekh)
          if (turul == 'tekst')
            TextField(
              controller: _tekstuud[id],
              enabled: !_khariulsanEsekh,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _khariulsanEsekh ? 'Хариулт оруулаагүй байна' : 'Саналаа бичнэ үү...',
                hintStyle: const TextStyle(color: _kSubText, fontSize: 13),
                filled: true,
                fillColor: _kBgColor,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kPrimaryEmerald, width: 1.5),
                ),
              ),
            )
          else
            ...songoltuud.map((option) {
              final songogdson = _isOptionSelected(id, option);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _khariulsanEsekh ? null : () => _songoyo(id, option, olon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: songogdson ? _kLightEmerald : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: songogdson ? _kPrimaryEmerald : _kBorderColor,
                        width: songogdson ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio button custom dot
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: songogdson ? _kPrimaryEmerald : _kSubText.withValues(alpha: 0.6),
                              width: songogdson ? 6 : 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: songogdson ? FontWeight.bold : FontWeight.w500,
                              color: _kDarkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomStepperBar(BuildContext context, int totalQuestions) {
    final isLastQuestion = _currentIndex >= totalQuestions - 1;
    final isFirstQuestion = _currentIndex == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: OutlinedButton(
                onPressed: isFirstQuestion
                    ? null
                    : () {
                        setState(() {
                          _currentIndex--;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kDarkText,
                  disabledForegroundColor: _kSubText.withValues(alpha: 0.4),
                  side: const BorderSide(color: _kBorderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left_rounded, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Өмнөх',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Next / Submit / Close Button
            Expanded(
              child: ElevatedButton(
                onPressed: _ilgeej
                    ? null
                    : () {
                        if (_khariulsanEsekh) {
                          if (isLastQuestion) {
                            Navigator.of(context).pop(false);
                          } else {
                            setState(() {
                              _currentIndex++;
                            });
                          }
                        } else {
                          if (isLastQuestion) {
                            _ilgeeye();
                          } else {
                            if (!_isCurrentQuestionValid()) {
                              final a = _asuultuud[_currentIndex];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${a['asuult']}" асуултад хариулна уу'),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _currentIndex++;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _ilgeej
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _khariulsanEsekh
                                ? (isLastQuestion ? 'Хаах' : 'Дараах')
                                : (isLastQuestion ? 'Илгээх' : 'Дараах'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isLastQuestion) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SCREEN 3: SUCCESS / COMPLETION SCREEN
  // ==========================================================================
  Widget _buildCompletionScreen(BuildContext context) {
    final now = DateTime.now();
    final formattedDate =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final mins = _elapsedDuration.inMinutes;
    final secs = _elapsedDuration.inSeconds % 60;
    final timeStr = mins > 0 ? '$mins мин $secs сек' : '$secs сек';
    final totalQuestions = _asuultuud.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kDarkText, size: 20),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Text(
          'Асуулга',
          style: TextStyle(
            color: _kDarkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Celebration Hero Graphic
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Confetti decorative circles
                          Positioned(
                            top: 10,
                            left: 60,
                            child: _buildConfettiDot(const Color(0xFFFFB800), 10),
                          ),
                          Positioned(
                            top: 25,
                            right: 70,
                            child: _buildConfettiDot(const Color(0xFF38BDF8), 8),
                          ),
                          Positioned(
                            bottom: 15,
                            left: 75,
                            child: _buildConfettiDot(const Color(0xFFC084FC), 12),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 60,
                            child: _buildConfettiDot(const Color(0xFFF43F5E), 8),
                          ),

                          // Large Checkmark Badge
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: _kPrimaryEmerald,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3300B074),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Баярлалаа!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Та асуулгад амжилттай оролцлоо.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _kSubText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Participation Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _kBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Таны оролцоо',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _kDarkText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Оролцсон огноо',
                            value: formattedDate,
                          ),
                          const Divider(height: 24, color: _kBorderColor),
                          _buildSummaryRow(
                            icon: Icons.access_time_rounded,
                            label: 'Зарцуулсан хугацаа',
                            value: timeStr,
                          ),
                          const Divider(height: 24, color: _kBorderColor),
                          _buildSummaryRow(
                            icon: Icons.format_list_bulleted_rounded,
                            label: 'Хариулсан асуулт',
                            value: '$totalQuestions / $totalQuestions',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Soft Mint Thank You Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kLightEmerald,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kSoftMint),
                      ),
                      child: const Text(
                        'Таны санал бидний үйлчилгээг сайжруулахад үнэтэй хувь нэмэр оруулж байна.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDarkEmerald,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Full Width Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Хаах',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _kSubText),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _kSubText),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _kDarkText,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMPTY STATE WIDGET
// ============================================================================
class _KhoosonKharagdats extends StatelessWidget {
  final IconData icon;
  final String tekst;
  final String? tovch;
  final VoidCallback? onTovch;

  const _KhoosonKharagdats({
    required this.icon,
    required this.tekst,
    this.tovch,
    this.onTovch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _kLightEmerald,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: _kPrimaryEmerald),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tekst,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kSubText,
          ),
        ),
        if (tovch != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onTovch,
              child: Text(
                tovch!,
                style: const TextStyle(
                  color: _kPrimaryEmerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
