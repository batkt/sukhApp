import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:record/record.dart' as record;
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sukh_app/services/api_service.dart' show ApiService;

/// Base URL of the org's own sukhBackv2 backend (same as the rest of the app).
const String _kChatApiBase = ApiService.baseUrl;
const String _kChatSocketUrl = 'https://amarhome.mn';

class SupportChatPage extends StatefulWidget {
  final Map<String, dynamic> extra;

  const SupportChatPage({super.key, required this.extra});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  /// ID of the root medegdel document that acts as the chat thread.
  String? _chatId;
  List<dynamic> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  String? _userId;
  String? _baiguullagiinId;
  String? _barilgiinId;
  String? _displayName;
  String? _baiguullagaName;
  String? _authToken;

  // Chatbot choices are not used with the medegdel backend – kept for UI
  // compatibility but will remain empty.
  final List<dynamic> _rootChoices = [];
  List<dynamic> _currentChoices = [];
  bool _humanMode = true; // medegdel threads are always human-mode
  bool _isOperatorLoading = false;
  final String _restartLabel = 'Эхлэл рүү буцах';

  late AnimationController _fadeController;

  bool _isRecording = false;
  int _recordingTime = 0;
  record.AudioRecorder? _audioRecorder;
  Timer? _recordingTimer;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  sio.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _audioRecorder = record.AudioRecorder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder?.dispose();
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder!.start(
          const record.RecordConfig(encoder: record.AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingTime = 0;
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingTime++;
          });
        });
      } else {
        showGlassSnackBar(context, message: 'Микрофон ашиглах зөвшөөрөл шаардлагатай.');
      }
    } catch (e) {
      showGlassSnackBar(context, message: 'Бичлэг эхлүүлэхэд алдаа гарлаа: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await _uploadAndSendFile(file, 'audio', duration: _recordingTime);
        }
      }
    } catch (e) {
      showGlassSnackBar(context, message: 'Бичлэг хадгалахад алдаа гарлаа: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
        _recordingTime = 0;
      });
    } catch (_) {}
  }

  Future<void> _uploadAndSendFile(File file, String fileType, {int? duration}) async {
    if (_chatId == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Upload file to org's own backend
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_kChatApiBase/medegdel/uploadChatFile'),
      );
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      if (_baiguullagiinId != null) {
        request.fields['baiguullagiinId'] = _baiguullagiinId!;
      }

      final length = await file.length();
      int byteCount = 0;
      final stream = http.ByteStream(file.openRead().transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            byteCount += data.length;
            if (mounted) {
              setState(() {
                _uploadProgress = byteCount / length;
              });
            }
            sink.add(data);
          },
        ),
      ));

      request.files.add(
        http.MultipartFile('file', stream, length, filename: file.path.split('/').last),
      );
      request.fields['fileType'] = fileType;

      final streamedRes = await request.send();
      final response = await http.Response.fromStream(streamedRes);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          // path returned is like "baiguullagiinId/chat-xxx.ext"
          final filePath = resData['path']?.toString();

          // 2. Send reply with the file path
          final headers = <String, String>{'Content-Type': 'application/json'};
          if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

          final body = <String, dynamic>{
            'parentId': _chatId,
            'baiguullagiinId': _baiguullagiinId ?? '',
            'orshinSuugchId': _userId ?? '',
            'message': '',
          };
          if (fileType == 'audio' || fileType == 'voice') {
            body['voiceUrl'] = filePath ?? '';
          } else {
            body['zurag'] = filePath ?? '';
          }

          final msgResponse = await http.post(
            Uri.parse('$_kChatApiBase/medegdel/reply'),
            headers: headers,
            body: jsonEncode(body),
          );
          if (msgResponse.statusCode == 200 || msgResponse.statusCode == 201) {
            _fetchMessages(silent: true);
          }
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      showGlassSnackBar(context, message: 'Файл илгээхэд алдаа гарлаа: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final picker = image_picker.ImagePicker();
    
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = context.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Файл хавсаргах',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionItem(
                    icon: Icons.image_rounded,
                    label: 'Зураг сонгох',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(context, 'image'),
                  ),
                  _buildOptionItem(
                    icon: Icons.video_collection_rounded,
                    label: 'Видео сонгох',
                    color: Colors.purple,
                    onTap: () => Navigator.pop(context, 'video'),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );

    if (selection == null) return;

    if (selection == 'image') {
      final picked = await picker.pickImage(source: image_picker.ImageSource.gallery);
      if (picked != null) {
        await _uploadAndSendFile(File(picked.path), 'image');
      }
    } else if (selection == 'video') {
      final picked = await picker.pickVideo(
        source: image_picker.ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (picked != null) {
        await _uploadAndSendFile(File(picked.path), 'video');
      }
    }
  }

  Widget _buildOptionItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 28.sp, color: color),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _initializeChat() async {
    try {
      _userId = await StorageService.getUserId();
      final userName = await StorageService.getUserName() ?? 'Оршин суугч';
      final customerName = await StorageService.getWalletCustomerName();
      _baiguullagiinId = await StorageService.getBaiguullagiinId();
      _barilgiinId = await StorageService.getBarilgiinId();
      _authToken = await StorageService.getToken();
      final bairName = await StorageService.getWalletBairName() ?? '';
      final doorNo = await StorageService.getWalletDoorNo() ?? '';

      _displayName = customerName ?? userName;
      _baiguullagaName = bairName.isNotEmpty ? '$bairName - $doorNo тоот' : 'СӨХ Апп';

      if (_userId == null || _baiguullagiinId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          showGlassSnackBar(context, message: 'Хэрэглэгчийн мэдээлэл олдсонгүй');
        }
        return;
      }

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      // 1. Look for an existing "sanal" thread for this resident
      final listRes = await http.get(
        Uri.parse(
            '$_kChatApiBase/medegdel?orshinSuugchId=$_userId&baiguullagiinId=$_baiguullagiinId&turul=sanal'),
        headers: headers,
      );

      if (listRes.statusCode == 200) {
        final listData = jsonDecode(listRes.body);
        final existing = (listData['data'] as List<dynamic>? ?? []);
        // Pick the most recently updated one (list is sorted by updatedAt desc)
        if (existing.isNotEmpty) {
          _chatId = existing.first['_id']?.toString();
        }
      }

      // 2. If no existing thread, create one
      if (_chatId == null) {
        final createRes = await http.post(
          Uri.parse('$_kChatApiBase/medegdelIlgeeye'),
          headers: headers,
          body: jsonEncode({
            'orshinSuugchId': _userId,
            'baiguullagiinId': _baiguullagiinId,
            if (_barilgiinId != null) 'barilgiinId': _barilgiinId,
            'turul': 'sanal',
            'medeelel': {
              'title': '$_baiguullagaName - Чат',
              'body': 'Оршин суугч чат нээлээ.',
            },
          }),
        );
        if (createRes.statusCode == 200 || createRes.statusCode == 201) {
          final createData = jsonDecode(createRes.body);
          final dataList = createData['data'] as List<dynamic>?;
          if (dataList != null && dataList.isNotEmpty) {
            _chatId = dataList.first['_id']?.toString();
          }
        }
      }

      if (_chatId != null) {
        await _fetchMessages();
      }

      setState(() => _isLoading = false);
      _scrollToBottom();
      _fadeController.forward();

      // Connect socket.io to org's own backend
      _connectSocket();

      // Fallback poll every 30s in case socket misses something
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted && _chatId != null) {
          _fetchMessages(silent: true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        showGlassSnackBar(context, message: 'Чат холбоход алдаа гарлаа: $e');
      }
    }
  }

  void _connectSocket() {
    if (_chatId == null || _userId == null) return;
    // Connect to org's own sukhBackv2 socket and listen for admin replies
    // on the "orshinSuugch{userId}" room that medegdelAdminReply emits to.
    _socket = sio.io(
      _kChatSocketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) {
      // Join the resident-specific room so admin replies arrive in real time
      _socket!.emit('join', {'conversationId': _chatId});
    });
    // Admin reply: emitted as "orshinSuugch{userId}" with a Medegdel object
    _socket!.on('orshinSuugch$_userId', (payload) {
      if (!mounted) return;
      _fetchMessages(silent: true);
    });
    // Also handle the generic "baiguullagiin" broadcast in case the app is
    // showing a message from the admin panel
    _socket!.on('baiguullagiin$_baiguullagiinId', (payload) {
      if (!mounted) return;
      final type = payload is Map ? payload['type'] : null;
      if (type == 'medegdelAdminReply' || type == 'medegdelNew') {
        _fetchMessages(silent: true);
      }
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (_chatId == null || _baiguullagiinId == null) return;
    try {
      final headers = <String, String>{};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      final response = await http.get(
        Uri.parse(
            '$_kChatApiBase/medegdel/thread/$_chatId?baiguullagiinId=$_baiguullagiinId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final list = resData['data'] as List<dynamic>? ?? [];
        final lastOldId = _messages.isNotEmpty ? _messages.last['_id'] : null;
        final lastNewId = list.isNotEmpty ? list.last['_id'] : null;
        final hasNew = list.length != _messages.length || lastOldId != lastNewId;
        if (mounted) {
          setState(() {
            _messages = list;
          });
          if (hasNew) {
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        showGlassSnackBar(context, message: 'Мессеж татахад алдаа гарлаа');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final tempMsg = {
      'message': text,
      'createdAt': DateTime.now().toIso8601String(),
      // mark as user reply so the UI renders it on the right side
      'turul': 'user_reply',
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMsg);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      final response = await http.post(
        Uri.parse('$_kChatApiBase/medegdel/reply'),
        headers: headers,
        body: jsonEncode({
          'parentId': _chatId,
          'baiguullagiinId': _baiguullagiinId ?? '',
          'orshinSuugchId': _userId ?? '',
          'message': text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchMessages(silent: true);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, message: 'Мессеж илгээхэд алдаа гарлаа: $e');
      }
    }
  }

  /// Chatbot choices are not used with the medegdel backend;
  /// tapping a choice sends its label as a plain text reply instead.
  Future<void> _sendChoice(dynamic choice) async {
    final text = choice['label']?.toString() ?? '';
    if (text.isEmpty || _chatId == null) return;

    final tempMsg = {
      'message': text,
      'createdAt': DateTime.now().toIso8601String(),
      'turul': 'user_reply',
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMsg);
      _currentChoices = List<dynamic>.from(_rootChoices);
    });
    _scrollToBottom();

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      final response = await http.post(
        Uri.parse('$_kChatApiBase/medegdel/reply'),
        headers: headers,
        body: jsonEncode({
          'parentId': _chatId,
          'baiguullagiinId': _baiguullagiinId ?? '',
          'orshinSuugchId': _userId ?? '',
          'message': text,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchMessages(silent: true);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, message: 'Мессеж илгээхэд алдаа гарлаа: $e');
      }
    }
  }

  Future<void> _connectToOperator() async {
    // medegdel backend is always human-mode; no operator toggle needed.
    // This function is kept for UI button compatibility but is a no-op.
    if (mounted) {
      showGlassSnackBar(context, message: 'СӨХ-ийн ажилтан таны мессежийг харж хариу өгнө.');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Convert a medegdel file path (e.g. "baiguullagiinId/chat-123.jpg") to a
  /// full URL served by the org's own backend at /medegdel/:baiguullagiinId/:ner.
  /// If the path is already a full URL, returns it as-is.
  String _buildFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // medegdel files are served at: https://amarhome.mn/medegdel/{baiguullagiinId}/{filename}
    return 'https://amarhome.mn/medegdel/$path';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 10.h),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Тусламж & Дэмжлэг',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100.h,
            right: -50.w,
            child: _buildBlob(AppColors.deepGreen.withOpacity(0.15), 250.w),
          ),
          Positioned(
            bottom: 100.h,
            left: -80.w,
            child: _buildBlob(Colors.blue.withOpacity(0.1), 300.w),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
                  : _buildChatRoomView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildChatRoomView() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64.sp, color: AppColors.deepGreen.withOpacity(0.1)),
                      SizedBox(height: 16.h),
                      Text('Мессеж байхгүй байна', style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    // medegdel backend: user replies have turul='user_reply'
                    // The root medegdel itself (turul='sanal') is the admin greeting,
                    // shown as agent message. Temp messages added locally also use 'user_reply'.
                    final isMe = msg['turul'] == 'user_reply' || msg['isTemp'] == true;
                    int lastKhariuIdx = -1;
                    int lastUserIdx = -1;
                    for (int i = _messages.length - 1; i >= 0; i--) {
                      final t = _messages[i]['turul'];
                      final isUserMsg = t == 'user_reply' || _messages[i]['isTemp'] == true;
                      if (!isUserMsg && lastKhariuIdx == -1) lastKhariuIdx = i;
                      if (isUserMsg && lastUserIdx == -1) lastUserIdx = i;
                    }
                    final isLastAgentMsg = (index == lastKhariuIdx);
                    final isLastUserMsg = (index == lastUserIdx);
                    return _buildMessageBubble(
                      msg,
                      isMe,
                      isLastAgentMsg: isLastAgentMsg,
                      isLastUserMsg: isLastUserMsg,
                    );
                  },
                ),
        ),
        _buildChoicesContainer(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChoicesContainer() {
    if (_humanMode || _currentChoices.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            ..._currentChoices.map((c) {
              final label = c['label']?.toString() ?? '';
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ActionChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.deepGreen.withOpacity(0.06),
                  side: BorderSide(color: AppColors.deepGreen.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  onPressed: () => _sendChoice(c),
                ),
              );
            }),
            if (_currentChoices != _rootChoices)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ActionChip(
                  avatar: Icon(Icons.refresh_rounded, size: 14.sp, color: Colors.grey[500]),
                  label: Text(
                    _restartLabel,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  onPressed: () {
                    setState(() {
                      _currentChoices = List<dynamic>.from(_rootChoices);
                    });
                  },
                ),
              ),
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ActionChip(
                avatar: _isOperatorLoading
                    ? SizedBox(
                        width: 12.sp,
                        height: 12.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      )
                    : Icon(Icons.support_agent_rounded, size: 14.sp, color: Colors.green),
                label: Text(
                  'Оператортой холбох',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.green.withOpacity(0.06),
                side: BorderSide(color: Colors.green.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                onPressed: _isOperatorLoading ? null : _connectToOperator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    dynamic msg, 
    bool isMe, {
    bool isLastAgentMsg = false,
    bool isLastUserMsg = false,
  }) {
    final isDark = context.isDarkMode;
    final dateStr = msg['createdAt'] ?? msg['ognoo'];
    final sentDate = dateStr != null ? DateTime.tryParse(dateStr.toString())?.toLocal() ?? DateTime.now() : DateTime.now();
    final timeStr = DateFormat('HH:mm').format(sentDate);
    // medegdel fields: message text in 'message', image in 'zurag', voice in 'duu'
    final text = msg['message']?.toString() ?? msg['text']?.toString() ?? '';
    // zurag can be a single path or comma-separated; show the first one
    final zuragRaw = msg['zurag']?.toString();
    final fileUrl = zuragRaw != null && zuragRaw.isNotEmpty
        ? zuragRaw.split(',').first.trim()
        : null;
    final duuRaw = msg['duu']?.toString();
    final voiceUrl = duuRaw != null && duuRaw.isNotEmpty ? duuRaw : null;
    // Map to UI fileType
    final fileType = fileUrl != null ? 'image' : (voiceUrl != null ? 'audio' : msg['fileType']?.toString());
    final effectiveFileUrl = fileUrl ?? voiceUrl ?? msg['fileUrl']?.toString();
    final duration = msg['duration'];
    // medegdel has no read-receipt fields; skip seen-time display
    const bool readByGuest = false;
    const dynamic readByGuestAt = null;
    const bool readByAgent = false;
    const dynamic readByAgentAt = null;

    String? seenTimeStr;
    if (!isMe && readByGuestAt != null) {
      try {
        seenTimeStr = DateFormat('HH:mm').format(DateTime.parse(readByGuestAt.toString()).toLocal());
      } catch (_) {}
    } else if (isMe && readByAgentAt != null) {
      try {
        seenTimeStr = DateFormat('HH:mm').format(DateTime.parse(readByAgentAt.toString()).toLocal());
      } catch (_) {}
    }

    // Pure image/video messages render without bubble background
    final isMediaOnly = effectiveFileUrl != null && (fileType == 'image' || fileType == 'video') && text.isEmpty;

    // Build the media/content widget
    Widget buildContent() {
      if (isMediaOnly) {
        // Clean media card - no bubble background
        if (fileType == 'image') {
          final imgUrl = _buildFileUrl(effectiveFileUrl);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                    body: Center(child: Image.network(imgUrl)),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.network(
                imgUrl,
                width: 220.w,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                        width: 220.w,
                        height: 160.h,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
              ),
            ),
          );
        } else {
          // Video — no bubble
          return ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: ChatVideoPlayer(url: _buildFileUrl(effectiveFileUrl)),
          );
        }
      }

      // Normal bubble for text / audio / text+image
      return Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [AppColors.deepGreen, AppColors.deepGreenAccent], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isMe ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
            bottomRight: Radius.circular(isMe ? 4.r : 16.r),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty) ...[
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 15.sp,
                  height: 1.4,
                ),
              ),
              if (fileUrl != null) SizedBox(height: 8.h),
            ],
            if (fileUrl != null) ...[
              if (fileType == 'image')
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                          body: Center(child: Image.network(_buildFileUrl(effectiveFileUrl))),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(_buildFileUrl(effectiveFileUrl), width: 200.w, fit: BoxFit.fitWidth),
                  ),
                )
              else if (fileType == 'video')
                ChatVideoPlayer(url: _buildFileUrl(effectiveFileUrl))
              else if (fileType == 'audio')
                VoicePlayBubble(fileUrl: _buildFileUrl(effectiveFileUrl), duration: duration, isMe: isMe),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: AppColors.deepGreen.withOpacity(0.1),
                  child: Icon(Icons.support_agent_rounded, size: 16.sp, color: AppColors.deepGreen),
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(child: buildContent()),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) SizedBox(width: 40.w),
              Text(timeStr, style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
            ],
          ),
          // Show "Харсан HH:mm" under last agent/bot message or last user message
          if ((!isMe && isLastAgentMsg && readByGuest) || (isMe && isLastUserMsg && readByAgent)) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.done_all_rounded, size: 12.sp, color: Colors.blue.shade400),
                SizedBox(width: 3.w),
                Text(
                  seenTimeStr != null ? 'Харсан · $seenTimeStr' : 'Харсан',
                  style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade400, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = context.isDarkMode;
    
    if (_isRecording) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFFFF1F2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.red, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Дуу хурааж байна... ${_recordingTime ~/ 60}:${(_recordingTime % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            const Spacer(),
            TextButton(
              onPressed: _cancelRecording,
              child: Text('Болих', style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp)),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              child: Text('Илгээх', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF5F7FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.deepGreen, size: 28.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _isUploading ? null : _pickAndUploadFile,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(fontSize: 15.sp),
                enabled: !_isUploading,
                decoration: InputDecoration(
                  hintText: _isUploading ? 'Файл хуулж байна... ${(_uploadProgress * 100).toInt()}%' : 'Мессеж бичих...',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.mic_none_rounded, color: Colors.red.shade600, size: 28.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _isUploading ? null : _startRecording,
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _isUploading ? null : _sendMessage,
            child: Container(
              height: 44.h,
              width: 44.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepGreen, Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isUploading
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.send_rounded, color: Colors.white, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class VoicePlayBubble extends StatefulWidget {
  final String fileUrl;
  final dynamic duration;
  final bool isMe;

  const VoicePlayBubble({
    super.key,
    required this.fileUrl,
    this.duration,
    required this.isMe,
  });

  @override
  State<VoicePlayBubble> createState() => _VoicePlayBubbleState();
}

class _VoicePlayBubbleState extends State<VoicePlayBubble> {
  late audioplayers.AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDragging = false;      // true while user drags slider
  double _dragValue = 0.0;       // slider value during drag
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = audioplayers.AudioPlayer();
    
    if (widget.duration != null) {
      _duration = Duration(seconds: (widget.duration as num).round());
    }

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == audioplayers.PlayerState.playing;
        });
      }
    });

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = pos;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final fullUrl = 'https://admin.zevtabs.mn/api/file?path=${widget.fileUrl}';
      await _audioPlayer.play(audioplayers.UrlSource(fullUrl));
    }
  }

  String _formatDuration(Duration d) {
    final sec = d.inSeconds % 60;
    final min = d.inMinutes;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isMe ? Colors.white : AppColors.deepGreen;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      width: 200.w,
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              size: 36.sp,
              color: themeColor,
            ),
            onPressed: _togglePlay,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                    activeTrackColor: themeColor,
                    inactiveTrackColor: themeColor.withOpacity(0.25),
                    thumbColor: themeColor,
                    overlayColor: themeColor.withOpacity(0.15),
                  ),
                  child: Slider(
                    value: _isDragging
                        ? _dragValue
                        : (_duration.inMilliseconds > 0
                            ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0),
                    onChangeStart: (val) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = val;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _dragValue = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      final seekTo = Duration(milliseconds: (val * _duration.inMilliseconds).round());
                      await _audioPlayer.seek(seekTo);
                      setState(() {
                        _isDragging = false;
                        _position = seekTo;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 10.sp),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatVideoPlayer extends StatefulWidget {
  final String url;
  const ChatVideoPlayer({super.key, required this.url});

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.url), play: false);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Video(
          controller: controller,
          onEnterFullscreen: () async {
            // media_kit sets landscape AFTER calling onEnterFullscreen,
            // so we use a post-frame callback to override it back to portrait.
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            });
          },
          onExitFullscreen: () async {
            await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
          },
        ),
      ),
    );
  }
}

