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

class SupportChatPage extends StatefulWidget {
  final Map<String, dynamic> extra;

  const SupportChatPage({super.key, required this.extra});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _chatId;
  List<dynamic> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  String? _guestId;
  String? _displayName;
  String? _baiguullagaName;
  String? _ajiltniiNer;

  List<dynamic> _rootChoices = [];
  List<dynamic> _currentChoices = [];
  bool _humanMode = false;
  bool _isOperatorLoading = false;
  String _restartLabel = 'Эхлэл рүү буцах';

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
    if (_chatId == null || _guestId == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/upload'),
      );
      
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
          final fileUrl = resData['fileUrl'];
          
          final msgResponse = await http.post(
            Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations/$_chatId/messages'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': '',
              'guestId': _guestId,
              'displayName': _displayName,
              'project': 'sukhapp',
              'baiguullagaName': _baiguullagaName,
              'ajiltniiNer': _ajiltniiNer,
              'fileUrl': fileUrl,
              'fileType': fileType,
              'duration': duration,
            }),
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
      final userId = await StorageService.getUserId() ?? 'unknown';
      final userName = await StorageService.getUserName() ?? 'Оршин суугч';
      final customerName = await StorageService.getWalletCustomerName();
      final bairName = await StorageService.getWalletBairName() ?? '';
      final doorNo = await StorageService.getWalletDoorNo() ?? '';

      _guestId = 'resident_$userId';
      _displayName = customerName ?? userName;
      _ajiltniiNer = _displayName;
      _baiguullagaName = bairName.isNotEmpty ? '$bairName - $doorNo тоот' : 'СӨХ Апп';

      // 1. Fetch chat config (chatbot choices)
      final configResponse = await http.get(Uri.parse('https://admin.zevtabs.mn/api/v1/chat/config?project=sukhapp'));
      if (configResponse.statusCode == 200) {
        final configData = jsonDecode(configResponse.body)['data'];
        if (configData != null) {
          _rootChoices = configData['rootChoices'] as List<dynamic>? ?? [];
          _currentChoices = List<dynamic>.from(_rootChoices);
          _restartLabel = configData['restartLabel'] ?? 'Эхлэл рүү буцах';
        }
      }

      // 2. Load existing or register conversation under sukhapp project
      final response = await http.post(
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guestId': _guestId,
          'displayName': _displayName,
          'project': 'sukhapp',
          'baiguullagaName': _baiguullagaName,
          'ajiltniiNer': _ajiltniiNer,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final convData = resData['data'];
        if (convData != null) {
          _chatId = convData['id'] ?? convData['_id'];
          _humanMode = convData['humanMode'] == true;
          await _fetchMessages();
        }
      }

      setState(() => _isLoading = false);
      _scrollToBottom();
      _fadeController.forward();

      // Connect socket.io for real-time messages
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
    if (_chatId == null) return;
    const socketUrl = 'https://admin.zevtabs.mn';
    _socket = sio.io(
      socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) {
      _socket!.emit('join', {'conversationId': _chatId});
    });
    _socket!.on('message:new', (payload) {
      if (!mounted) return;
      final convId = payload is Map ? payload['conversationId'] : null;
      if (convId != null && convId.toString() == _chatId) {
        _fetchMessages(silent: true);
      }
    });
    _socket!.on('conversation:read', (payload) {
      if (!mounted) return;
      final convId = payload is Map ? payload['conversationId'] : null;
      if (convId != null && convId.toString() == _chatId) {
        _fetchMessages(silent: true);
      }
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (_chatId == null || _guestId == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations/$_chatId/messages?guestId=$_guestId'),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final list = resData['data'] as List<dynamic>? ?? [];
        final lastOldId = _messages.isNotEmpty ? _messages.last['id'] : null;
        final lastNewId = list.isNotEmpty ? list.last['id'] : null;
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
    if (text.isEmpty || _chatId == null || _guestId == null) return;

    final tempMsg = {
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'role': 'user',
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMsg);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations/$_chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'guestId': _guestId,
          'displayName': _displayName,
          'project': 'sukhapp',
          'baiguullagaName': _baiguullagaName,
          'ajiltniiNer': _ajiltniiNer,
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

  Future<void> _sendChoice(dynamic choice) async {
    final text = choice['label']?.toString() ?? '';
    if (text.isEmpty || _chatId == null || _guestId == null) return;

    final tempMsg = {
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'role': 'user',
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMsg);
      final subChoices = choice['choices'] as List<dynamic>? ?? [];
      if (subChoices.isNotEmpty) {
        _currentChoices = subChoices;
      } else {
        _currentChoices = List<dynamic>.from(_rootChoices);
      }
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations/$_chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'guestId': _guestId,
          'displayName': _displayName,
          'project': 'sukhapp',
          'baiguullagaName': _baiguullagaName,
          'ajiltniiNer': _ajiltniiNer,
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
    if (_chatId == null || _guestId == null) return;
    setState(() => _isOperatorLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://admin.zevtabs.mn/api/v1/chat/conversations/$_chatId/operator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'guestId': _guestId}),
      );
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body)['data'];
        if (resData != null && resData['conversation'] != null) {
          setState(() {
            _humanMode = resData['conversation']['humanMode'] == true;
          });
        }
      }
      _fetchMessages(silent: true);
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, message: 'Оператортой холбоход алдаа гарлаа');
      }
    } finally {
      if (mounted) {
        setState(() => _isOperatorLoading = false);
      }
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
                    final isMe = msg['role'] == 'user';
                    // Find last HUMAN AGENT message index (not bot) and last user message index
                    int lastAgentIdx = -1;
                    int lastUserIdx = -1;
                    for (int i = _messages.length - 1; i >= 0; i--) {
                      if (_messages[i]['role'] == 'agent' && lastAgentIdx == -1) {
                        lastAgentIdx = i;
                      }
                      if (_messages[i]['role'] == 'user' && lastUserIdx == -1) {
                        lastUserIdx = i;
                      }
                    }
                    final isLastAgentMsg = (index == lastAgentIdx);
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
    final dateStr = msg['createdAt'];
    final sentDate = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();
    final timeStr = DateFormat('HH:mm').format(sentDate);
    final text = msg['text'] ?? '';
    final fileUrl = msg['fileUrl'];
    final fileType = msg['fileType'];
    final duration = msg['duration'];
    final readByGuest = msg['readByGuest'] == true;
    final readByGuestAt = msg['readByGuestAt'];
    final readByAgent = msg['readByAgent'] == true;
    final readByAgentAt = msg['readByAgentAt'];

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
    final isMediaOnly = fileUrl != null && (fileType == 'image' || fileType == 'video') && text.isEmpty;

    // Build the media/content widget
    Widget buildContent() {
      if (isMediaOnly) {
        // Clean media card - no bubble background
        if (fileType == 'image') {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                    body: Center(child: Image.network('https://admin.zevtabs.mn/api/file?path=$fileUrl')),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.network(
                'https://admin.zevtabs.mn/api/file?path=$fileUrl',
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
            child: ChatVideoPlayer(url: 'https://admin.zevtabs.mn/api/file?path=$fileUrl'),
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
                          body: Center(child: Image.network('https://admin.zevtabs.mn/api/file?path=$fileUrl')),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network('https://admin.zevtabs.mn/api/file?path=$fileUrl', width: 200.w, fit: BoxFit.fitWidth),
                  ),
                )
              else if (fileType == 'video')
                ChatVideoPlayer(url: 'https://admin.zevtabs.mn/api/file?path=$fileUrl')
              else if (fileType == 'audio')
                VoicePlayBubble(fileUrl: fileUrl, duration: duration, isMe: isMe),
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

