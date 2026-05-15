import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'dart:ui';

class SupportChatPage extends StatefulWidget {
  final Map<String, dynamic> extra;

  const SupportChatPage({super.key, required this.extra});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCreating = false;
  String? _chatId;
  List<dynamic> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkExistingChat();
    
    // Auto-fill reason if initialMessage is provided
    if (widget.extra['initialMessage'] != null) {
      _reasonController.text = widget.extra['initialMessage'];
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _reasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingChat() async {
    try {
      final paymentId = widget.extra['paymentId']?.toString();
      final objectId = widget.extra['objectId']?.toString();
      final invoiceNo = widget.extra['invoiceNo']?.toString();
      
      final idsToCheck = [paymentId, objectId, invoiceNo]
          .where((id) => id != null && id.isNotEmpty)
          .toList();
      
      if (idsToCheck.isEmpty) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        return;
      }

      for (var id in idsToCheck) {
        final chatData = await ApiService.getWalletChatByObjectId(id!);
        
        if (chatData != null && (chatData.containsKey('chatId') || chatData.containsKey('data'))) {
          setState(() {
            _chatId = chatData['chatId'] ?? chatData['data']?['chatId'];
            var msgs = chatData['messages'] ?? 
                       chatData['data']?['messages'] ?? 
                       chatData['Messages'] ?? 
                       chatData['data']?['Messages'];
            
            _messages = List<dynamic>.from(msgs ?? []);
            _isLoading = false;
          });
          _scrollToBottom();
          _fadeController.forward();
          return;
        }
      }
      
      setState(() => _isLoading = false);
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _createChat() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showGlassSnackBar(context, message: 'Шалтгаан заавал оруулна уу.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final paymentId = widget.extra['paymentId']?.toString();
      final objectId = widget.extra['objectId']?.toString();
      final invoiceNo = widget.extra['invoiceNo']?.toString();
      final billingName = widget.extra['billingName']?.toString() ?? 'Төлбөр';

      final effectiveObjectId = (objectId != null && objectId.isNotEmpty) 
          ? objectId 
          : null;

      final result = await ApiService.createWalletChat(
        paymentId: (paymentId != null && paymentId.isNotEmpty) ? paymentId : '',
        objectId: effectiveObjectId,
        reason: reason,
        subject: billingName,
        description: 'Төлбөрийн тусламж',
      );

      if (result.containsKey('chatId')) {
        setState(() {
          _chatId = result['chatId'];
          var msgs = result['messages'] ?? result['data']?['messages'];
          _messages = List<dynamic>.from(msgs ?? []);
          _isCreating = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isCreating = false);
      showGlassSnackBar(context, message: 'Чат үүсгэхэд алдаа гарлаа: $e');
    }
  }

  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty || _chatId == null) return;

    final tempMsg = {
      'message': msg,
      'sent': DateTime.now().toIso8601String(),
      'senderType': 'Хэтэвч хэрэглэгч',
      'senderName': 'Би',
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMsg);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final result = await ApiService.sendWalletChatMessage(
        chatId: _chatId!,
        message: msg,
      );
      
      var msgs = result['messages'] ?? result['data']?['messages'];
      if (msgs == null) {
        final updatedChat = await ApiService.getWalletChat(_chatId!);
        msgs = updatedChat['messages'] ?? updatedChat['data']?['messages'];
      }
      
      setState(() {
        _messages = List<dynamic>.from(msgs ?? []);
      });
      _scrollToBottom();
    } catch (e) {
      showGlassSnackBar(context, message: 'Мессеж илгээхэд алдаа гарлаа: $e');
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

  void _showHistory() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SupportHistoryModal(),
    );
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
                (widget.extra['billingName']?.toString() == 'Төлбөр' || widget.extra['billingName'] == null)
                    ? (widget.extra['bairniiNer']?.toString() ?? widget.extra['customerName']?.toString() ?? 'Дэмжлэгийн чат')
                    : widget.extra['billingName']!,
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
              actions: [
                IconButton(
                  icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87, size: 24.sp),
                  onPressed: _showHistory,
                ),
                SizedBox(width: 8.w),
              ],
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
                  : (_chatId == null ? _buildCreateChatView() : _buildChatRoomView()),
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

  Widget _buildCreateChatView() {
    final isDark = context.isDarkMode;
    
    debugPrint('🔵 [SUPPORT CHAT PAGE] extra[billingName]: ${widget.extra['billingName']}');
    debugPrint('🔵 [SUPPORT CHAT PAGE] extra[bairniiNer]: ${widget.extra['bairniiNer']}');
    debugPrint('🔵 [SUPPORT CHAT PAGE] extra[customerName]: ${widget.extra['customerName']}');

    final billingName = (widget.extra['billingName']?.toString() == 'Төлбөр' || widget.extra['billingName'] == null)
        ? (widget.extra['bairniiNer']?.toString() ?? widget.extra['customerName']?.toString() ?? 'Төлбөр')
        : widget.extra['billingName']!.toString();
    
    debugPrint('🔵 [SUPPORT CHAT PAGE] Resolved billingName: $billingName');

    final invoiceNo = widget.extra['invoiceNo']?.toString();
    final amount = widget.extra['amount'] ?? 0;
    final date = widget.extra['date']?.toString();

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : AppColors.deepGreen).withOpacity(0.05),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.deepGreen.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Биллинг', billingName, isHighlighted: true),
                if (invoiceNo != null) ...[
                  SizedBox(height: 12.h),
                  _buildInfoRow('Нэхэмжлэх', invoiceNo),
                ],
                SizedBox(height: 12.h),
                _buildInfoRow('Дүн', '${NumberFormat('#,###').format(amount)} ₮'),
                if (date != null) ...[
                  SizedBox(height: 12.h),
                  _buildInfoRow('Огноо', date),
                ],
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Тусламж хүсэх шалтгаан',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              style: TextStyle(fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: 'Энд шалтгаанаа бичнэ үү...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                contentPadding: EdgeInsets.all(16.w),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.deepGreen.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _isCreating
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('ЧАТ ЭХЛҮҮЛЭХ', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey[500])),
        Text(
          value, 
          style: TextStyle(
            fontSize: 14.sp, 
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? AppColors.deepGreen : (context.isDarkMode ? Colors.white : Colors.black87),
          )
        ),
      ],
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
                    final senderType = (msg['senderType']?.toString() ?? '').toUpperCase();
                    final senderName = msg['senderName']?.toString() ?? '';
                    final isMe = senderType.contains('WALLET') || senderType.contains('ХЭТЭВЧ') || senderName == 'Би' || msg['isTemp'] == true;
                    return _buildMessageBubble(msg, isMe);
                  },
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final isDark = context.isDarkMode;
    final sentDate = msg['sent'] != null ? DateTime.parse(msg['sent']).toLocal() : DateTime.now();
    final timeStr = DateFormat('HH:mm').format(sentDate);
    final isSeen = msg['isSeenOther'] == true || msg['seenOtherDate'] != null;

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
              Flexible(
                child: Container(
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
                  child: Text(
                    msg['message'] ?? '',
                    style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 15.sp, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) SizedBox(width: 40.w),
              Text(timeStr, style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
              if (isMe) ...[
                SizedBox(width: 4.w),
                Icon(isSeen ? Icons.done_all_rounded : Icons.done_rounded, size: 12.sp, color: isSeen ? Colors.blue : Colors.grey[400]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = context.isDarkMode;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, MediaQuery.of(context).padding.bottom + 12.h),
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
                decoration: InputDecoration(
                  hintText: 'Мессеж бичих...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48.h,
              width: 48.h,
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
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportHistoryModal extends StatefulWidget {
  @override
  State<_SupportHistoryModal> createState() => _SupportHistoryModalState();
}

class _SupportHistoryModalState extends State<_SupportHistoryModal> {
  bool _loading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await ApiService.getWalletNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r))),
          SizedBox(height: 20.h),
          Text('Тусламжийн түүх', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 20.h),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
                : (_notifications.isEmpty
                    ? Center(child: Text('Түүх байхгүй байна', style: TextStyle(color: Colors.grey[500])))
                    : ListView.separated(
                        padding: EdgeInsets.all(20.w),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          return Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.deepGreen.withOpacity(0.1),
                                  child: Icon(Icons.chat_outlined, size: 20.sp, color: AppColors.deepGreen),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title'] ?? 'Чат', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                      SizedBox(height: 4.h),
                                      Text(item['message'] ?? '', style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey[400]),
                              ],
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
