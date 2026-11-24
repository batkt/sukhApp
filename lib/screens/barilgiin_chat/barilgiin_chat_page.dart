import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:video_player/video_player.dart';

/// Оршин суугчийн групп чат: «Миний байр» (барилгын) ба «Бүх байр»
/// (байгууллагын бүх байрны нийтлэг) чат. Оршин суугчид тоотоороо харагдана.
/// Текст, зураг, видео (камераар бичих эсвэл сангаас) илгээнэ.
///
/// Backend: sukhBackv2 `routes/barilgiinChatRoute.js`
///   GET  /barilgiinChat/minii
///   GET  /barilgiinChat/:id/messejuud?umnukh=&khemjee=
///   POST /barilgiinChat/:id/file                     multipart "file" → {khavsralt}
///   POST /barilgiinChat/:id/messej                   {text, clientId, khariuId?, khavsralt?: [{ner}]}
///   POST /barilgiinChat/:id/messej/:messejId/zasakh  {text}
///   GET  /barilgiinChat/:id/media                    чатын дэлгэрэнгүй (зураг, видео)
/// `:id` нь барилгын id, эсвэл «Бүх байр»-ын хувьд `buh_<baiguullagiinId>`.
/// Бодит цаг: socket `barilgiinChat:join` {token, barilgiinId}; шинэ мессеж
/// `barilgiinChat:messej`, засвар `barilgiinChat:zasvar`.
class BarilgiinChatPage extends StatefulWidget {
  const BarilgiinChatPage({super.key});

  @override
  State<BarilgiinChatPage> createState() => _BarilgiinChatPageState();
}

const _videoMaxBytes = 100 * 1024 * 1024;
const _maxKhavsralt = 10;

String _failUrl(String zam) => '${ApiService.baseUrl}/$zam';

class _Chat {
  final String barilgiinId;
  final String baiguullagiinId;
  final String turul; // barilga | buh
  final String ner;
  final String baiguullagiinNer;
  final String miniiNer;

  _Chat.fromJson(Map<String, dynamic> j)
      : barilgiinId = j['barilgiinId']?.toString() ?? '',
        baiguullagiinId = j['baiguullagiinId']?.toString() ?? '',
        turul = j['turul']?.toString() ?? 'barilga',
        ner = j['ner']?.toString() ?? '',
        baiguullagiinNer = j['baiguullagiinNer']?.toString() ?? '',
        miniiNer = j['miniiNer']?.toString() ?? '';
}

class _Khariu {
  final String messejId;
  final String ilgeegchNer;
  final String text;
  const _Khariu(this.messejId, this.ilgeegchNer, this.text);

  static _Khariu? fromJson(dynamic j) {
    if (j is! Map || j['messejId'] == null) return null;
    return _Khariu(
      j['messejId'].toString(),
      j['ilgeegchNer']?.toString() ?? '',
      j['text']?.toString() ?? '',
    );
  }
}

/// Зураг эсвэл видео. Илгээж буй үед [localPath] (серверт хараахан очоогүй).
class _Khavsralt {
  final String turul; // zurag | video
  final String zam;
  final String? localPath;
  const _Khavsralt({required this.turul, this.zam = '', this.localPath});

  bool get video => turul == 'video';

  static List<_Khavsralt> listFromJson(dynamic j) => (j is List ? j : const [])
      .whereType<Map>()
      .map((e) => _Khavsralt(
            turul: e['turul']?.toString() ?? 'zurag',
            zam: e['zam']?.toString() ?? '',
          ))
      .where((k) => k.zam.isNotEmpty)
      .toList();
}

class _Messej {
  final String id;
  final String barilgiinId;
  final String ilgeegchId;
  final String ilgeegchTurul;
  final String ilgeegchNer;
  final String text;
  final String? clientId;
  final _Khariu? khariu;
  final List<_Khavsralt> khavsralt;
  final bool zassan;
  final DateTime ognoo;
  bool ilgeej;
  bool aldaa = false;

  _Messej({
    required this.id,
    required this.barilgiinId,
    required this.ilgeegchId,
    required this.ilgeegchTurul,
    required this.ilgeegchNer,
    required this.text,
    required this.ognoo,
    this.clientId,
    this.khariu,
    this.khavsralt = const [],
    this.zassan = false,
    this.ilgeej = false,
  });

  bool get tur => ilgeej || aldaa || id.startsWith('tmp-');

  factory _Messej.fromJson(Map<String, dynamic> j) => _Messej(
        id: j['_id']?.toString() ?? '',
        barilgiinId: j['barilgiinId']?.toString() ?? '',
        ilgeegchId: j['ilgeegchId']?.toString() ?? '',
        ilgeegchTurul: j['ilgeegchTurul']?.toString() ?? '',
        ilgeegchNer: j['ilgeegchNer']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        clientId: j['clientId']?.toString(),
        khariu: _Khariu.fromJson(j['khariu']),
        khavsralt: _Khavsralt.listFromJson(j['khavsralt']),
        zassan: j['zassanEsekh'] == true,
        ognoo: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

Future<Map<String, dynamic>> _avya(String zam, [Map<String, String>? query]) async {
  final headers = await ApiService.getAuthHeaders();
  final uri = Uri.parse('${ApiService.baseUrl}$zam').replace(queryParameters: query);
  final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
  return _khariu(res);
}

Future<Map<String, dynamic>> _ilgeeye(String zam, Map<String, dynamic> body) async {
  final headers = await ApiService.getAuthHeaders();
  final res = await http
      .post(Uri.parse('${ApiService.baseUrl}$zam'), headers: headers, body: json.encode(body))
      .timeout(const Duration(seconds: 20));
  return _khariu(res);
}

/// Нэг файл upload → серверийн файлын нэр (мессежид хавсаргахад)
Future<String> _failUpload(String chatId, String filePath) async {
  final token = await StorageService.getToken();
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiService.baseUrl}/barilgiinChat/$chatId/file'),
  );
  if (token != null) req.headers['Authorization'] = 'Bearer $token';
  req.files.add(await http.MultipartFile.fromPath('file', filePath));
  final streamed = await req.send().timeout(const Duration(minutes: 5));
  final res = await http.Response.fromStream(streamed);
  final d = _khariu(res);
  final ner = (d['khavsralt'] is Map) ? d['khavsralt']['ner']?.toString() : null;
  if (ner == null || ner.isEmpty) throw Exception('Файл илгээгдсэнгүй.');
  return ner;
}

Map<String, dynamic> _khariu(http.Response res) {
  Map<String, dynamic> d = {};
  try {
    final x = json.decode(res.body);
    if (x is Map<String, dynamic>) d = x;
  } catch (_) {}
  if (res.statusCode < 200 || res.statusCode >= 300 || d['success'] == false) {
    final msg = d['message']?.toString();
    if (res.statusCode == 413 && (msg == null || msg.isEmpty)) {
      throw Exception('Файл хэт том байна.');
    }
    throw Exception(msg != null && msg.isNotEmpty ? msg : httpStatusMessage(res.statusCode));
  }
  return d;
}

String _tsag(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _udur(DateTime d) {
  final odoo = DateTime.now();
  final zuruu = DateTime(odoo.year, odoo.month, odoo.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (zuruu == 0) return 'Өнөөдөр';
  if (zuruu == 1) return 'Өчигдөр';
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

bool _negUdur(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Хавсралтыг бүтэн дэлгэцээр нээнэ (зураг — томруулж харах, видео — тоглуулах)
void _khavsraltNeekh(BuildContext context, _Khavsralt k) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => k.video ? _VideoKhuudas(khavsralt: k) : _ZuragKhuudas(khavsralt: k),
    ),
  );
}

/* ── Хуудас: «Миний байр» / «Бүх байр» табууд ─────────────────────────── */

class _BarilgiinChatPageState extends State<BarilgiinChatPage> {
  List<_Chat> _barilguud = [];
  List<_Chat> _buhuud = [];
  String? _songosonBarilga;
  bool _loading = true;
  String? _aldaa;

  @override
  void initState() {
    super.initState();
    _tatya();
  }

  Future<void> _tatya() async {
    setState(() {
      _loading = true;
      _aldaa = null;
    });
    try {
      final d = await _avya('/barilgiinChat/minii');
      final list = (d['chatuud'] as List? ?? [])
          .whereType<Map>()
          .map((e) => _Chat.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.barilgiinId.isNotEmpty)
          .toList();
      final idevkhtei = await StorageService.getBarilgiinId();
      if (!mounted) return;
      setState(() {
        _barilguud = list.where((c) => c.turul != 'buh').toList();
        _buhuud = list.where((c) => c.turul == 'buh').toList();
        final umnukh = _songosonBarilga ?? idevkhtei;
        _songosonBarilga = _barilguud.any((c) => c.barilgiinId == umnukh)
            ? umnukh
            : (_barilguud.isNotEmpty ? _barilguud.first.barilgiinId : null);
      });
    } catch (e) {
      if (mounted) setState(() => _aldaa = friendlyError(e, fallback: 'Чат ачаалж чадсангүй.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _Chat? get _barilgaChat {
    for (final c in _barilguud) {
      if (c.barilgiinId == _songosonBarilga) return c;
    }
    return null;
  }

  /// Сонгосон байрны байгууллагын «Бүх байр» чат
  _Chat? get _buhChat {
    final b = _barilgaChat;
    for (final c in _buhuud) {
      if (b == null || c.baiguullagiinId == b.baiguullagiinId) return c;
    }
    return _buhuud.isNotEmpty ? _buhuud.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F5F2),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: context.textPrimaryColor,
          title: Text('Чат', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          actions: [
            // Идэвхтэй табын чатын дэлгэрэнгүй (илгээгдсэн зураг, видео)
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Чатын дэлгэрэнгүй',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  final chat = DefaultTabController.of(ctx).index == 0 ? _barilgaChat : _buhChat;
                  if (chat == null) return;
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => _ChatDelgerengui(chat: chat)),
                  );
                },
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: isDark ? AppColors.deepGreenAccent : AppColors.deepGreen,
            unselectedLabelColor: context.textSecondaryColor,
            indicatorColor: isDark ? AppColors.deepGreenAccent : AppColors.deepGreen,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Миний байр'), Tab(text: 'Бүх байр')],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
            : _aldaa != null
                ? _AldaaKharuulakh(text: _aldaa!, onRetry: _tatya)
                : TabBarView(
                    children: [
                      Column(
                        children: [
                          if (_barilguud.length > 1) _buildBarilgaSongokh(isDark),
                          Expanded(
                            child: _barilgaChat == null
                                ? const _Khooson(text: 'Таны хаягт холбогдсон байр олдсонгүй.')
                                : _ChatRoomView(
                                    key: ValueKey(_barilgaChat!.barilgiinId),
                                    chat: _barilgaChat!,
                                  ),
                          ),
                        ],
                      ),
                      _buhChat == null
                          ? const _Khooson(text: 'Нийтлэг чат олдсонгүй.')
                          : _ChatRoomView(
                              key: ValueKey(_buhChat!.barilgiinId),
                              chat: _buhChat!,
                            ),
                    ],
                  ),
      ),
    );
  }

  /// Олон байранд тоот эзэмшдэг бол байраа сонгоно
  Widget _buildBarilgaSongokh(bool isDark) {
    return SizedBox(
      height: 44.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        children: _barilguud.map((c) {
          final songoson = c.barilgiinId == _songosonBarilga;
          return Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: ChoiceChip(
              label: Text(c.ner.isNotEmpty ? c.ner : 'Байр'),
              selected: songoson,
              showCheckmark: false,
              selectedColor: AppColors.deepGreen,
              labelStyle: TextStyle(
                fontSize: 12.sp,
                color: songoson ? Colors.white : context.textPrimaryColor,
              ),
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              side: BorderSide.none,
              onSelected: (_) => setState(() => _songosonBarilga = c.barilgiinId),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Khooson extends StatelessWidget {
  final String text;
  const _Khooson({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, height: 1.5, color: context.textSecondaryColor),
        ),
      ),
    );
  }
}

class _AldaaKharuulakh extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const _AldaaKharuulakh({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: context.textSecondaryColor),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.deepGreen),
              child: const Text('Дахин оролдох'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Нэг чат (мессежүүд + бичих хэсэг) ─────────────────────────────────── */

class _ChatRoomView extends StatefulWidget {
  final _Chat chat;
  const _ChatRoomView({super.key, required this.chat});

  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> with AutomaticKeepAliveClientMixin {
  static const _khuudas = 30;
  static const _eventShine = 'barilgiinChat:messej';
  static const _eventZasvar = 'barilgiinChat:zasvar';

  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  /// Хуучнаас шинэ рүү эрэмбэтэй
  final List<_Messej> _messejuud = [];
  bool _loading = true;
  bool _umnukhLoading = false;
  bool _dakhiadBii = false;
  String? _aldaa;
  String? _miniiId;
  String? _token;

  /// Хариулж буй / засаж буй мессеж (аль нэг нь л идэвхтэй)
  _Messej? _khariulakh;
  _Messej? _zasakh;

  String get _chatId => widget.chat.barilgiinId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_guilgelt);
    _ekhlekh();
  }

  @override
  void dispose() {
    final s = SocketService.instance.socket;
    if (s != null) {
      s.off(_eventShine, _shineMessej);
      s.off(_eventZasvar, _zasvarIrlee);
      s.off('connect', _negdye);
      s.emit('barilgiinChat:leave', {'barilgiinId': _chatId});
    }
    _scroll.removeListener(_guilgelt);
    _scroll.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ekhlekh() async {
    _miniiId = await StorageService.getUserId();
    _token = await StorageService.getToken();
    await _socketKholbokh();
    await _tatya();
  }

  Future<void> _socketKholbokh() async {
    final svc = SocketService.instance;
    if (svc.socket == null) await svc.connect();
    final s = svc.socket;
    if (s == null || !mounted) return;
    s.off(_eventShine, _shineMessej);
    s.on(_eventShine, _shineMessej);
    s.off(_eventZasvar, _zasvarIrlee);
    s.on(_eventZasvar, _zasvarIrlee);
    // Дахин холбогдох бүрт room-доо дахин нэгдэнэ
    s.off('connect', _negdye);
    s.on('connect', _negdye);
    if (s.connected) _negdye(null);
  }

  void _negdye(dynamic _) {
    final s = SocketService.instance.socket;
    if (s == null || _token == null) return;
    s.emit('barilgiinChat:join', {'token': _token, 'barilgiinId': _chatId});
  }

  _Messej? _socketMessej(dynamic data) {
    if (data is List && data.isNotEmpty) data = data.first;
    if (data is! Map || !mounted) return null;
    final m = _Messej.fromJson(Map<String, dynamic>.from(data));
    if (m.barilgiinId != _chatId || m.id.isEmpty) return null;
    return m;
  }

  void _shineMessej(dynamic data) {
    final m = _socketMessej(data);
    if (m != null) setState(() => _nemekh(m));
  }

  void _zasvarIrlee(dynamic data) {
    final m = _socketMessej(data);
    if (m == null) return;
    final i = _messejuud.indexWhere((x) => x.id == m.id);
    if (i >= 0) setState(() => _messejuud[i] = m);
  }

  /// Давхардлыг (socket + POST хариу) clientId/_id-аар арилгана
  void _nemekh(_Messej m) {
    if (_messejuud.any((x) => x.id == m.id)) return;
    final i = m.clientId == null ? -1 : _messejuud.indexWhere((x) => x.clientId == m.clientId);
    if (i >= 0) {
      _messejuud[i] = m;
    } else {
      _messejuud.add(m);
    }
  }

  List<_Messej> _jagsaalt(Map<String, dynamic> d) => (d['messejuud'] as List? ?? [])
      .whereType<Map>()
      .map((e) => _Messej.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  Future<void> _tatya() async {
    setState(() {
      _loading = true;
      _aldaa = null;
    });
    try {
      final d = await _avya('/barilgiinChat/$_chatId/messejuud', {'khemjee': '$_khuudas'});
      if (!mounted) return;
      setState(() {
        _messejuud
          ..clear()
          ..addAll(_jagsaalt(d));
        _dakhiadBii = d['dakhiadBii'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _aldaa = friendlyError(e, fallback: 'Мессеж ачаалж чадсангүй.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// reverse ListView тул дээш гүйлгэхэд maxScrollExtent руу ойртоно
  void _guilgelt() {
    if (!_scroll.hasClients || !_dakhiadBii || _umnukhLoading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) _umnukhiigTatya();
  }

  Future<void> _umnukhiigTatya() async {
    final ekhnii = _messejuud.where((m) => !m.tur).firstOrNull;
    if (ekhnii == null) return;
    setState(() => _umnukhLoading = true);
    try {
      final d = await _avya('/barilgiinChat/$_chatId/messejuud', {
        'khemjee': '$_khuudas',
        'umnukh': ekhnii.id,
      });
      final list = _jagsaalt(d).where((m) => !_messejuud.any((x) => x.id == m.id)).toList();
      if (!mounted) return;
      setState(() {
        _messejuud.insertAll(0, list);
        _dakhiadBii = d['dakhiadBii'] == true;
      });
    } catch (_) {
      // Дараагийн гүйлгээн дээр дахин оролдоно
    } finally {
      if (mounted) setState(() => _umnukhLoading = false);
    }
  }

  /* ── Зураг / видео сонгох ── */

  void _khavsraltSongokh() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.isDarkMode ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        Widget mur(IconData icon, String text, Future<void> Function() f) => ListTile(
              leading: Icon(icon, color: AppColors.deepGreen),
              title: Text(text),
              onTap: () {
                Navigator.pop(ctx);
                f();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              mur(Icons.photo_library_rounded, 'Зураг сонгох', _zuragSongokh),
              mur(Icons.photo_camera_rounded, 'Зураг авах', () => _negFail(video: false)),
              mur(Icons.videocam_rounded, 'Видео бичих', () => _negFail(video: true)),
              mur(Icons.video_library_rounded, 'Видео сонгох',
                  () => _negFail(video: true, sangaas: true)),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _zuragSongokh() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
      if (files.isEmpty) return;
      final songoson = files.take(_maxKhavsralt).toList();
      if (files.length > _maxKhavsralt && mounted) {
        showGlassSnackBar(context,
            message: 'Нэг удаад $_maxKhavsralt хүртэл зураг илгээнэ.', icon: Icons.info_outline);
      }
      await _ilgeekh(failuud: songoson.map((f) => (f.path, false)).toList());
    } catch (e) {
      _pickerAldaa(e);
    }
  }

  Future<void> _negFail({required bool video, bool sangaas = false}) async {
    try {
      final XFile? f = video
          ? await _picker.pickVideo(
              source: sangaas ? ImageSource.gallery : ImageSource.camera,
              maxDuration: const Duration(minutes: 3),
            )
          : await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
              maxWidth: 1920,
            );
      if (f == null) return;
      if (video && await File(f.path).length() > _videoMaxBytes) {
        if (mounted) {
          showGlassSnackBar(context,
              message: 'Видео хэт том байна (100MB хүртэл).', icon: Icons.error);
        }
        return;
      }
      await _ilgeekh(failuud: [(f.path, video)]);
    } catch (e) {
      _pickerAldaa(e);
    }
  }

  void _pickerAldaa(Object e) {
    if (!mounted) return;
    final zuvshuurul = e is PlatformException &&
        (e.code.contains('denied') || e.code.contains('access'));
    showGlassSnackBar(
      context,
      message: zuvshuurul
          ? 'Камер эсвэл зургийн санд хандах зөвшөөрөл өгнө үү.'
          : 'Файл сонгож чадсангүй.',
      icon: Icons.error,
    );
  }

  /* ── Илгээх / засах / хариулах ── */

  Future<void> _tovchDarlaa() async {
    if (_zasakh != null) return _zasvarKhadgalakh();
    return _ilgeekh();
  }

  /// [failuud]: (локал зам, видео эсэх). [dakhin]: амжилтгүй болсон мессежийг дахин илгээх.
  Future<void> _ilgeekh({_Messej? dakhin, List<(String, bool)>? failuud}) async {
    // Хавсралттай бол бичсэн текстийг тайлбар болгон хамт явуулна
    final text = (dakhin?.text ?? _controller.text).trim();
    final lokal = dakhin?.khavsralt.where((k) => k.localPath != null).toList() ??
        (failuud ?? [])
            .map((f) => _Khavsralt(turul: f.$2 ? 'video' : 'zurag', localPath: f.$1))
            .toList();
    if (text.isEmpty && lokal.isEmpty) return;
    HapticFeedback.lightImpact();
    final khariu = dakhin?.khariu ??
        (_khariulakh == null
            ? null
            : _Khariu(
                _khariulakh!.id,
                _khariulakh!.ilgeegchNer,
                _khariulakh!.text.isNotEmpty
                    ? _khariulakh!.text
                    : (_khariulakh!.khavsralt.any((k) => k.video) ? '🎥 Видео' : '📷 Зураг'),
              ));
    final clientId = dakhin?.clientId ??
        'a${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';
    final tur = _Messej(
      id: 'tmp-$clientId',
      barilgiinId: _chatId,
      ilgeegchId: _miniiId ?? '',
      ilgeegchTurul: 'orshinSuugch',
      ilgeegchNer: widget.chat.miniiNer,
      text: text,
      clientId: clientId,
      khariu: khariu,
      khavsralt: lokal,
      ognoo: DateTime.now(),
      ilgeej: true,
    );
    setState(() {
      if (dakhin != null) {
        final i = _messejuud.indexOf(dakhin);
        if (i >= 0) _messejuud[i] = tur;
      } else {
        _messejuud.add(tur);
        _controller.clear();
        _khariulakh = null;
      }
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    try {
      final nernuud = <String>[];
      for (final k in lokal) {
        nernuud.add(await _failUpload(_chatId, k.localPath!));
      }
      final d = await _ilgeeye('/barilgiinChat/$_chatId/messej', {
        'text': text,
        'clientId': clientId,
        if (khariu != null) 'khariuId': khariu.messejId,
        if (nernuud.isNotEmpty) 'khavsralt': nernuud.map((n) => {'ner': n}).toList(),
      });
      final m = d['messej'];
      if (m is Map && mounted) {
        final shine = _Messej.fromJson(Map<String, dynamic>.from(m));
        setState(() {
          _messejuud.removeWhere((x) => x.id == shine.id);
          final i = _messejuud.indexWhere((x) => x.clientId == clientId);
          if (i >= 0) {
            _messejuud[i] = shine;
          } else {
            _messejuud.add(shine);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        tur.ilgeej = false;
        tur.aldaa = true;
      });
      showGlassSnackBar(
        context,
        message: friendlyError(e, fallback: 'Мессеж илгээгдсэнгүй.'),
        icon: Icons.error,
      );
    }
  }

  Future<void> _zasvarKhadgalakh() async {
    final m = _zasakh;
    final text = _controller.text.trim();
    if (m == null || (text.isEmpty && m.khavsralt.isEmpty)) return;
    if (text == m.text) {
      _boliulakh();
      return;
    }
    HapticFeedback.lightImpact();
    try {
      final d = await _ilgeeye('/barilgiinChat/$_chatId/messej/${m.id}/zasakh', {'text': text});
      final x = d['messej'];
      if (!mounted) return;
      setState(() {
        if (x is Map) {
          final shine = _Messej.fromJson(Map<String, dynamic>.from(x));
          final i = _messejuud.indexWhere((y) => y.id == shine.id);
          if (i >= 0) _messejuud[i] = shine;
        }
        _zasakh = null;
        _controller.clear();
      });
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: friendlyError(e, fallback: 'Засвар хадгалагдсангүй.'),
          icon: Icons.error,
        );
      }
    }
  }

  void _boliulakh() {
    setState(() {
      if (_zasakh != null) _controller.clear();
      _zasakh = null;
      _khariulakh = null;
    });
  }

  void _uildel(_Messej m) {
    if (m.tur) return;
    HapticFeedback.selectionClick();
    final minii = m.ilgeegchId == _miniiId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.isDarkMode ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Хариулах'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _zasakh = null;
                  _khariulakh = m;
                });
                _focus.requestFocus();
              },
            ),
            if (minii)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(m.khavsralt.isNotEmpty ? 'Тайлбар засах' : 'Засах'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _khariulakh = null;
                    _zasakh = m;
                    _controller.text = m.text;
                    _controller.selection =
                        TextSelection.collapsed(offset: _controller.text.length);
                  });
                  _focus.requestFocus();
                },
              ),
            if (m.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Хуулах'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: m.text));
                },
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  /* ── UI ── */

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDarkMode;
    return Column(
      children: [
        Expanded(child: _buildBody(isDark)),
        _buildOruulga(isDark),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading && _messejuud.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.deepGreen));
    }
    if (_aldaa != null && _messejuud.isEmpty) {
      return _AldaaKharuulakh(text: _aldaa!, onRetry: _tatya);
    }
    if (_messejuud.isEmpty) {
      return _Khooson(
        text: widget.chat.turul == 'buh'
            ? 'Одоогоор мессеж алга.\nБүх байрны хөршүүддээ анхны мессежээ бичээрэй 👋'
            : 'Одоогоор мессеж алга.\nХөршүүддээ анхны мессежээ бичээрэй 👋',
      );
    }
    final n = _messejuud.length;
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      itemCount: n + (_dakhiadBii ? 1 : 0),
      itemBuilder: (context, ri) {
        if (ri == n) {
          return Padding(
            padding: EdgeInsets.all(12.h),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepGreen),
              ),
            ),
          );
        }
        final i = n - 1 - ri;
        final m = _messejuud[i];
        final prev = i > 0 ? _messejuud[i - 1] : null;
        final udurUur = prev == null || !_negUdur(prev.ognoo, m.ognoo);
        final minii = m.ilgeegchId == _miniiId;
        final nerKharuulakh =
            !minii && (prev == null || prev.ilgeegchId != m.ilgeegchId || udurUur);
        return Column(
          children: [
            if (udurUur)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _udur(m.ognoo),
                    style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor),
                  ),
                ),
              ),
            _buildBubble(m, isDark, minii, nerKharuulakh),
          ],
        );
      },
    );
  }

  Widget _buildBubble(_Messej m, bool isDark, bool minii, bool nerKharuulakh) {
    final ajiltan = m.ilgeegchTurul == 'ajiltan';
    final ungu = minii
        ? AppColors.deepGreen
        : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white);
    final textUngu = minii ? Colors.white : context.textPrimaryColor;
    final dedUngu = minii ? Colors.white.withValues(alpha: 0.75) : context.textSecondaryColor;
    final ongo = isDark ? AppColors.deepGreenAccent : AppColors.deepGreen;
    final media = m.khavsralt.isNotEmpty;

    return Align(
      alignment: minii ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _uildel(m),
        child: Container(
          margin: EdgeInsets.only(bottom: 6.h, top: nerKharuulakh ? 4.h : 0),
          constraints: BoxConstraints(maxWidth: 0.78.sw),
          padding: media
              ? EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 6.h)
              : EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 6.h),
          decoration: BoxDecoration(
            color: ungu,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(minii ? 16.r : 4.r),
              bottomRight: Radius.circular(minii ? 4.r : 16.r),
            ),
            border: minii || !ajiltan
                ? null
                : Border.all(color: AppColors.deepGreen.withValues(alpha: 0.35)),
          ),
          // IntrinsicWidth: бөмбөлөг агуулгынхаа өргөнтэй тэнцүү (бүтэн мөр биш)
          child: IntrinsicWidth(
            child: Opacity(
              opacity: m.ilgeej ? 0.75 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nerKharuulakh)
                    Padding(
                      padding: EdgeInsets.fromLTRB(media ? 8.w : 0, media ? 4.h : 0, 0, 2.h),
                      child: Text(
                        ajiltan
                            ? '${m.ilgeegchNer.isNotEmpty ? m.ilgeegchNer : 'Ажилтан'} · СӨХ'
                            : (m.ilgeegchNer.isNotEmpty ? m.ilgeegchNer : 'Оршин суугч'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: ongo,
                        ),
                      ),
                    ),
                  if (m.khariu != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: media ? 4.w : 0),
                      child: _buildKhariuKhaircag(m.khariu!, minii, isDark),
                    ),
                  if (media) _MediaTor(khavsralt: m.khavsralt, ilgeej: m.ilgeej),
                  if (m.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          media ? 8.w : 0, media ? 6.h : 0, media ? 8.w : 0, 0),
                      child: Text(
                        m.text,
                        style: TextStyle(fontSize: 14.sp, height: 1.4, color: textUngu),
                      ),
                    ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: EdgeInsets.only(right: media ? 8.w : 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: m.aldaa
                          ? GestureDetector(
                              onTap: () => _ilgeekh(dakhin: m),
                              child: Text(
                                'Илгээгдсэнгүй · дахин оролдох',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  decoration: TextDecoration.underline,
                                  color: minii ? Colors.white : const Color(0xFFE5484D),
                                ),
                              ),
                            )
                          : Text(
                              m.ilgeej
                                  ? (media ? 'Илгээж байна... (файл)' : 'Илгээж байна...')
                                  : '${m.zassan ? 'засварласан · ' : ''}${_tsag(m.ognoo)}',
                              style: TextStyle(fontSize: 10.sp, color: dedUngu),
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
  }

  Widget _buildKhariuKhaircag(_Khariu k, bool minii, bool isDark) {
    final zuraas = minii ? Colors.white.withValues(alpha: 0.8) : AppColors.deepGreen;
    return Container(
      margin: EdgeInsets.only(bottom: 4.h, top: 2.h),
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
      decoration: BoxDecoration(
        color: minii
            ? Colors.white.withValues(alpha: 0.15)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F4F2)),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: zuraas, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            k.ilgeegchNer,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: minii ? Colors.white : AppColors.deepGreen,
            ),
          ),
          Text(
            k.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              color: minii ? Colors.white.withValues(alpha: 0.85) : context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOruulga(bool isDark) {
    final idevkhtei = _zasakh ?? _khariulakh;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (idevkhtei != null)
              Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.fromLTRB(12.w, 6.h, 4.w, 6.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: const Border(
                    left: BorderSide(color: AppColors.deepGreen, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _zasakh != null ? Icons.edit_rounded : Icons.reply_rounded,
                      size: 16.sp,
                      color: AppColors.deepGreen,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _zasakh != null ? 'Мессеж засах' : idevkhtei.ilgeegchNer,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          Text(
                            idevkhtei.text.isNotEmpty
                                ? idevkhtei.text
                                : (idevkhtei.khavsralt.any((k) => k.video)
                                    ? '🎥 Видео'
                                    : '📷 Зураг'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _boliulakh,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, size: 18.sp, color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_zasakh == null)
                  Padding(
                    padding: EdgeInsets.only(right: 6.w, bottom: 2.h),
                    child: IconButton(
                      tooltip: 'Зураг, видео',
                      onPressed: _khavsraltSongokh,
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 26.sp,
                        color: AppColors.deepGreen,
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor),
                      // Аппын ерөнхий InputDecorationTheme-ийн хүрээ, дүүргэлтийг унтраана
                      decoration: InputDecoration(
                        hintText: 'Мессеж бичих...',
                        counterText: '',
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 14.sp),
                        contentPadding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Material(
                  color: AppColors.deepGreen,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _tovchDarlaa,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(
                        _zasakh != null ? Icons.check_rounded : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Мессеж доторх зураг / видео ───────────────────────────────────────── */

class _MediaTor extends StatelessWidget {
  final List<_Khavsralt> khavsralt;
  final bool ilgeej;
  const _MediaTor({required this.khavsralt, required this.ilgeej});

  @override
  Widget build(BuildContext context) {
    final w = 0.78.sw - 8.w;
    if (khavsralt.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: min(w, 240.w),
          height: 240.w,
          child: _MediaZurag(khavsralt: khavsralt.first, ilgeej: ilgeej),
        ),
      );
    }
    final tal = (min(w, 240.w) - 4.w) / 2;
    return SizedBox(
      width: min(w, 240.w),
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.w,
        children: khavsralt
            .map((k) => ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: tal,
                    height: tal,
                    child: _MediaZurag(khavsralt: k, ilgeej: ilgeej),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Нэг хавсралтын жижиг зураг (видео бол тоглуулах тэмдэгтэй)
class _MediaZurag extends StatelessWidget {
  final _Khavsralt khavsralt;
  final bool ilgeej;
  const _MediaZurag({required this.khavsralt, this.ilgeej = false});

  @override
  Widget build(BuildContext context) {
    final k = khavsralt;
    Widget zurag;
    if (k.video) {
      zurag = Container(
        color: const Color(0xFF1B1F23),
        child: Icon(Icons.videocam_rounded, color: Colors.white38, size: 40.sp),
      );
    } else if (k.localPath != null) {
      zurag = Image.file(File(k.localPath!), fit: BoxFit.cover, cacheWidth: 600);
    } else {
      zurag = Image.network(
        _failUrl(k.zam),
        fit: BoxFit.cover,
        cacheWidth: 600,
        loadingBuilder: (c, child, p) => p == null
            ? child
            : Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepGreen),
                ),
              ),
        errorBuilder: (c, e, s) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
        ),
      );
    }
    return GestureDetector(
      onTap: ilgeej || k.localPath != null ? null : () => _khavsraltNeekh(context, k),
      child: Stack(
        fit: StackFit.expand,
        children: [
          zurag,
          if (k.video)
            Center(
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28.sp),
              ),
            ),
          if (ilgeej)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/* ── Бүтэн дэлгэц: зураг, видео ────────────────────────────────────────── */

class _ZuragKhuudas extends StatelessWidget {
  final _Khavsralt khavsralt;
  const _ZuragKhuudas({required this.khavsralt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            _failUrl(khavsralt.zam),
            fit: BoxFit.contain,
            loadingBuilder: (c, child, p) => p == null
                ? child
                : const CircularProgressIndicator(color: Colors.white),
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}

class _VideoKhuudas extends StatefulWidget {
  final _Khavsralt khavsralt;
  const _VideoKhuudas({required this.khavsralt});

  @override
  State<_VideoKhuudas> createState() => _VideoKhuudasState();
}

class _VideoKhuudasState extends State<_VideoKhuudas> {
  late final VideoPlayerController _c =
      VideoPlayerController.networkUrl(Uri.parse(_failUrl(widget.khavsralt.zam)));
  bool _aldaa = false;

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _c.play();
    }).catchError((_) {
      if (mounted) setState(() => _aldaa = true);
    });
    _c.addListener(_shinechlekh);
  }

  void _shinechlekh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_shinechlekh);
    _c.dispose();
    super.dispose();
  }

  String _khugatsaa(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _aldaa
          ? const Center(
              child: Text('Видео тоглуулж чадсангүй.', style: TextStyle(color: Colors.white70)),
            )
          : !v.isInitialized
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => v.isPlaying ? _c.pause() : _c.play(),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: v.aspectRatio,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_c),
                                  if (!v.isPlaying)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded,
                                          color: Colors.white, size: 40),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        child: Row(
                          children: [
                            Text(_khugatsaa(v.position),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: VideoProgressIndicator(
                                _c,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.deepGreenAccent,
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(_khugatsaa(v.duration),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/* ── Чатын дэлгэрэнгүй: илгээгдсэн зураг, видео ────────────────────────── */

class _ChatDelgerengui extends StatefulWidget {
  final _Chat chat;
  const _ChatDelgerengui({required this.chat});

  @override
  State<_ChatDelgerengui> createState() => _ChatDelgerenguiState();
}

class _ChatDelgerenguiState extends State<_ChatDelgerengui> with SingleTickerProviderStateMixin {
  final List<_Khavsralt> _media = [];
  String? _umnukh;
  bool _dakhiadBii = false;
  bool _loading = true;
  String? _aldaa;
  final _scroll = ScrollController();
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_dakhiadBii &&
          !_loading &&
          _scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _tatya();
      }
    });
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
    _tatya();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _tatya() async {
    setState(() {
      _loading = true;
      _aldaa = null;
    });
    try {
      final d = await _avya('/barilgiinChat/${widget.chat.barilgiinId}/media', {
        'khemjee': '30',
        if (_umnukh != null) 'umnukh': _umnukh!,
      });
      if (!mounted) return;
      setState(() {
        _media.addAll(_Khavsralt.listFromJson(d['media']));
        _umnukh = d['umnukh']?.toString();
        _dakhiadBii = d['dakhiadBii'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _aldaa = friendlyError(e, fallback: 'Ачаалж чадсангүй.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final videoTab = _tab.index == 1;
    final list = _media.where((k) => k.video == videoTab).toList();
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: context.textPrimaryColor,
        title: Text('Чатын дэлгэрэнгүй',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF1A7A5E), AppColors.deepGreen]),
                  ),
                  child: Icon(
                    widget.chat.turul == 'buh' ? Icons.groups_rounded : Icons.apartment_rounded,
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
                        widget.chat.ner.isNotEmpty ? widget.chat.ner : 'Чат',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (widget.chat.baiguullagiinNer.isNotEmpty)
                        Text(
                          widget.chat.baiguullagiinNer,
                          style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            labelColor: isDark ? AppColors.deepGreenAccent : AppColors.deepGreen,
            unselectedLabelColor: context.textSecondaryColor,
            indicatorColor: isDark ? AppColors.deepGreenAccent : AppColors.deepGreen,
            tabs: const [Tab(text: 'Зураг'), Tab(text: 'Видео')],
          ),
          Expanded(
            child: _aldaa != null && _media.isEmpty
                ? _AldaaKharuulakh(text: _aldaa!, onRetry: _tatya)
                : list.isEmpty
                    ? (_loading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.deepGreen))
                        : _Khooson(
                            text: videoTab
                                ? 'Илгээсэн видео алга.'
                                : 'Илгээсэн зураг алга.',
                          ))
                    : GridView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.all(2.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2.w,
                          crossAxisSpacing: 2.w,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _MediaZurag(khavsralt: list[i]),
                      ),
          ),
        ],
      ),
    );
  }
}
