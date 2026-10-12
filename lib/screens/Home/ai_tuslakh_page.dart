import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/Home/support_chat_page.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

/// Вэбийн «AI туслах»-тай ижил backend (`POST /aiTuslakh`), оршин суугчийн
/// горимоор (`mode: "orshinSuugch"`). Хариу text/plain-ээр stream ирнэ.
class AiTuslakhPage extends StatefulWidget {
  const AiTuslakhPage({super.key});

  @override
  State<AiTuslakhPage> createState() => _AiTuslakhPageState();
}

class _Messej {
  final String role; // user | assistant
  String content;
  bool aldaa = false;

  /// Backend-ийн `X-Ai-Log-Id` — үнэлгээ илгээхэд хэрэглэнэ.
  String? logId;

  /// Хэрэглэгчийн үнэлгээ: 1 = 👍, -1 = 👎, null = үнэлээгүй.
  int? unelgee;
  _Messej(this.role, this.content);
}

class _AiTuslakhPageState extends State<AiTuslakhPage> {
  /// Апп нээлттэй байх хугацаанд яриа хадгалагдана (вэбийн sessionStorage-тэй адил)
  static final List<_Messej> _tuukh = [];

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  http.Client? _client;
  StreamSubscription<String>? _sub;
  bool _khuleej = false;

  /// 👎 дарсны дараах «Юу буруу байсан бэ?» оруулга аль мессеж дээр нээлттэй вэ
  _Messej? _tailbarMessej;
  final _tailbarController = TextEditingController();

  static const _sanaluud = [
    'Төлбөрөө яаж төлөх вэ?',
    'И-баримтаа хаанаас авах вэ?',
    'Зочны машин яаж урих вэ?',
    'Санал хүсэлт яаж илгээх вэ?',
    'Нууц кодоо мартсан бол яах вэ?',
  ];

  @override
  void dispose() {
    _sub?.cancel();
    _client?.close();
    _controller.dispose();
    _tailbarController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _dooshGuilgekh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ilgeekh([String? tekst]) async {
    final asuult = (tekst ?? _controller.text).trim();
    if (asuult.isEmpty || _khuleej) return;
    HapticFeedback.lightImpact();
    _controller.clear();

    final tuukhiinMessej = _tuukh
        .where((m) => !m.aldaa && m.content.trim().isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    final khariu = _Messej('assistant', '');
    setState(() {
      _tuukh.add(_Messej('user', asuult));
      _tuukh.add(khariu);
      _khuleej = true;
      _tailbarMessej = null;
    });
    _dooshGuilgekh();

    try {
      final token = await StorageService.getToken();
      final barilgiinId = await StorageService.getBarilgiinId();
      final req = http.Request('POST', Uri.parse('${ApiService.baseUrl}/aiTuslakh'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        })
        ..body = json.encode({
          'messages': [
            ...tuukhiinMessej.length > 12
                ? tuukhiinMessej.sublist(tuukhiinMessej.length - 12)
                : tuukhiinMessej,
            {'role': 'user', 'content': asuult},
          ],
          'mode': 'orshinSuugch',
          'khuudasniiNer': 'Амархоум апп',
          if (barilgiinId != null && barilgiinId.isNotEmpty) 'barilgiinId': barilgiinId,
        });

      _client = http.Client();
      final res = await _client!.send(req).timeout(const Duration(seconds: 60));
      // http багц header нэрийг жижиг үсгээр өгнө.
      final logId = res.headers['x-ai-log-id'];
      if (logId != null && logId.isNotEmpty) khariu.logId = logId;

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final body = await res.stream.bytesToString();
        String msg = httpStatusMessage(res.statusCode);
        try {
          final d = json.decode(body);
          msg = [d['message'], d['aldaa']]
              .where((x) => x != null && x.toString().isNotEmpty)
              .join('\n');
          if (msg.isEmpty) msg = httpStatusMessage(res.statusCode);
        } catch (_) {}
        throw Exception(msg);
      }

      final duussan = Completer<void>();
      _sub = res.stream.transform(utf8.decoder).listen(
        (chunk) {
          if (!mounted) return;
          setState(() => khariu.content += chunk);
          _dooshGuilgekh();
        },
        onError: (e) {
          if (!duussan.isCompleted) duussan.completeError(e);
        },
        onDone: () {
          if (!duussan.isCompleted) duussan.complete();
        },
        cancelOnError: true,
      );
      await duussan.future;

      if (khariu.content.trim().isEmpty) {
        throw Exception('AI туслах хариу өгсөнгүй. Дахин оролдоно уу.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          khariu.aldaa = true;
          khariu.content = khariu.content.trim().isNotEmpty
              ? '${khariu.content}\n\n(Хариу тасалдлаа. Дахин оролдоно уу.)'
              : friendlyError(e, fallback: 'AI туслахтай холбогдож чадсангүй. Дахин оролдоно уу.');
        });
      }
    } finally {
      _sub = null;
      _client?.close();
      _client = null;
      if (mounted) setState(() => _khuleej = false);
      _dooshGuilgekh();
    }
  }

  void _zogsookh() {
    _sub?.cancel();
    _client?.close();
    _client = null;
    setState(() => _khuleej = false);
  }

  void _tseverlekh() {
    if (_khuleej) _zogsookh();
    setState(() {
      _tuukh.clear();
      _tailbarMessej = null;
    });
  }

  Future<void> _unelgeeIlgeekh(String logId, int unelgee, [String? tailbar]) async {
    final token = await StorageService.getToken();
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/aiTuslakhUnelgee'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'logId': logId,
            'unelgee': unelgee,
            if (tailbar != null && tailbar.isNotEmpty) 'tailbar': tailbar,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(httpStatusMessage(res.statusCode));
    }
  }

  Future<void> _unelgeeSoligh(_Messej m, int utga) async {
    final logId = m.logId;
    if (logId == null) return;
    HapticFeedback.selectionClick();
    final umnukh = m.unelgee;
    final shine = umnukh == utga ? 0 : utga;
    setState(() {
      m.unelgee = shine == 0 ? null : shine;
      if (shine == -1) {
        _tailbarMessej = m;
        _tailbarController.clear();
      } else if (identical(_tailbarMessej, m)) {
        _tailbarMessej = null;
      }
    });
    try {
      await _unelgeeIlgeekh(logId, shine);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        m.unelgee = umnukh;
        if (identical(_tailbarMessej, m)) _tailbarMessej = null;
      });
      showGlassSnackBar(context, message: 'Үнэлгээ илгээж чадсангүй.', icon: Icons.error);
    }
  }

  Future<void> _tailbarIlgeekh() async {
    final m = _tailbarMessej;
    var tekst = _tailbarController.text.trim();
    if (tekst.length > 500) tekst = tekst.substring(0, 500);
    setState(() => _tailbarMessej = null);
    _tailbarController.clear();
    FocusScope.of(context).unfocus();
    if (m == null || m.logId == null || m.unelgee != -1 || tekst.isEmpty) return;
    try {
      await _unelgeeIlgeekh(m.logId!, -1, tekst);
      if (mounted) showGlassSnackBar(context, message: 'Баярлалаа!', icon: Icons.check_circle);
    } catch (_) {
      if (mounted) {
        showGlassSnackBar(context, message: 'Тайлбар илгээж чадсангүй.', icon: Icons.error);
      }
    }
  }

  void _operator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupportChatPage(extra: {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: context.textPrimaryColor,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1A7A5E), AppColors.deepGreen],
                ),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI туслах',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Аппын талаар юу ч асуугаарай',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Оператортой холбогдох',
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: _operator,
          ),
          if (_tuukh.isNotEmpty)
            IconButton(
              tooltip: 'Яриаг цэвэрлэх',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _tseverlekh,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _tuukh.isEmpty
                ? _buildMendchilgee(isDark)
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    itemCount: _tuukh.length,
                    itemBuilder: (context, i) => _buildMessej(_tuukh[i], isDark),
                  ),
          ),
          _buildOruulga(isDark),
        ],
      ),
    );
  }

  Widget _buildMendchilgee(bool isDark) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
      children: [
        Text(
          'Сайн байна уу! 👋',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Төлбөр төлөх, зочин урих, санал хүсэлт илгээх зэрэг аппын бүх зүйлийг тайлбарлаж өгнө. Жишээ нь:',
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.45,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        ..._sanaluud.map(
          (s) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Material(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () => _ilgeekh(s),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 16.sp,
                        color: context.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton.icon(
          onPressed: _operator,
          icon: const Icon(Icons.support_agent_rounded, size: 18),
          label: const Text('Оператортой шууд чатлах'),
          style: TextButton.styleFrom(foregroundColor: AppColors.deepGreen),
        ),
      ],
    );
  }

  Widget _buildMessej(_Messej m, bool isDark) {
    final user = m.role == 'user';
    final khoosonKhariu = !user && m.content.isEmpty && _khuleej;
    final unelgeeKharuulakh = !user &&
        m.logId != null &&
        !m.aldaa &&
        m.content.trim().isNotEmpty &&
        !(_khuleej && identical(m, _tuukh.last));
    final bubble = _buildBubble(m, isDark, user, khoosonKhariu,
        bottomMargin: unelgeeKharuulakh ? 2.h : 10.h);
    if (!unelgeeKharuulakh) return bubble;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bubble,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unelgeeTovch(m, 1, isDark),
                _unelgeeTovch(m, -1, isDark),
              ],
            ),
            if (identical(_tailbarMessej, m) && m.unelgee == -1) _buildTailbar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _unelgeeTovch(_Messej m, int utga, bool isDark) {
    final songoson = m.unelgee == utga;
    final idevkhtei = utga == 1 ? AppColors.deepGreen : const Color(0xFFE5484D);
    return IconButton(
      onPressed: () => _unelgeeSoligh(m, utga),
      tooltip: utga == 1 ? 'Тус болсон' : 'Тус болоогүй',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.all(6.w),
      constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
      icon: Icon(
        utga == 1
            ? (songoson ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined)
            : (songoson ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined),
        size: 16.sp,
        color: songoson ? idevkhtei : context.textSecondaryColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildTailbar(bool isDark) {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.82.sw),
      padding: EdgeInsets.only(left: 12.w, right: 4.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tailbarController,
              autofocus: true,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _tailbarIlgeekh(),
              style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Юу буруу байсан бэ? (заавал биш)',
                counterText: '',
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          IconButton(
            onPressed: _tailbarIlgeekh,
            tooltip: 'Илгээх',
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
            icon: Icon(Icons.send_rounded, size: 18.sp, color: AppColors.deepGreen),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() => _tailbarMessej = null);
            },
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size(0, 32.w),
              textStyle: TextStyle(fontSize: 12.sp),
            ),
            child: const Text('Алгасах'),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Messej m, bool isDark, bool user, bool khoosonKhariu,
      {required double bottomMargin}) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomMargin),
        constraints: BoxConstraints(maxWidth: 0.82.sw),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: user
              ? AppColors.deepGreen
              : m.aldaa
                  ? const Color(0xFFE5484D).withOpacity(isDark ? 0.18 : 0.08)
                  : (isDark ? Colors.white.withOpacity(0.07) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(user ? 18.r : 6.r),
            bottomRight: Radius.circular(user ? 6.r : 18.r),
          ),
        ),
        child: khoosonKhariu
            ? const _BichijBaina()
            : user
                ? Text(
                    m.content,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.4),
                  )
                : _MarkdownLite(
                    text: m.content,
                    color: m.aldaa ? const Color(0xFFE5484D) : context.textPrimaryColor,
                  ),
      ),
    );
  }

  Widget _buildOruulga(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _ilgeekh(),
                      style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor),
                      // Аппын ерөнхий InputDecorationTheme дүүргэлт, хүрээ нэмж
                      // «хайрцаг дотор хайрцаг» болгодог байв — бүгдийг унтраана.
                      decoration: InputDecoration(
                        hintText: 'Асуултаа бичнэ үү...',
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
                    onTap: _khuleej ? _zogsookh : () => _ilgeekh(),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(
                        _khuleej ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'AI алдаа гаргаж болно. Чухал зүйлийг шалгаарай.',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(fontSize: 10.5.sp, color: context.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Хариу хүлээж байх үеийн гурван цэг
class _BichijBaina extends StatefulWidget {
  const _BichijBaina();

  @override
  State<_BichijBaina> createState() => _BichijBainaState();
}

class _BichijBainaState extends State<_BichijBaina>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
          final o = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
            width: 7.w,
            height: 7.w,
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withOpacity(o),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

/// Вэбийнхтэй ижил хөнгөн markdown: **тод**, жагсаалт (1. / - / •), # гарчиг.
class _MarkdownLite extends StatelessWidget {
  final String text;
  final Color color;
  const _MarkdownLite({required this.text, required this.color});

  List<TextSpan> _todruulga(String line, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var i = 0;
    for (final m in re.allMatches(line)) {
      if (m.start > i) spans.add(TextSpan(text: line.substring(i, m.start), style: base));
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(fontWeight: FontWeight.w600),
      ));
      i = m.end;
    }
    if (i < line.length) spans.add(TextSpan(text: line.substring(i), style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: color, fontSize: 14.sp, height: 1.45);
    final widgets = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 6.h));
        continue;
      }
      final heading = RegExp(r'^#{1,6}\s+(.*)').firstMatch(line);
      final numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)').firstMatch(line);
      final bullet = RegExp(r'^\s*[-•*]\s+(.*)').firstMatch(line);
      if (heading != null) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 2.h, bottom: 2.h),
          child: Text.rich(TextSpan(
            children: _todruulga(heading.group(1)!, base.copyWith(fontWeight: FontWeight.w600)),
          )),
        ));
      } else if (numbered != null || bullet != null) {
        final tag = numbered != null ? '${numbered.group(1)}.' : '•';
        final body = numbered != null ? numbered.group(2)! : bullet!.group(1)!;
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20.w,
                child: Text(tag, style: base.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Text.rich(TextSpan(children: _todruulga(body, base)))),
            ],
          ),
        ));
      } else {
        widgets.add(Text.rich(TextSpan(children: _todruulga(line, base))));
      }
    }
    return SelectionArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
    );
  }
}
