import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';

class SupportChatPage extends StatefulWidget {
  final Map<String, dynamic> extra;

  const SupportChatPage({super.key, required this.extra});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  bool _isLoading = true;
  bool _isCreating = false;
  String? _chatId;
  List<dynamic> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkExistingChat();
  }

  Future<void> _checkExistingChat() async {
    try {
      final paymentId = widget.extra['paymentId']?.toString();
      if (paymentId == null) return;

      final chatData = await ApiService.getWalletChatByObjectId(paymentId);
      if (chatData != null) {
        setState(() {
          _chatId = chatData['chatId'];
          _messages = chatData['messages'] ?? [];
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createChat() async {
    if (_reasonController.text.trim().isEmpty) {
      showGlassSnackBar(context, message: 'Шалтгаан заавал оруулна уу.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final paymentId = widget.extra['paymentId']?.toString() ?? '';
      final result = await ApiService.createWalletChat(
        paymentId: paymentId,
        reason: _reasonController.text.trim(),
      );

      setState(() {
        _chatId = result['chatId'];
        _messages = result['messages'] ?? [];
        _isCreating = false;
      });
      _scrollToBottom();
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
      'senderType': 'WALLET_USER',
      'senderName': 'Та',
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
      setState(() {
        _messages = result['messages'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final paymentId = widget.extra['paymentId']?.toString() ?? '';
    final billingName = widget.extra['billingName']?.toString() ?? '';
    final amount = widget.extra['amount'] ?? 0;
    final invoiceNo = widget.extra['invoiceNo']?.toString() ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: buildStandardAppBar(
        context,
        title: 'Дэмжлэгийн чат',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatId == null
              ? _buildCreateChatView(billingName, invoiceNo, amount)
              : _buildChatRoomView(),
    );
  }

  Widget _buildCreateChatView(String title, String inv, dynamic amt) {
    final isDark = context.isDarkMode;
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.deepGreen, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildInfoRow('Нэхэмжлэх:', inv),
                _buildInfoRow('Төлсөн дүн:', '${NumberFormat('#,##0').format(amt)} ₮'),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Асуудлын тайлбар',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Жишээ: Төлбөр хийсэн ч статус шинэчлэгдэхгүй байна...',
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('ЧАТ ЭХЛҮҮЛЭХ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildChatRoomView() {
    final isDark = context.isDarkMode;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16.w),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isMe = msg['senderType'] == 'WALLET_USER';
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
    final timeStr = msg['sent'] != null 
        ? DateFormat('HH:mm').format(DateTime.parse(msg['sent'])) 
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isMe 
                  ? AppColors.deepGreen 
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
                bottomRight: Radius.circular(isMe ? 4.r : 20.r),
              ),
              boxShadow: [
                if (!isMe) BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              msg['message'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            timeStr,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = context.isDarkMode;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, MediaQuery.of(context).padding.bottom + 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Мессеж бичих...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send_rounded, color: AppColors.deepGreen),
          ),
        ],
      ),
    );
  }
}
