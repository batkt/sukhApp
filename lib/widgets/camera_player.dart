import 'package:flutter/material.dart';
import 'package:sukh_app/widgets/webrtc_player.dart';
import 'package:sukh_app/widgets/whep_player.dart';

/// Камерын плеерийн НЭГ оролт — шинэ (WHEP) ба хуучин (P2P) замыг
/// КАМЕР ТУС БҮРЭЭР сонгоно.
///
/// ── Яагаад камер тус бүрээр ─────────────────────────────────────────────
/// Барилгуудыг нэг дор шилжүүлэх боломжгүй: компьютер бүр дээр ffmpeg
/// суулгаж, тохиргоог шинэчилж, үйлчилгээг дахин асаах хэрэгтэй. Тиймээс
/// шилжсэн барилга шинэ замаар, шилжээгүй нь хуучин замаар ЗЭРЭГ ажиллах
/// ёстой.
///
/// ── Хэрхэн шийддэг вэ ───────────────────────────────────────────────────
/// Жагсаалт хөтлөхгүй. Эхлээд WHEP-ээр оролдоно; MediaMTX `404` буцаавал
/// (тухайн зам байхгүй = барилга шилжээгүй) тэр камерыг хуучин плеер рүү
/// шилжүүлнэ. Барилга нийтэлж эхэлмэгц дараагийн нээлт дээр өөрөө шинэ зам
/// руу орно — тохиргоонд гар хүрэхгүй.
///
/// `404` нь эцсийн хариу тул шийдвэрийг процессын хугацаанд санана: олон
/// камертай хуудсыг гүйлгэхэд дахин дахин амжилтгүй хүсэлт явуулахгүй.
/// Түр зуурын алдааг санахгүй — сервер сэргэвэл дахин оролдоно.
class CameraPlayer extends StatefulWidget {
  final String rtspUrl;
  final String barilgiinId;
  /// Урсгал нь товшилтгүйгээр ШУУД эхэлнэ.
  ///
  /// Камерын дэлгэц нээгдмэгц зураг харагдах ёстой — оператор нэмэлт
  /// товшилт хийх шаардлагагүй. `false` дамжуулбал л тоглуулах товч гарна
  /// (одоогоор хаанаас ч тэгж дууддаггүй).
  final bool autoStart;
  final Duration? delay;

  const CameraPlayer({
    super.key,
    required this.rtspUrl,
    required this.barilgiinId,
    this.autoStart = true,
    this.delay,
  });

  @override
  State<CameraPlayer> createState() => _CameraPlayerState();
}

/// Зам → «WHEP дээр байхгүй». Аппыг дахин нээхэд цэвэрлэгдэнэ.
final Set<String> _shiljeeguiZamuud = <String>{};

class _CameraPlayerState extends State<CameraPlayer> {
  late bool _khuuchnaar;
  late String _zam;

  @override
  void initState() {
    super.initState();
    _zam = urgasniiZam(widget.barilgiinId, widget.rtspUrl);
    _khuuchnaar = _zam.isEmpty || _shiljeeguiZamuud.contains(_zam);
  }

  @override
  void didUpdateWidget(CameraPlayer old) {
    super.didUpdateWidget(old);
    if (old.rtspUrl != widget.rtspUrl ||
        old.barilgiinId != widget.barilgiinId) {
      _zam = urgasniiZam(widget.barilgiinId, widget.rtspUrl);
      _khuuchnaar = _zam.isEmpty || _shiljeeguiZamuud.contains(_zam);
    }
  }

  void _bolomjgui() {
    if (_zam.isNotEmpty) _shiljeeguiZamuud.add(_zam);
    if (mounted) setState(() => _khuuchnaar = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_khuuchnaar) {
      return WebRTCPlayer(
        rtspUrl: widget.rtspUrl,
        barilgiinId: widget.barilgiinId,
        autoStart: widget.autoStart,
        delay: widget.delay,
      );
    }

    return WhepPlayer(
      rtspUrl: widget.rtspUrl,
      barilgiinId: widget.barilgiinId,
      autoStart: widget.autoStart,
      delay: widget.delay,
      onUnavailable: _bolomjgui,
    );
  }
}
