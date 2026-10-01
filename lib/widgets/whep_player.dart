import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:sukh_app/core/api/api_host.dart';

/// Камерын урсгалыг VPS дээрх MediaMTX-ээс WHEP-ээр авч тоглуулна.
///
/// ── Яагаад P2P-г орлуулав ───────────────────────────────────────────────
/// Хуучин `WebRTCPlayer` нь барилгын компьютер РҮҮ шууд холбогддог байв.
/// Хоёр тал NAT-ын ард байхад ICE бүтэхгүй (TURN тохируулаагүй), үзэгч бүр
/// камер руу тусдаа RTSP сесс нээдэг, доголдол бүрт бүхэлд нь дахин барьдаг.
///
/// Одоо нөгөө тал нь НИЙТИЙН тогтмол хаягтай сервер: ICE-ийн бүх хүлээлт
/// (STUN, relay candidate, урт таймаут) шаардлагагүй болно. Хөтөч/апп
/// зөвхөн host candidate-аар серверийн нийтийн хаяг руу шалгалт явуулахад
/// сервер эх хаягийг нь peer-reflexive болгон таньдаг.
///
/// ── Зам ─────────────────────────────────────────────────────────────────
/// `{barilgiinId}/{камерын-ip-цэгийг-зураасаар}` + суваг олдвол `-{суваг}`.
/// Rust worker-ийн `Config::stream_path`/`nemelt_zam` болон вэбийн
/// `urgasniiZam` гурвуулаа ИЖИЛ дүрмээр боддог тул шинэ API хэрэггүй.
class WhepPlayer extends StatefulWidget {
  final String rtspUrl;
  final String barilgiinId;
  /// Урсгал нь товшилтгүйгээр ШУУД эхэлнэ.
  ///
  /// Камерын дэлгэц нээгдмэгц зураг харагдах ёстой — оператор нэмэлт
  /// товшилт хийх шаардлагагүй. `false` дамжуулбал л тоглуулах товч гарна
  /// (одоогоор хаанаас ч тэгж дууддаггүй).
  final bool autoStart;
  final Duration? delay;

  /// Урсгал MediaMTX дээр БАЙХГҮЙ үед дуудагдана (HTTP 404).
  ///
  /// Барилгууд нэг дор биш, ээлжлэн шилждэг тул шилжээгүй барилгын камерыг
  /// хуучин P2P замаар үзэх боломжтой байх ёстой. `CameraPlayer` үүнийг
  /// барьж аваад хуучин плеер рүү сэлгэнэ.
  final VoidCallback? onUnavailable;

  const WhepPlayer({
    super.key,
    required this.rtspUrl,
    required this.barilgiinId,
    this.autoStart = true,
    this.delay,
    this.onUnavailable,
  });

  @override
  State<WhepPlayer> createState() => _WhepPlayerState();
}

/// `rtsp://user:pass@192.168.1.110:554/...` → `192.168.1.110`
String? rtspIpAvya(String rtspUrl) {
  // Regex-ийн оронд Rust (`config::rtsp_ip`) ба вэб-тэй ЯГ ижил
  // алгоритм. Зөрвөл апп өөр зам хүсч WHEP 404 авна.
  final s = rtspUrl.trim();
  final doorkh = s.toLowerCase();
  if (!doorkh.startsWith('rtsp://') && !doorkh.startsWith('rtsps://')) {
    return null;
  }

  final tsuv = s.split('://');
  if (tsuv.length < 2 || tsuv[1].isEmpty) return null;
  final after = tsuv[1];

  // СҮҮЛИЙН `@` — нууц үг дотор `@` байж болно.
  final at = after.lastIndexOf('@');
  final host = at >= 0 ? after.substring(at + 1) : after;

  final tues = host.indexOf(RegExp(r'[:/?#]'));
  final ip = tues < 0 ? host : host.substring(0, tues);
  return ip.isEmpty ? null : ip;
}

/// RTSP хаягаас СУВГИЙН дугаарыг салгана.
///
/// NVR бол НЭГ IP дээр олон камер: зөвхөн IP-гээр зам нэрлэвэл бүх суваг нэг
/// зам руу орж, бие биенээ түлхэнэ.
///
/// Зогсоолын ANPR камерын `root` нь `tokhirgoo.ROOT || "stream"` бөгөөд
/// сувгийн дугаар агуулдаггүй. Тиймээс «суваг олдвол л дагавар нэмэх» дүрэм
/// нь одоо ажиллаж байгаа замуудыг ХЭВЭЭР үлдээнэ.
String rtspSuvagAvya(String rtspUrl) {
  final u = rtspUrl.trim();
  final hik = RegExp(r'/Channels/(\d+)').firstMatch(u);
  if (hik != null) return hik.group(1)!;
  final q = RegExp(r'[?&]channel=(\d+)').firstMatch(u);
  if (q != null) return q.group(1)!;
  return '';
}

/// Урсгалын зам. Хоосон мөр буцвал зам бодох боломжгүй гэсэн үг.
String urgasniiZam(String barilgiinId, String rtspUrl) {
  final ip = rtspIpAvya(rtspUrl);
  if (barilgiinId.isEmpty || ip == null || ip.isEmpty) return '';
  final suvag = rtspSuvagAvya(rtspUrl);
  final ipZam = ip.replaceAll('.', '-');
  return suvag.isEmpty ? '$barilgiinId/$ipZam' : '$barilgiinId/$ipZam-$suvag';
}

class _WhepPlayerState extends State<WhepPlayer> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;

  bool _started = false;
  bool _loading = true;
  String? _error;

  /// WHEP сессийн хаяг — салахдаа DELETE явуулна.
  String? _resource;

  /// Хуучирсан оролдлогын хариу ирвэл таньж хаяхад.
  int _oroldlogo = 0;

  /// Дуудагчид нэгээс олон удаа мэдэгдэхгүй.
  bool _medegdsen = false;

  /// `dispose` дуудагдсан эсэх.
  ///
  /// `_salya()` нь async: дотроо `http.delete` болон `pc.close()`-ыг хүлээдэг.
  /// `dispose()` түүнийг хүлээхгүйгээр renderer-ээ устгадаг тул `_salya` нь
  /// АРАЙ ХОЖУУ renderer-т хүрэхэд `Can't set srcObject: The
  /// RTCVideoRenderer is disposed` гэсэн онцгой тохиолдол гардаг.
  bool _ustsan = false;

  @override
  void initState() {
    super.initState();
    _started = widget.autoStart;
    if (_started) {
      if (widget.delay != null) {
        Future.delayed(widget.delay!, () {
          if (mounted) _ekhlye();
        });
      } else {
        _ekhlye();
      }
    }
  }

  Future<void> _ekhlye() async {
    await _renderer.initialize();
    if (mounted) await _kholbogdoyo();
  }

  void _bolomjgui() {
    if (_medegdsen) return;
    _medegdsen = true;
    widget.onUnavailable?.call();
  }

  Future<void> _kholbogdoyo() async {
    final zam = urgasniiZam(widget.barilgiinId, widget.rtspUrl);
    if (zam.isEmpty) {
      // Зам бодох боломжгүй бол WHEP-ээр оролдох ч утгагүй.
      _bolomjgui();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Камерын хаягаас IP олдсонгүй';
        });
      }
      return;
    }

    final whepUrl = '${ApiHost.whep}/$zam/whep';
    final oroldlogo = ++_oroldlogo;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Сервер нийтийн тул STUN/TURN шаардлагагүй.
      final pc = await createPeerConnection(<String, dynamic>{
        'iceServers': <dynamic>[],
        'sdpSemantics': 'unified-plan',
      });
      _pc = pc;

      // Зөвхөн дүрс: нийтлэгч дууг `-an`-аар хаядаг (G.711 нь WebRTC-ээр
      // дамждаггүй) тул аудио transceiver нэмэх нь дэмий.
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      pc.onTrack = (RTCTrackEvent e) {
        if (e.track.kind == 'video' && e.streams.isNotEmpty) {
          if (mounted && !_ustsan) {
            setState(() {
              _renderer.srcObject = e.streams[0];
              _loading = false;
              _error = null;
            });
          }
        }
      };

      pc.onConnectionState = (RTCPeerConnectionState s) {
        if (!mounted || _pc != pc) return;
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          setState(() => _error = 'Холболт тасарлаа');
        }
      };

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      await _iceKhuleeye(pc);

      final local = await pc.getLocalDescription();
      if (local?.sdp == null) throw Exception('Локал SDP алга');

      final res = await http.post(
        Uri.parse(whepUrl),
        headers: {'Content-Type': 'application/sdp'},
        body: local!.sdp,
      );

      if (oroldlogo != _oroldlogo || !mounted) return;

      if (res.statusCode == 404) {
        // Тухайн зам сервер дээр байхгүй — барилга шилжээгүй байна.
        _bolomjgui();
        return;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('WHEP ${res.statusCode}');
      }

      final loc = res.headers['location'];
      if (loc != null && loc.isNotEmpty) {
        _resource = Uri.parse(whepUrl).resolve(loc).toString();
      }

      await pc.setRemoteDescription(RTCSessionDescription(res.body, 'answer'));
    } catch (e) {
      if (oroldlogo != _oroldlogo || !mounted) return;
      setState(() {
        _loading = false;
        _error = 'Камертай холбогдож чадсангүй';
      });
      debugPrint('❌ [WHEP] $whepUrl → $e');
    }
  }

  /// WHEP нь нэг удаагийн offer/answer. Host candidate агшин зуур бэлэн
  /// болдог тул энэ хүлээлт бараг мэдэгдэхгүй — ердөө хамгаалалтын тааз.
  Future<void> _iceKhuleeye(RTCPeerConnection pc) async {
    final tugsgul = DateTime.now().add(const Duration(milliseconds: 1200));
    while (DateTime.now().isBefore(tugsgul)) {
      final state = pc.iceGatheringState;
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) return;
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> _salya() async {
    _oroldlogo++;
    final res = _resource;
    _resource = null;
    if (res != null) {
      // Сесс цэвэрлэх нь «хийвэл сайн» — амжилтгүй болсон ч хэрэглэгчид
      // нөлөөлөхгүй, сервер өөрөө хугацаагаар цэвэрлэнэ.
      try {
        await http.delete(Uri.parse(res));
      } catch (_) {}
    }
    final pc = _pc;
    _pc = null;
    if (pc != null) {
      pc.onTrack = null;
      pc.onConnectionState = null;
      try {
        await pc.close();
      } catch (_) {}
    }
    if (!_ustsan) _renderer.srcObject = null;
  }

  @override
  void dispose() {
    // Дарааллыг ЗӨВ барих нь чухал: renderer-ийг эхлээд СИНХРОНООР
    // чөлөөлж, дараа нь устгана. `_salya()` нь async тул хүлээхгүй —
    // харин `_ustsan` тэмдэг нь түүнийг renderer-т хүрэхээс сэргийлнэ.
    _ustsan = true;
    _renderer.srcObject = null;
    _salya();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Container(
        color: Colors.black,
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.play_circle_outline,
                color: Colors.white70, size: 48),
            onPressed: () {
              setState(() => _started = true);
              _ekhlye();
            },
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            _renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
          if (_loading && _error == null)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off,
                      color: Colors.white38, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await _salya();
                      if (mounted) await _kholbogdoyo();
                    },
                    child: const Text('Дахин оролдох',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
