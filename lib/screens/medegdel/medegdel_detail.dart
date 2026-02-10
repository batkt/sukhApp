import 'dart:io' show File, Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

/// Normalize zurag/duu path: backend may store "public/medegdel/baiguullagiinId/file" or "baiguullagiinId/file".
/// URL must be /medegdel/baiguullagiinId/file.
String _normalizeMedegdelPath(String? p) {
  if (p == null || p.isEmpty) return '';
  final n = p.replaceFirst(RegExp(r'^public/medegdel/?'), '').replaceFirst(RegExp(r'^public/?'), '');
  return n.isEmpty ? p : n;
}

class MedegdelDetailModal extends StatefulWidget {
  final Medegdel notification;

  const MedegdelDetailModal({super.key, required this.notification});

  @override
  State<MedegdelDetailModal> createState() => _MedegdelDetailModalState();
}

class _MedegdelDetailModalState extends State<MedegdelDetailModal> {
  late Medegdel _notification;
  bool _isMarkingAsRead = false;
  List<Medegdel> _threadItems = [];
  bool _threadLoading = false;
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;
  void Function(Map<String, dynamic>)? _socketCallback;
  XFile? _replyImage;
  String? _replyVoicePath;
  bool _recording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _voicePlayer;
  String? _playingVoiceMessageId;

  @override
  void initState() {
    super.initState();
    _voicePlayer = AudioPlayer();
    _voicePlayer!.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoiceMessageId = null);
    });
    _notification = widget.notification;
    _markAsReadAutomatically();
    _loadThread();
    final rootId = (_notification.parentId ?? _notification.id).toString().trim();
    _socketCallback = (data) {
      if (!mounted) return;
      final payloadParentId = (data['parentId']?.toString() ?? '').trim();
      final turul = (data['turul'] ?? '').toString().toLowerCase();
      final isAdminReply = turul == 'khariu' || turul == 'хариу' || turul == 'hariu';
      if (payloadParentId.isEmpty || rootId.isEmpty) return;
      if (payloadParentId != rootId || !isAdminReply) return;
      Medegdel? msg;
      try {
        msg = Medegdel.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        try {
          final j = Map<String, dynamic>.from(data);
          msg = Medegdel(
            id: j['_id']?.toString() ?? '',
            parentId: j['parentId']?.toString(),
            baiguullagiinId: j['baiguullagiinId']?.toString() ?? '',
            barilgiinId: j['barilgiinId']?.toString(),
            ognoo: j['ognoo']?.toString() ?? j['createdAt']?.toString() ?? '',
            title: j['title']?.toString() ?? '',
            gereeniiDugaar: j['gereeniiDugaar']?.toString(),
            message: j['message']?.toString() ?? '',
            orshinSuugchGereeniiDugaar: j['orshinSuugchGereeniiDugaar']?.toString(),
            orshinSuugchId: j['orshinSuugchId']?.toString(),
            orshinSuugchNer: j['orshinSuugchNer']?.toString(),
            orshinSuugchUtas: j['orshinSuugchUtas']?.toString(),
            kharsanEsekh: j['kharsanEsekh'] == true,
            turul: j['turul']?.toString() ?? 'khariu',
            createdAt: j['createdAt']?.toString() ?? '',
            updatedAt: j['updatedAt']?.toString() ?? '',
            status: j['status']?.toString(),
            tailbar: j['tailbar']?.toString(),
            repliedAt: j['repliedAt']?.toString(),
            zurag: j['zurag']?.toString(),
            duu: j['duu']?.toString(),
          );
        } catch (_) {
          return;
        }
      }
      if (msg == null || !mounted) return;
      final messageId = msg.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (_threadItems.any((m) => m.id == messageId)) return;
          _threadItems = [..._threadItems, msg!];
        });
      });
    };
    SocketService.instance.setNotificationCallback(_socketCallback!);
  }

  @override
  void dispose() {
    _voicePlayer?.dispose();
    _voicePlayer = null;
    if (_socketCallback != null) {
      SocketService.instance.removeNotificationCallback(_socketCallback);
    }
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _playOrPauseVoice(String messageId, String url) async {
    if (!mounted) return;
    final fullUrl = '${ApiService.baseUrl}/medegdel/${_normalizeMedegdelPath(url)}';
    // iOS AVPlayer does not support WebM; stay on page and show message (no external link)
    if (Platform.isIOS && url.toLowerCase().contains('.webm')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Энэ дууны формат (WebM) төхөөрөмж дээр тоглуулагдахгүй. M4A/MP3 илгээнэ үү.')),
        );
      }
      return;
    }
    if (_voicePlayer == null || !mounted) return;
    final isThisPlaying = _playingVoiceMessageId == messageId;
    try {
      if (isThisPlaying) {
        final state = _voicePlayer!.state;
        if (state == PlayerState.playing) {
          await _voicePlayer!.pause();
        } else {
          await _voicePlayer!.resume();
        }
        if (mounted) setState(() {});
      } else {
        await _voicePlayer!.stop();
        await _voicePlayer!.setSource(UrlSource(fullUrl));
        await _voicePlayer!.resume();
        if (mounted) setState(() => _playingVoiceMessageId = messageId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _playingVoiceMessageId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Дуу тоглуулахад алдаа: $e')));
      }
    }
  }

  Future<void> _loadThread() async {
    final rootId = _notification.parentId ?? _notification.id;
    if (rootId.isEmpty) return;
    setState(() => _threadLoading = true);
    try {
      final res = await ApiService.getMedegdelThread(rootId);
      if (!mounted) return;
      final list = (res['data'] as List?)
          ?.map((e) => Medegdel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [];
      setState(() {
        _threadItems = list;
        _threadLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _threadLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null || !mounted) {
        if (x == null) print('[medegdel] _pickImage: user cancelled or no image');
        return;
      }
      if (mounted) setState(() => _replyImage = x);
      print('[medegdel] _pickImage: ok name=${x.name}');
    } catch (e, st) {
      print('[medegdel] _pickImage error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Зураг сонгоход алдаа: $e')));
    }
  }

  Future<void> _startRecord() async {
    if (_recording) return;
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дуу бичих эрх олгоно уу.')));
        return;
      }
      final isRecording = await _audioRecorder.isRecording();
      if (isRecording) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e, st) {
      print('[medegdel] _startRecord error: $e\n$st');
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Дуу бичих эхлэхэд алдаа: $e')));
      }
    }
  }

  Future<void> _stopRecord() async {
    if (!_recording) return;
    try {
      final isRecording = await _audioRecorder.isRecording();
      if (!isRecording) {
        if (mounted) setState(() => _recording = false);
        return;
      }
      final path = await _audioRecorder.stop();
      if (mounted) setState(() { _recording = false; if (path != null) _replyVoicePath = path; });
    } catch (e, st) {
      print('[medegdel] _stopRecord error: $e\n$st');
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    final hasText = text.isNotEmpty;
    final hasImage = _replyImage != null;
    final hasVoice = _replyVoicePath != null;
    if ((!hasText && !hasImage && !hasVoice) || _sendingReply) return;
    final rootId = _notification.parentId ?? _notification.id;
    print('[medegdel] _sendReply start rootId=$rootId hasText=$hasText hasImage=$hasImage hasVoice=$hasVoice');
    setState(() => _sendingReply = true);
    try {
      String? zuragPath;
      String? voicePath;
      if (_replyImage != null) {
        final bytes = await _replyImage!.readAsBytes();
        final name = _replyImage!.name;
        zuragPath = await ApiService.uploadMedegdelChatFileWithBytes(bytes, name.isEmpty ? 'image.jpg' : name);
        print('[medegdel] _sendReply upload ok zuragPath=$zuragPath');
        if (mounted) setState(() => _replyImage = null);
      }
      if (_replyVoicePath != null) {
        voicePath = await ApiService.uploadMedegdelChatFile(file: File(_replyVoicePath!));
        if (mounted) setState(() => _replyVoicePath = null);
      }
      print('[medegdel] _sendReply sending reply zurag=$zuragPath voice=$voicePath');
      final res = await ApiService.sendMedegdelReply(
        rootMedegdelId: rootId,
        message: text,
        zurag: zuragPath,
        voiceUrl: voicePath,
      );
      _replyController.clear();
      final data = res['data'];
      if (mounted && data is Map) {
        try {
          final newMsg = Medegdel.fromJson(Map<String, dynamic>.from(data));
          setState(() => _threadItems = [..._threadItems, newMsg]);
        } catch (_) {}
      }
      if (mounted) Future.delayed(const Duration(milliseconds: 500), () => _loadThread());
      print('[medegdel] _sendReply done');
    } catch (e, st) {
      print('[medegdel] _sendReply error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Илгээхэд алдаа: ${e is Exception ? e.toString() : e}')),
        );
      }
    }
    if (mounted) setState(() => _sendingReply = false);
  }

  Future<void> _markAsReadAutomatically() async {
    if (_notification.kharsanEsekh) {
      return;
    }

    final turul = _notification.turul.toLowerCase();
    final isMedegdel = turul == 'app';

    if (!isMedegdel) {
      return;
    }

    if (_isMarkingAsRead) {
      return;
    }

    setState(() {
      _isMarkingAsRead = true;
    });

    try {
      await ApiService.markMedegdelAsRead(_notification.id);
      if (mounted) {
        setState(() {
          _notification = Medegdel(
            id: _notification.id,
            parentId: _notification.parentId,
            baiguullagiinId: _notification.baiguullagiinId,
            barilgiinId: _notification.barilgiinId,
            ognoo: _notification.ognoo,
            title: _notification.title,
            gereeniiDugaar: _notification.gereeniiDugaar,
            message: _notification.message,
            orshinSuugchGereeniiDugaar:
                _notification.orshinSuugchGereeniiDugaar,
            orshinSuugchId: _notification.orshinSuugchId,
            orshinSuugchNer: _notification.orshinSuugchNer,
            orshinSuugchUtas: _notification.orshinSuugchUtas,
            kharsanEsekh: true,
            turul: _notification.turul,
            createdAt: _notification.createdAt,
            updatedAt: _notification.updatedAt,
            status: _notification.status,
            tailbar: _notification.tailbar,
            repliedAt: _notification.repliedAt,
          );
          _isMarkingAsRead = false;
        });
        // Backend marks root + all replies; refetch thread so "seen" shows on messages
        _loadThread();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMarkingAsRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGomdol = _notification.turul.toLowerCase() == 'gomdol';
    final isSanal = _notification.turul.toLowerCase() == 'sanal';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.responsiveBorderRadius(
            small: 18,
            medium: 19,
            large: 20,
            tablet: 24,
            veryNarrow: 16,
          )),
          topRight: Radius.circular(context.responsiveBorderRadius(
            small: 18,
            medium: 19,
            large: 20,
            tablet: 24,
            veryNarrow: 16,
          )),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            )),
            width: context.responsiveSpacing(
              small: 36,
              medium: 38,
              large: 40,
              tablet: 44,
              veryNarrow: 32,
            ),
            height: context.responsiveSpacing(
              small: 4,
              medium: 4,
              large: 5,
              tablet: 6,
              veryNarrow: 3,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 2,
                medium: 2,
                large: 3,
                tablet: 4,
                veryNarrow: 2,
              )),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.responsiveSpacing(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 18,
              veryNarrow: 12,
            )),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isGomdol
                        ? 'Гомдол'
                        : isSanal
                        ? 'Санал'
                        : 'Мэдэгдэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 12,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.textSecondaryColor,
                    size: context.responsiveFontSize(
                      small: 20,
                      medium: 22,
                      large: 24,
                      tablet: 26,
                      veryNarrow: 18,
                    ),
                  ),
                  onPressed: () {
                    final turul = _notification.turul.toLowerCase();
                    final isMedegdel = turul == 'app';
                    final wasMarkedAsRead =
                        _notification.kharsanEsekh && isMedegdel;
                    Navigator.pop(context, wasMarkedAsRead);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildContent(isGomdol, isSanal)),
                _buildReplyBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayTurul(String turul) {
    final turulLower = turul.toLowerCase();
    if (turulLower == 'gomdol') return 'Гомдол';
    if (turulLower == 'sanal') return 'Санал';
    if (turulLower == 'khariu' ||
        turulLower == 'hariu' ||
        turulLower == 'хариу')
      return 'Хариу';
    if (turulLower == 'app') return 'Мэдэгдэл';
    return turul; // Return original if not recognized
  }

  String _getStatusText(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    if (status == 'done') {
      return 'Шийдэгдсэн';
    }
    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан') {
      return 'Татгалзсан';
    }
    if (notification.hasReply) {
      return 'Хариу өгсөн';
    }
    return 'Хүлээгдэж байна';
  }

  bool _isStatusDone(Medegdel notification) {
    return notification.status?.toLowerCase() == 'done';
  }

  bool _isStatusRejected(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    return status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан';
  }

  Widget _buildContent(bool isGomdol, bool isSanal) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(
          small: 14,
          medium: 15,
          large: 16,
          tablet: 18,
          veryNarrow: 12,
        ),
        vertical: context.responsiveSpacing(
          small: 6,
          medium: 7,
          large: 8,
          tablet: 10,
          veryNarrow: 4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and status badges
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            )),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 10,
                medium: 11,
                large: 12,
                tablet: 14,
                veryNarrow: 8,
              )),
              border: Border.all(
                color: _isStatusDone(_notification)
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.deepGreen.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsiveSpacing(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    ),
                    vertical: context.responsiveSpacing(
                      small: 5,
                      medium: 6,
                      large: 7,
                      tablet: 8,
                      veryNarrow: 4,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: isGomdol
                        ? Colors.orange.withOpacity(0.12)
                        : isSanal
                        ? AppColors.deepGreen.withOpacity(0.12)
                        : AppColors.deepGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    )),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGomdol
                            ? Icons.report_problem
                            : isSanal
                            ? Icons.lightbulb_outline
                            : Icons.notifications_outlined,
                        size: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 16,
                          veryNarrow: 10,
                        ),
                        color: isGomdol
                            ? Colors.orange
                            : AppColors.deepGreen,
                      ),
                      SizedBox(width: context.responsiveSpacing(
                        small: 4,
                        medium: 5,
                        large: 6,
                        tablet: 8,
                        veryNarrow: 3,
                      )),
                      Text(
                        _getDisplayTurul(_notification.turul),
                        style: TextStyle(
                          color: isGomdol
                              ? Colors.orange
                              : AppColors.deepGreen,
                          fontSize: context.responsiveFontSize(
                            small: 10,
                            medium: 11,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 9,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isGomdol || isSanal) ...[
                  SizedBox(width: context.responsiveSpacing(
                    small: 8,
                    medium: 9,
                    large: 10,
                    tablet: 12,
                    veryNarrow: 6,
                  )),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(
                        small: 8,
                        medium: 9,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 6,
                      ),
                      vertical: context.responsiveSpacing(
                        small: 5,
                        medium: 6,
                        large: 7,
                        tablet: 8,
                        veryNarrow: 4,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: _isStatusDone(_notification)
                          ? AppColors.success.withOpacity(0.12)
                          : _isStatusRejected(_notification)
                          ? AppColors.error.withOpacity(0.12)
                          : _notification.hasReply
                          ? AppColors.success.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 8,
                        medium: 9,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 6,
                      )),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isStatusDone(_notification)
                              ? Icons.check_circle_outline
                              : _isStatusRejected(_notification)
                              ? Icons.cancel_outlined
                              : _notification.hasReply
                              ? Icons.check_circle_outline
                              : Icons.schedule,
                          size: context.responsiveFontSize(
                            small: 11,
                            medium: 12,
                            large: 13,
                            tablet: 15,
                            veryNarrow: 9,
                          ),
                          color: _isStatusDone(_notification)
                              ? AppColors.success
                              : _isStatusRejected(_notification)
                              ? AppColors.error
                              : _notification.hasReply
                              ? AppColors.success
                              : Colors.orange,
                        ),
                        SizedBox(width: context.responsiveSpacing(
                          small: 4,
                          medium: 5,
                          large: 6,
                          tablet: 8,
                          veryNarrow: 3,
                        )),
                        Text(
                          _getStatusText(_notification),
                          style: TextStyle(
                            color: _isStatusDone(_notification)
                                ? AppColors.success
                                : _isStatusRejected(_notification)
                                ? AppColors.error
                                : _notification.hasReply
                                ? AppColors.success
                                : Colors.orange,
                            fontSize: context.responsiveFontSize(
                              small: 9,
                              medium: 10,
                              large: 11,
                              tablet: 13,
                              veryNarrow: 8,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing(
            small: 14,
            medium: 15,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          )),
          // Title
          Text(
            _notification.title,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: context.responsiveFontSize(
                small: 16,
                medium: 17,
                large: 18,
                tablet: 20,
                veryNarrow: 14,
              ),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.responsiveSpacing(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          )),
          // Message
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing(
              small: 12,
              medium: 13,
              large: 14,
              tablet: 16,
              veryNarrow: 10,
            )),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 10,
                medium: 11,
                large: 12,
                tablet: 14,
                veryNarrow: 8,
              )),
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              _notification.message,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: context.responsiveFontSize(
                  small: 14,
                  medium: 15,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 12,
                ),
                height: 1.5,
              ),
            ),
          ),
          if (_notification.hasReply && (isGomdol || isSanal)) ...[
            SizedBox(height: context.responsiveSpacing(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            )),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing(
                small: 12,
                medium: 13,
                large: 14,
                tablet: 16,
                veryNarrow: 10,
              )),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                  small: 10,
                  medium: 11,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 8,
                )),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(
                        small: 8,
                        medium: 9,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 6,
                      ),
                      vertical: context.responsiveSpacing(
                        small: 4,
                        medium: 5,
                        large: 6,
                        tablet: 8,
                        veryNarrow: 3,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 6,
                        medium: 7,
                        large: 8,
                        tablet: 10,
                        veryNarrow: 4,
                      )),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          color: AppColors.success,
                          size: context.responsiveFontSize(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 16,
                            veryNarrow: 10,
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing(
                          small: 4,
                          medium: 5,
                          large: 6,
                          tablet: 8,
                          veryNarrow: 3,
                        )),
                        Text(
                          'Хариу',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: context.responsiveFontSize(
                              small: 10,
                              medium: 11,
                              large: 12,
                              tablet: 14,
                              veryNarrow: 9,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  )),
                  Text(
                    _notification.tailbar!,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 11,
                        medium: 12,
                        large: 13,
                        tablet: 15,
                        veryNarrow: 10,
                      ),
                      height: 1.5,
                    ),
                  ),
                  if (_notification.repliedAt != null) ...[
                    SizedBox(height: context.responsiveSpacing(
                      small: 10,
                      medium: 11,
                      large: 12,
                      tablet: 14,
                      veryNarrow: 8,
                    )),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: context.responsiveFontSize(
                            small: 10,
                            medium: 11,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 9,
                          ),
                          color: context.textSecondaryColor,
                        ),
                        SizedBox(width: context.responsiveSpacing(
                          small: 4,
                          medium: 5,
                          large: 6,
                          tablet: 8,
                          veryNarrow: 3,
                        )),
                        Text(
                          'Хариу өгсөн: ${_formatDate(_notification.repliedAt!)}',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 9,
                              medium: 10,
                              large: 11,
                              tablet: 13,
                              veryNarrow: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: context.responsiveSpacing(
            small: 14,
            medium: 15,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          )),
          // Details section
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing(
              small: 12,
              medium: 13,
              large: 14,
              tablet: 16,
              veryNarrow: 10,
            )),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 10,
                medium: 11,
                large: 12,
                tablet: 14,
                veryNarrow: 8,
              )),
              border: Border.all(
                color: _isStatusDone(_notification)
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.deepGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.deepGreen,
                      size: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 12,
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing(
                      small: 6,
                      medium: 7,
                      large: 8,
                      tablet: 10,
                      veryNarrow: 4,
                    )),
                    Text(
                      'Дэлгэрэнгүй',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 16,
                          veryNarrow: 10,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing(
                  small: 12,
                  medium: 13,
                  large: 14,
                  tablet: 16,
                  veryNarrow: 10,
                )),
                _buildDetailRow(
                  'Огноо',
                  _notification.formattedDateTime,
                  Icons.calendar_today,
                ),
                if (_notification.gereeniiDugaar != null &&
                    _notification.gereeniiDugaar!.isNotEmpty)
                  _buildDetailRow(
                    'Гэрээний дугаар',
                    _notification.gereeniiDugaar!,
                    Icons.description,
                  ),
                if (_notification.orshinSuugchGereeniiDugaar != null &&
                    _notification.orshinSuugchGereeniiDugaar!.isNotEmpty)
                  _buildDetailRow(
                    'Оршин суугчийн гэрээний дугаар',
                    _notification.orshinSuugchGereeniiDugaar!,
                    Icons.person_outline,
                  ),
                if (_notification.orshinSuugchNer != null &&
                    _notification.orshinSuugchNer!.isNotEmpty)
                  _buildDetailRow(
                    'Оршин суугчийн нэр',
                    _notification.orshinSuugchNer!,
                    Icons.person,
                  ),
                if (_notification.orshinSuugchUtas != null &&
                    _notification.orshinSuugchUtas!.isNotEmpty)
                  _buildDetailRow(
                    'Утасны дугаар',
                    _notification.orshinSuugchUtas!,
                    Icons.phone,
                  ),
                _buildDetailRow(
                  'Төлөв',
                  _getStatusText(_notification),
                  _isStatusDone(_notification)
                      ? Icons.check_circle_outline
                      : _isStatusRejected(_notification)
                      ? Icons.cancel_outlined
                      : _notification.hasReply
                      ? Icons.check_circle_outline
                      : Icons.schedule,
                ),
                _buildDetailRow(
                  'Үүсгэсэн огноо',
                  _formatDate(_notification.createdAt),
                  Icons.access_time,
                ),
                if (_notification.updatedAt != _notification.createdAt)
                  _buildDetailRow(
                    'Шинэчлэгдсэн огноо',
                    _formatDate(_notification.updatedAt),
                    Icons.update,
                  ),
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing(
            small: 16,
            medium: 17,
            large: 18,
            tablet: 20,
            veryNarrow: 12,
          )),
          _buildChatSection(),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    if (_threadLoading) {
      return Padding(
        padding: EdgeInsets.all(context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        )),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.deepGreen,
            ),
          ),
        ),
      );
    }
    if (_threadItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 8,
        )),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsiveSpacing(
            small: 2,
            medium: 3,
            large: 4,
            tablet: 6,
            veryNarrow: 0,
          )),
          child: Text(
            'Харилцлага',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: context.responsiveFontSize(
                small: 14,
                medium: 15,
                large: 16,
                tablet: 18,
                veryNarrow: 12,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 9,
          large: 10,
          tablet: 12,
          veryNarrow: 6,
        )),
        ..._threadItems.map((msg) => _buildChatBubble(msg)),
        SizedBox(height: context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 8,
        )),
      ],
    );
  }

  Widget _buildChatBubble(Medegdel msg) {
    final isUser = msg.isUserReply;
    return Padding(
      padding: EdgeInsets.only(bottom: context.responsiveSpacing(
        small: 8,
        medium: 9,
        large: 10,
        tablet: 12,
        veryNarrow: 6,
      )),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const SizedBox.shrink(),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
                vertical: context.responsiveSpacing(
                  small: 10,
                  medium: 11,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 8,
                ),
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.deepGreen.withOpacity(0.15)
                    : (context.isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.responsiveBorderRadius(
                    small: 14,
                    medium: 15,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 12,
                  )),
                  topRight: Radius.circular(context.responsiveBorderRadius(
                    small: 14,
                    medium: 15,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 12,
                  )),
                  bottomLeft: Radius.circular(isUser ? context.responsiveBorderRadius(
                    small: 14,
                    medium: 15,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 12,
                  ) : 4),
                  bottomRight: Radius.circular(isUser ? 4 : context.responsiveBorderRadius(
                    small: 14,
                    medium: 15,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 12,
                  )),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.zurag != null && msg.zurag!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.responsiveSpacing(small: 6, medium: 8, large: 10, tablet: 12, veryNarrow: 4)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 200),
                          child: Image.network(
                            '${ApiService.baseUrl}/medegdel/${_normalizeMedegdelPath(msg.zurag)}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, o, s) => const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  if (msg.duu != null && msg.duu!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.responsiveSpacing(small: 6, medium: 8, large: 10, tablet: 12, veryNarrow: 4)),
                      child: InkWell(
                        onTap: () => _playOrPauseVoice(msg.id, msg.duu!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playingVoiceMessageId == msg.id && _voicePlayer?.state == PlayerState.playing
                                  ? Icons.pause_circle
                                  : Icons.play_circle_fill,
                              color: AppColors.deepGreen,
                              size: 28,
                            ),
                            SizedBox(width: context.responsiveSpacing(small: 6, medium: 8, large: 10, veryNarrow: 4)),
                            Text('Дуу сонсох', style: TextStyle(color: AppColors.deepGreen, fontSize: context.responsiveFontSize(small: 12, medium: 13, large: 14, veryNarrow: 11))),
                          ],
                        ),
                      ),
                    ),
                  if (msg.message.isNotEmpty)
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 13,
                          medium: 14,
                          large: 15,
                          tablet: 17,
                          veryNarrow: 12,
                        ),
                      ),
                    ),
                  if (msg.message.isNotEmpty) SizedBox(height: context.responsiveSpacing(small: 4, medium: 5, large: 6, tablet: 8, veryNarrow: 3)),
                  Text(
                    _formatDate(msg.createdAt),
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 9,
                        medium: 10,
                        large: 11,
                        tablet: 13,
                        veryNarrow: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsiveSpacing(small: 12, medium: 14, large: 16, tablet: 18, veryNarrow: 10),
        context.responsiveSpacing(small: 8, medium: 9, large: 10, tablet: 12, veryNarrow: 6),
        context.responsiveSpacing(small: 12, medium: 14, large: 16, tablet: 18, veryNarrow: 10),
        context.responsiveSpacing(small: 8, medium: 10, large: 12, tablet: 14, veryNarrow: 6),
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: context.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyImage != null || _replyVoicePath != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.responsiveSpacing(small: 6, medium: 8, veryNarrow: 4)),
                child: Row(
                  children: [
                    if (_replyImage != null)
                      Chip(
                        label: const Text('Зураг'),
                        onDeleted: () => setState(() => _replyImage = null),
                        avatar: const Icon(Icons.image, size: 18),
                      ),
                    if (_replyVoicePath != null) ...[
                      if (_replyImage != null) const SizedBox(width: 8),
                      Chip(
                        label: const Text('Дуу'),
                        onDeleted: () => setState(() => _replyVoicePath = null),
                        avatar: const Icon(Icons.mic, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _sendingReply ? null : _pickImage,
                  icon: Icon(Icons.image_outlined, color: AppColors.deepGreen, size: context.responsiveFontSize(small: 22, medium: 24, veryNarrow: 20)),
                ),
                if (!_recording)
                  IconButton(
                    onPressed: _sendingReply ? null : _startRecord,
                    icon: Icon(Icons.mic_none, color: AppColors.deepGreen, size: context.responsiveFontSize(small: 22, medium: 24, veryNarrow: 20)),
                  )
                else
                  IconButton(
                    onPressed: _stopRecord,
                    icon: Icon(Icons.stop_rounded, color: Colors.red, size: context.responsiveFontSize(small: 22, medium: 24, veryNarrow: 20)),
                  ),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    cursorColor: AppColors.deepGreen,
                    cursorHeight: context.responsiveFontSize(
                      small: 18,
                      medium: 20,
                      large: 22,
                      tablet: 24,
                      veryNarrow: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Хариу бичих...',
                      hintStyle: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 12,
                        ),
                      ),
                      filled: true,
                      fillColor: context.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                          small: 20,
                          medium: 22,
                          large: 24,
                          tablet: 28,
                          veryNarrow: 16,
                        )),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(
                          small: 14,
                          medium: 16,
                          large: 18,
                          tablet: 20,
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
                    ),
                    style: TextStyle(
                      color: context.isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                SizedBox(width: context.responsiveSpacing(
                  small: 8,
                  medium: 10,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 6,
                )),
                IconButton(
                  onPressed: (_sendingReply || (_replyController.text.trim().isEmpty && _replyImage == null && _replyVoicePath == null)) ? null : _sendReply,
                  icon: _sendingReply
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.deepGreen,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: AppColors.deepGreen,
                          size: context.responsiveFontSize(
                            small: 22,
                            medium: 24,
                            large: 26,
                            tablet: 28,
                            veryNarrow: 20,
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing(
          small: 8,
          medium: 9,
          large: 10,
          tablet: 12,
          veryNarrow: 6,
        )),
        padding: EdgeInsets.all(context.responsiveSpacing(
          small: 10,
          medium: 11,
          large: 12,
          tablet: 14,
          veryNarrow: 8,
        )),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          )),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing(
                small: 6,
                medium: 7,
                large: 8,
                tablet: 10,
                veryNarrow: 4,
              )),
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                  small: 6,
                  medium: 7,
                  large: 8,
                  tablet: 10,
                  veryNarrow: 4,
                )),
              ),
              child: Icon(
                icon,
                size: context.responsiveFontSize(
                  small: 12,
                  medium: 13,
                  large: 14,
                  tablet: 16,
                  veryNarrow: 10,
                ),
                color: AppColors.deepGreen,
              ),
            ),
            SizedBox(width: context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 9,
                        medium: 10,
                        large: 11,
                        tablet: 13,
                        veryNarrow: 8,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(
                    small: 3,
                    medium: 4,
                    large: 5,
                    tablet: 6,
                    veryNarrow: 2,
                  )),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 11,
                        medium: 12,
                        large: 13,
                        tablet: 15,
                        veryNarrow: 10,
                      ),
                      fontWeight: FontWeight.w600,
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class MedegdelDetailScreen extends StatefulWidget {
  final Medegdel notification;

  const MedegdelDetailScreen({super.key, required this.notification});

  @override
  State<MedegdelDetailScreen> createState() => _MedegdelDetailScreenState();
}

class _MedegdelDetailScreenState extends State<MedegdelDetailScreen> {
  late Medegdel _notification;
  bool _isMarkingAsRead = false;
  List<Medegdel> _threadItems = [];
  bool _threadLoading = false;
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;
  void Function(Map<String, dynamic>)? _socketCallback;
  XFile? _replyImage;
  String? _replyVoicePath;
  bool _recording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _voicePlayer;
  String? _playingVoiceMessageId;

  String _getDisplayTurul(String turul) {
    final turulLower = turul.toLowerCase();
    if (turulLower == 'gomdol') return 'Гомдол';
    if (turulLower == 'sanal') return 'Санал';
    if (turulLower == 'khariu' ||
        turulLower == 'hariu' ||
        turulLower == 'хариу')
      return 'Хариу';
    if (turulLower == 'app') return 'Мэдэгдэл';
    return turul; // Return original if not recognized
  }

  String _getStatusText(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    if (status == 'done') {
      return 'Шийдэгдсэн';
    }
    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан') {
      return 'Татгалзсан';
    }
    if (notification.hasReply) {
      return 'Хариу өгсөн';
    }
    return 'Хүлээгдэж байна';
  }

  bool _isStatusDone(Medegdel notification) {
    return notification.status?.toLowerCase() == 'done';
  }

  bool _isStatusRejected(Medegdel notification) {
    final status = notification.status?.toLowerCase();
    return status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан';
  }

  @override
  void initState() {
    super.initState();
    _voicePlayer = AudioPlayer();
    _voicePlayer!.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoiceMessageId = null);
    });
    _notification = widget.notification;
    _markAsReadAutomatically();
    _loadThread();
    final rootId = (_notification.parentId ?? _notification.id).toString().trim();
    _socketCallback = (data) {
      if (!mounted) return;
      final payloadParentId = (data['parentId']?.toString() ?? '').trim();
      final turul = (data['turul'] ?? '').toString().toLowerCase();
      final isAdminReply = turul == 'khariu' || turul == 'хариу' || turul == 'hariu';
      if (payloadParentId.isEmpty || rootId.isEmpty) return;
      if (payloadParentId != rootId || !isAdminReply) return;
      Medegdel? msg;
      try {
        msg = Medegdel.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        try {
          final j = Map<String, dynamic>.from(data);
          msg = Medegdel(
            id: j['_id']?.toString() ?? '',
            parentId: j['parentId']?.toString(),
            baiguullagiinId: j['baiguullagiinId']?.toString() ?? '',
            barilgiinId: j['barilgiinId']?.toString(),
            ognoo: j['ognoo']?.toString() ?? j['createdAt']?.toString() ?? '',
            title: j['title']?.toString() ?? '',
            gereeniiDugaar: j['gereeniiDugaar']?.toString(),
            message: j['message']?.toString() ?? '',
            orshinSuugchGereeniiDugaar: j['orshinSuugchGereeniiDugaar']?.toString(),
            orshinSuugchId: j['orshinSuugchId']?.toString(),
            orshinSuugchNer: j['orshinSuugchNer']?.toString(),
            orshinSuugchUtas: j['orshinSuugchUtas']?.toString(),
            kharsanEsekh: j['kharsanEsekh'] == true,
            turul: j['turul']?.toString() ?? 'khariu',
            createdAt: j['createdAt']?.toString() ?? '',
            updatedAt: j['updatedAt']?.toString() ?? '',
            status: j['status']?.toString(),
            tailbar: j['tailbar']?.toString(),
            repliedAt: j['repliedAt']?.toString(),
            zurag: j['zurag']?.toString(),
            duu: j['duu']?.toString(),
          );
        } catch (_) {
          return;
        }
      }
      if (msg == null || !mounted) return;
      final messageId = msg.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (_threadItems.any((m) => m.id == messageId)) return;
          _threadItems = [..._threadItems, msg!];
        });
      });
    };
    SocketService.instance.setNotificationCallback(_socketCallback!);
  }

  @override
  void dispose() {
    _voicePlayer?.dispose();
    _voicePlayer = null;
    if (_socketCallback != null) {
      SocketService.instance.removeNotificationCallback(_socketCallback);
    }
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _playOrPauseVoice(String messageId, String url) async {
    if (!mounted) return;
    final fullUrl = '${ApiService.baseUrl}/medegdel/${_normalizeMedegdelPath(url)}';
    // iOS AVPlayer does not support WebM; stay on page and show message (no external link)
    if (Platform.isIOS && url.toLowerCase().contains('.webm')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Энэ дууны формат (WebM) төхөөрөмж дээр тоглуулагдахгүй. M4A/MP3 илгээнэ үү.')),
        );
      }
      return;
    }
    if (_voicePlayer == null || !mounted) return;
    final isThisPlaying = _playingVoiceMessageId == messageId;
    try {
      if (isThisPlaying) {
        final state = _voicePlayer!.state;
        if (state == PlayerState.playing) {
          await _voicePlayer!.pause();
        } else {
          await _voicePlayer!.resume();
        }
        if (mounted) setState(() {});
      } else {
        await _voicePlayer!.stop();
        await _voicePlayer!.setSource(UrlSource(fullUrl));
        await _voicePlayer!.resume();
        if (mounted) setState(() => _playingVoiceMessageId = messageId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _playingVoiceMessageId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Дуу тоглуулахад алдаа: $e')));
      }
    }
  }

  Future<void> _loadThread() async {
    final rootId = _notification.parentId ?? _notification.id;
    if (rootId.isEmpty) return;
    setState(() => _threadLoading = true);
    try {
      final res = await ApiService.getMedegdelThread(rootId);
      if (!mounted) return;
      final list = (res['data'] as List?)
          ?.map((e) => Medegdel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [];
      setState(() {
        _threadItems = list;
        _threadLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _threadLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null || !mounted) {
        if (x == null) print('[medegdel] _pickImage: user cancelled or no image');
        return;
      }
      if (mounted) setState(() => _replyImage = x);
      print('[medegdel] _pickImage: ok name=${x.name}');
    } catch (e, st) {
      print('[medegdel] _pickImage error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Зураг сонгоход алдаа: $e')));
    }
  }

  Future<void> _startRecord() async {
    if (_recording) return;
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дуу бичих эрх олгоно уу.')));
        return;
      }
      final isRecording = await _audioRecorder.isRecording();
      if (isRecording) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e, st) {
      print('[medegdel] _startRecord error: $e\n$st');
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Дуу бичих эхлэхэд алдаа: $e')));
      }
    }
  }

  Future<void> _stopRecord() async {
    if (!_recording) return;
    try {
      final isRecording = await _audioRecorder.isRecording();
      if (!isRecording) {
        if (mounted) setState(() => _recording = false);
        return;
      }
      final path = await _audioRecorder.stop();
      if (mounted) setState(() { _recording = false; if (path != null) _replyVoicePath = path; });
    } catch (e, st) {
      print('[medegdel] _stopRecord error: $e\n$st');
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    final hasText = text.isNotEmpty;
    final hasImage = _replyImage != null;
    final hasVoice = _replyVoicePath != null;
    if ((!hasText && !hasImage && !hasVoice) || _sendingReply) return;
    final rootId = _notification.parentId ?? _notification.id;
    print('[medegdel] _sendReply start rootId=$rootId hasText=$hasText hasImage=$hasImage hasVoice=$hasVoice');
    setState(() => _sendingReply = true);
    try {
      String? zuragPath;
      String? voicePath;
      if (_replyImage != null) {
        final bytes = await _replyImage!.readAsBytes();
        final name = _replyImage!.name;
        zuragPath = await ApiService.uploadMedegdelChatFileWithBytes(bytes, name.isEmpty ? 'image.jpg' : name);
        print('[medegdel] _sendReply upload ok zuragPath=$zuragPath');
        if (mounted) setState(() => _replyImage = null);
      }
      if (_replyVoicePath != null) {
        voicePath = await ApiService.uploadMedegdelChatFile(file: File(_replyVoicePath!));
        if (mounted) setState(() => _replyVoicePath = null);
      }
      print('[medegdel] _sendReply sending reply zurag=$zuragPath voice=$voicePath');
      final res = await ApiService.sendMedegdelReply(
        rootMedegdelId: rootId,
        message: text,
        zurag: zuragPath,
        voiceUrl: voicePath,
      );
      _replyController.clear();
      final data = res['data'];
      if (mounted && data is Map) {
        try {
          final newMsg = Medegdel.fromJson(Map<String, dynamic>.from(data));
          setState(() => _threadItems = [..._threadItems, newMsg]);
        } catch (_) {}
      }
      if (mounted) Future.delayed(const Duration(milliseconds: 500), () => _loadThread());
      print('[medegdel] _sendReply done');
    } catch (e, st) {
      print('[medegdel] _sendReply error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Илгээхэд алдаа: ${e is Exception ? e.toString() : e}')),
        );
      }
    }
    if (mounted) setState(() => _sendingReply = false);
  }

  Future<void> _markAsReadAutomatically() async {
    if (_notification.kharsanEsekh) {
      return;
    }

    final turul = _notification.turul.toLowerCase();
    final isMedegdel = turul == 'app';

    if (!isMedegdel) {
      return;
    }

    if (_isMarkingAsRead) {
      return;
    }

    setState(() {
      _isMarkingAsRead = true;
    });

    try {
      await ApiService.markMedegdelAsRead(_notification.id);
      if (mounted) {
        setState(() {
          _notification = Medegdel(
            id: _notification.id,
            parentId: _notification.parentId,
            baiguullagiinId: _notification.baiguullagiinId,
            barilgiinId: _notification.barilgiinId,
            ognoo: _notification.ognoo,
            title: _notification.title,
            gereeniiDugaar: _notification.gereeniiDugaar,
            message: _notification.message,
            orshinSuugchGereeniiDugaar:
                _notification.orshinSuugchGereeniiDugaar,
            orshinSuugchId: _notification.orshinSuugchId,
            orshinSuugchNer: _notification.orshinSuugchNer,
            orshinSuugchUtas: _notification.orshinSuugchUtas,
            kharsanEsekh: true,
            turul: _notification.turul,
            createdAt: _notification.createdAt,
            updatedAt: _notification.updatedAt,
            status: _notification.status,
            tailbar: _notification.tailbar,
            repliedAt: _notification.repliedAt,
          );
          _isMarkingAsRead = false;
        });
        // Backend marks root + all replies; refetch thread so "seen" shows on messages
        _loadThread();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMarkingAsRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGomdol = _notification.turul.toLowerCase() == 'gomdol';
    final isSanal = _notification.turul.toLowerCase() == 'sanal';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final turul = _notification.turul.toLowerCase();
          final isMedegdel = turul == 'app';
          final wasMarkedAsRead = _notification.kharsanEsekh && isMedegdel;
          if (Navigator.canPop(context)) {
            Navigator.pop(context, wasMarkedAsRead);
          } else {
            context.pop(wasMarkedAsRead);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.backgroundColor, context.surfaceColor],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: context.responsivePadding(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: context.textPrimaryColor,
                          size: context.responsiveFontSize(
                            small: 26,
                            medium: 27,
                            large: 28,
                            tablet: 30,
                            veryNarrow: 22,
                          ),
                        ),
                        onPressed: () {
                          final turul = _notification.turul.toLowerCase();
                          final isMedegdel = turul == 'app';
                          final wasMarkedAsRead =
                              _notification.kharsanEsekh && isMedegdel;
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, wasMarkedAsRead);
                          } else {
                            context.pop(wasMarkedAsRead);
                          }
                        },
                      ),
                      SizedBox(width: context.responsiveSpacing(
                        small: 12,
                        medium: 13,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 8,
                      )),
                      Expanded(
                        child: Text(
                          isGomdol
                              ? 'Гомдол'
                              : isSanal
                              ? 'Санал'
                              : 'Мэдэгдэл',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 22,
                              medium: 23,
                              large: 24,
                              tablet: 26,
                              veryNarrow: 18,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: context.responsivePadding(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.responsiveSpacing(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 16,
                            veryNarrow: 10,
                          )),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
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
                              color: _isStatusDone(_notification)
                                  ? AppColors.success.withOpacity(0.3)
                                  : context.textPrimaryColor.withOpacity(0.15),
                              width: _isStatusDone(_notification) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsiveSpacing(
                                    small: 12,
                                    medium: 13,
                                    large: 14,
                                    tablet: 16,
                                    veryNarrow: 10,
                                  ),
                                  vertical: context.responsiveSpacing(
                                    small: 8,
                                    medium: 9,
                                    large: 10,
                                    tablet: 12,
                                    veryNarrow: 6,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: isGomdol
                                      ? Colors.orange.withOpacity(0.15)
                                      : isSanal
                                      ? AppColors.secondaryAccent.withOpacity(
                                          0.15,
                                        )
                                      : AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                    context.responsiveBorderRadius(
                                      small: 10,
                                      medium: 12,
                                      large: 14,
                                      tablet: 16,
                                      veryNarrow: 8,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGomdol
                                          ? Icons.report_problem
                                          : isSanal
                                          ? Icons.lightbulb_outline
                                          : Icons.notifications,
                                      size: context.responsiveFontSize(
                                        small: 18,
                                        medium: 19,
                                        large: 20,
                                        tablet: 22,
                                        veryNarrow: 14,
                                      ),
                                      color: isGomdol
                                          ? Colors.orange
                                          : isSanal
                                          ? AppColors.secondaryAccent
                                          : AppColors.primary,
                                    ),
                                    SizedBox(
                                      width: context.responsiveSpacing(
                                        small: 6,
                                        medium: 8,
                                        large: 10,
                                        tablet: 12,
                                        veryNarrow: 4,
                                      ),
                                    ),
                                    Text(
                                      _getDisplayTurul(_notification.turul),
                                      style: TextStyle(
                                        color: isGomdol
                                            ? Colors.orange
                                            : isSanal
                                            ? AppColors.secondaryAccent
                                            : AppColors.primary,
                                        fontSize: context.responsiveFontSize(
                                          small: 13,
                                          medium: 14,
                                          large: 15,
                                          tablet: 17,
                                          veryNarrow: 11,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isGomdol || isSanal) ...[
                                SizedBox(width: context.responsiveSpacing(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 8,
                                )),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsiveSpacing(
                                      small: 12,
                                      medium: 13,
                                      large: 14,
                                      tablet: 16,
                                      veryNarrow: 10,
                                    ),
                                    vertical: context.responsiveSpacing(
                                      small: 8,
                                      medium: 9,
                                      large: 10,
                                      tablet: 12,
                                      veryNarrow: 6,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isStatusDone(_notification)
                                        ? AppColors.success.withOpacity(0.15)
                                        : _isStatusRejected(_notification)
                                        ? AppColors.error.withOpacity(0.15)
                                        : _notification.hasReply
                                        ? AppColors.success.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(
                                      context.responsiveBorderRadius(
                                        small: 10,
                                        medium: 12,
                                        large: 14,
                                        tablet: 16,
                                        veryNarrow: 8,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isStatusDone(_notification)
                                            ? Icons.check_circle
                                            : _isStatusRejected(_notification)
                                            ? Icons.cancel
                                            : _notification.hasReply
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        size: context.responsiveFontSize(
                                          small: 16,
                                          medium: 17,
                                          large: 18,
                                          tablet: 20,
                                          veryNarrow: 12,
                                        ),
                                        color: _isStatusDone(_notification)
                                            ? AppColors.success
                                            : _isStatusRejected(_notification)
                                            ? AppColors.error
                                            : _notification.hasReply
                                            ? AppColors.success
                                            : Colors.orange,
                                      ),
                                      SizedBox(
                                        width: context.responsiveSpacing(
                                          small: 6,
                                          medium: 8,
                                          large: 10,
                                          tablet: 12,
                                          veryNarrow: 4,
                                        ),
                                      ),
                                      Text(
                                        _getStatusText(_notification),
                                        style: TextStyle(
                                          color: _isStatusDone(_notification)
                                              ? AppColors.success
                                              : _isStatusRejected(_notification)
                                              ? AppColors.error
                                              : _notification.hasReply
                                              ? AppColors.success
                                              : Colors.orange,
                                          fontSize: context.responsiveFontSize(
                                            small: 12,
                                            medium: 13,
                                            large: 14,
                                            tablet: 16,
                                            veryNarrow: 10,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
                        Container(
                          padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing(
                            small: 4,
                            medium: 5,
                            large: 6,
                            tablet: 8,
                            veryNarrow: 3,
                          )),
                          child: Text(
                            _notification.title,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 22,
                                medium: 23,
                                large: 24,
                                tablet: 26,
                                veryNarrow: 18,
                              ),
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsiveSpacing(
                          small: 16,
                          medium: 17,
                          large: 18,
                          tablet: 20,
                          veryNarrow: 12,
                        )),
                        Container(
                          padding: EdgeInsets.all(context.responsiveSpacing(
                            small: 18,
                            medium: 19,
                            large: 20,
                            tablet: 22,
                            veryNarrow: 14,
                          )),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
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
                              color: context.textPrimaryColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _notification.message,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 15,
                                medium: 16,
                                large: 17,
                                tablet: 19,
                                veryNarrow: 13,
                              ),
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (_notification.hasReply &&
                            (isGomdol || isSanal)) ...[
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
                            padding: EdgeInsets.all(context.responsiveSpacing(
                              small: 18,
                              medium: 19,
                              large: 20,
                              tablet: 22,
                              veryNarrow: 14,
                            )),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.success.withOpacity(0.12),
                                  AppColors.success.withOpacity(0.08),
                                ],
                              ),
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
                                color: AppColors.success.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsiveSpacing(
                                      small: 12,
                                      medium: 13,
                                      large: 14,
                                      tablet: 16,
                                      veryNarrow: 10,
                                    ),
                                    vertical: context.responsiveSpacing(
                                      small: 8,
                                      medium: 9,
                                      large: 10,
                                      tablet: 12,
                                      veryNarrow: 6,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                      context.responsiveBorderRadius(
                                        small: 10,
                                        medium: 12,
                                        large: 14,
                                        tablet: 16,
                                        veryNarrow: 8,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.reply_rounded,
                                        color: AppColors.success,
                                        size: context.responsiveFontSize(
                                          small: 20,
                                          medium: 21,
                                          large: 22,
                                          tablet: 24,
                                          veryNarrow: 16,
                                        ),
                                      ),
                                      SizedBox(width: context.responsiveSpacing(
                                        small: 8,
                                        medium: 9,
                                        large: 10,
                                        tablet: 12,
                                        veryNarrow: 6,
                                      )),
                                      Text(
                                        'Хариу',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: context.responsiveFontSize(
                                            small: 16,
                                            medium: 17,
                                            large: 18,
                                            tablet: 20,
                                            veryNarrow: 13,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.responsiveSpacing(
                                  small: 16,
                                  medium: 17,
                                  large: 18,
                                  tablet: 20,
                                  veryNarrow: 12,
                                )),
                                Text(
                                  _notification.tailbar!,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: context.responsiveFontSize(
                                      small: 14,
                                      medium: 15,
                                      large: 16,
                                      tablet: 18,
                                      veryNarrow: 12,
                                    ),
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (_notification.repliedAt != null) ...[
                                  SizedBox(height: context.responsiveSpacing(
                                    small: 14,
                                    medium: 15,
                                    large: 16,
                                    tablet: 18,
                                    veryNarrow: 10,
                                  )),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsiveSpacing(
                                        small: 10,
                                        medium: 11,
                                        large: 12,
                                        tablet: 14,
                                        veryNarrow: 8,
                                      ),
                                      vertical: context.responsiveSpacing(
                                        small: 6,
                                        medium: 7,
                                        large: 8,
                                        tablet: 10,
                                        veryNarrow: 4,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.textPrimaryColor
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(
                                        context.responsiveBorderRadius(
                                          small: 8,
                                          medium: 9,
                                          large: 10,
                                          tablet: 12,
                                          veryNarrow: 6,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: context.responsiveFontSize(
                                            small: 14,
                                            medium: 15,
                                            large: 16,
                                            tablet: 18,
                                            veryNarrow: 12,
                                          ),
                                          color: context.inputGrayColor,
                                        ),
                                        SizedBox(
                                          width: context.responsiveSpacing(
                                            small: 6,
                                            medium: 8,
                                            large: 10,
                                            tablet: 12,
                                            veryNarrow: 4,
                                          ),
                                        ),
                                        Text(
                                          'Хариу өгсөн: ${_formatDate(_notification.repliedAt!)}',
                                          style: TextStyle(
                                            color: context.inputGrayColor,
                                            fontSize: context.responsiveFontSize(
                                              small: 12,
                                              medium: 13,
                                              large: 14,
                                              tablet: 16,
                                              veryNarrow: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
                          padding: EdgeInsets.all(context.responsiveSpacing(
                            small: 18,
                            medium: 19,
                            large: 20,
                            tablet: 22,
                            veryNarrow: 14,
                          )),
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor.withOpacity(0.08),
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
                              color: _isStatusDone(_notification)
                                  ? AppColors.success.withOpacity(0.3)
                                  : context.textPrimaryColor.withOpacity(0.15),
                              width: _isStatusDone(_notification) ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: context.textPrimaryColor,
                                    size: context.responsiveFontSize(
                                      small: 20,
                                      medium: 21,
                                      large: 22,
                                      tablet: 24,
                                      veryNarrow: 16,
                                    ),
                                  ),
                                  SizedBox(width: context.responsiveSpacing(
                                    small: 8,
                                    medium: 9,
                                    large: 10,
                                    tablet: 12,
                                    veryNarrow: 6,
                                  )),
                                  Text(
                                    'Дэлгэрэнгүй',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: context.responsiveFontSize(
                                        small: 17,
                                        medium: 18,
                                        large: 19,
                                        tablet: 21,
                                        veryNarrow: 14,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsiveSpacing(
                                small: 18,
                                medium: 19,
                                large: 20,
                                tablet: 22,
                                veryNarrow: 14,
                              )),
                              _buildDetailRow(
                                'Огноо',
                                _notification.formattedDateTime,
                                Icons.calendar_today,
                              ),
                              if (_notification.gereeniiDugaar != null &&
                                  _notification.gereeniiDugaar!.isNotEmpty)
                                _buildDetailRow(
                                  'Гэрээний дугаар',
                                  _notification.gereeniiDugaar!,
                                  Icons.description,
                                ),
                              if (_notification.orshinSuugchGereeniiDugaar !=
                                      null &&
                                  _notification
                                      .orshinSuugchGereeniiDugaar!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Оршин суугчийн гэрээний дугаар',
                                  _notification.orshinSuugchGereeniiDugaar!,
                                  Icons.person_outline,
                                ),
                              if (_notification.orshinSuugchNer != null &&
                                  _notification.orshinSuugchNer!.isNotEmpty)
                                _buildDetailRow(
                                  'Оршин суугчийн нэр',
                                  _notification.orshinSuugchNer!,
                                  Icons.person,
                                ),
                              if (_notification.orshinSuugchUtas != null &&
                                  _notification.orshinSuugchUtas!.isNotEmpty)
                                _buildDetailRow(
                                  'Утасны дугаар',
                                  _notification.orshinSuugchUtas!,
                                  Icons.phone,
                                ),
                              _buildDetailRow(
                                'Төлөв',
                                _getStatusText(_notification),
                                _isStatusDone(_notification)
                                    ? Icons.check_circle
                                    : _isStatusRejected(_notification)
                                    ? Icons.cancel
                                    : _notification.hasReply
                                    ? Icons.check_circle
                                    : Icons.pending,
                              ),
                              _buildDetailRow(
                                'Үүсгэсэн огноо',
                                _formatDate(_notification.createdAt),
                                Icons.access_time,
                              ),
                              if (_notification.updatedAt !=
                                  _notification.createdAt)
                                _buildDetailRow(
                                  'Шинэчлэгдсэн огноо',
                                  _formatDate(_notification.updatedAt),
                                  Icons.update,
                                ),
                            ],
                          ),
                        ),
                        _buildChatSectionScreen(),
                      ],
                    ),
                  ),
                ),
              _buildReplyBarScreen(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildChatSectionScreen() {
    if (_threadLoading) {
      return Padding(
        padding: EdgeInsets.all(context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        )),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.deepGreen,
            ),
          ),
        ),
      );
    }
    if (_threadItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsiveSpacing(
          small: 20,
          medium: 24,
          large: 28,
          tablet: 32,
          veryNarrow: 14,
        )),
        Text(
          'Харилцлага',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: context.responsiveFontSize(
              small: 17,
              medium: 18,
              large: 19,
              tablet: 21,
              veryNarrow: 14,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 8,
        )),
        ..._threadItems.map((msg) => _buildChatBubbleScreen(msg)),
        SizedBox(height: context.responsiveSpacing(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 24,
          veryNarrow: 10,
        )),
      ],
    );
  }

  Widget _buildChatBubbleScreen(Medegdel msg) {
    final isUser = msg.isUserReply;
    return Padding(
      padding: EdgeInsets.only(bottom: context.responsiveSpacing(
        small: 10,
        medium: 12,
        large: 14,
        tablet: 16,
        veryNarrow: 8,
      )),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const SizedBox.shrink(),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing(
                  small: 14,
                  medium: 16,
                  large: 18,
                  tablet: 20,
                  veryNarrow: 12,
                ),
                vertical: context.responsiveSpacing(
                  small: 12,
                  medium: 14,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 10,
                ),
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.deepGreen.withOpacity(0.15)
                    : context.textPrimaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.zurag != null && msg.zurag!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 200),
                          child: Image.network(
                            '${ApiService.baseUrl}/medegdel/${_normalizeMedegdelPath(msg.zurag)}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, o, s) => const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  if (msg.duu != null && msg.duu!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _playOrPauseVoice(msg.id, msg.duu!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playingVoiceMessageId == msg.id && _voicePlayer?.state == PlayerState.playing
                                  ? Icons.pause_circle
                                  : Icons.play_circle_fill,
                              color: AppColors.deepGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text('Дуу сонсох', style: TextStyle(color: AppColors.deepGreen, fontSize: context.responsiveFontSize(small: 12, medium: 13, large: 14, veryNarrow: 11))),
                          ],
                        ),
                      ),
                    ),
                  if (msg.message.isNotEmpty)
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 12,
                        ),
                      ),
                    ),
                  if (msg.message.isNotEmpty) const SizedBox(height: 6),
                  Text(
                    _formatDate(msg.createdAt),
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 10,
                        medium: 11,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildReplyBarScreen() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsiveSpacing(small: 16, medium: 18, large: 20, tablet: 22, veryNarrow: 12),
        context.responsiveSpacing(small: 10, medium: 12, large: 14, tablet: 16, veryNarrow: 8),
        context.responsiveSpacing(small: 16, medium: 18, large: 20, tablet: 22, veryNarrow: 12),
        context.responsiveSpacing(small: 10, medium: 12, large: 14, tablet: 16, veryNarrow: 8),
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: context.isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyImage != null || _replyVoicePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (_replyImage != null)
                      Chip(
                        label: const Text('Зураг'),
                        onDeleted: () => setState(() => _replyImage = null),
                        avatar: const Icon(Icons.image, size: 18),
                      ),
                    if (_replyVoicePath != null) ...[
                      if (_replyImage != null) const SizedBox(width: 8),
                      Chip(
                        label: const Text('Дуу'),
                        onDeleted: () => setState(() => _replyVoicePath = null),
                        avatar: const Icon(Icons.mic, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _sendingReply ? null : _pickImage,
                  icon: Icon(Icons.image_outlined, color: AppColors.deepGreen, size: 24),
                ),
                if (!_recording)
                  IconButton(
                    onPressed: _sendingReply ? null : _startRecord,
                    icon: Icon(Icons.mic_none, color: AppColors.deepGreen, size: 24),
                  )
                else
                  IconButton(
                    onPressed: _stopRecord,
                    icon: const Icon(Icons.stop_rounded, color: Colors.red, size: 24),
                  ),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    cursorColor: AppColors.deepGreen,
                    cursorHeight: 20,
                    decoration: InputDecoration(
                      hintText: 'Хариу бичих...',
                      hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 15),
                      filled: true,
                      fillColor: context.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(
                      color: context.isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      fontSize: 15,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: (_sendingReply || (_replyController.text.trim().isEmpty && _replyImage == null && _replyVoicePath == null)) ? null : _sendReply,
                  icon: _sendingReply
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepGreen))
                      : Icon(Icons.send_rounded, color: AppColors.deepGreen, size: 26),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing(
          small: 14,
          medium: 15,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        )),
        padding: EdgeInsets.all(context.responsiveSpacing(
          small: 12,
          medium: 13,
          large: 14,
          tablet: 16,
          veryNarrow: 10,
        )),
        decoration: BoxDecoration(
          color: context.textPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
            small: 12,
            medium: 13,
            large: 14,
            tablet: 16,
            veryNarrow: 10,
          )),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing(
                small: 8,
                medium: 9,
                large: 10,
                tablet: 12,
                veryNarrow: 6,
              )),
              decoration: BoxDecoration(
                color: context.textPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                  small: 8,
                  medium: 9,
                  large: 10,
                  tablet: 12,
                  veryNarrow: 6,
                )),
              ),
              child: Icon(
                icon,
                size: context.responsiveFontSize(
                  small: 18,
                  medium: 19,
                  large: 20,
                  tablet: 22,
                  veryNarrow: 14,
                ),
                color: context.textPrimaryColor,
              ),
            ),
            SizedBox(width: context.responsiveSpacing(
              small: 12,
              medium: 13,
              large: 14,
              tablet: 16,
              veryNarrow: 10,
            )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.inputGrayColor,
                      fontSize: context.responsiveFontSize(
                        small: 12,
                        medium: 13,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 10,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(
                    small: 6,
                    medium: 7,
                    large: 8,
                    tablet: 10,
                    veryNarrow: 4,
                  )),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 12,
                      ),
                      fontWeight: FontWeight.w600,
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
