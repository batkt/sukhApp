import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/models/blog_model.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/blog_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:intl/intl.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  List<BlogModel> _blogs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;
  String? _baiguullagiinId;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupSocketListener();
  }

  Future<void> _initializeData() async {
    _userId = await StorageService.getUserId();
    _baiguullagiinId = await StorageService.getBaiguullagiinId();
    _loadBlogs();
  }

  void _setupSocketListener() {
    SocketService.instance.setBaiguullagiinMedegdelCallback((payload) {
      if (!mounted) return;
      
      final type = payload['type']?.toString();
      if (type == 'blogNew') {
        _loadBlogs();
      } else if (type == 'blogReactionUpdate') {
        final data = payload['data'];
        if (data != null && data['blogId'] != null) {
          final blogId = data['blogId'].toString();
          final reactions = (data['reactions'] as List)
              .map((e) => ReactionModel.fromJson(e))
              .toList();
          
          setState(() {
            final index = _blogs.indexWhere((b) => b.id == blogId);
            if (index != -1) {
              _blogs[index] = _blogs[index].copyWith(reactions: reactions);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.setBaiguullagiinMedegdelCallback(null);
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    if (_baiguullagiinId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final blogs = await BlogService.getBlogs(_baiguullagiinId!);
      setState(() {
        _blogs = blogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReaction(String blogId, String emoji) async {
    if (_userId == null || _baiguullagiinId == null) return;

    try {
      final updatedBlog = await BlogService.toggleReaction(
        blogId: blogId,
        baiguullagiinId: _baiguullagiinId!,
        emoji: emoji,
        orshinSuugchId: _userId!,
      );
      
      setState(() {
        final index = _blogs.indexWhere((b) => b.id == blogId);
        if (index != -1) {
          _blogs[index] = updatedBlog;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа гарлаа: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Мэдээ мэдээлэл'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _loadBlogs,
                  child: ListView.builder(
                    itemCount: _blogs.length,
                    itemBuilder: (context, index) {
                      return _buildBlogCard(_blogs[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildBlogCard(BlogModel blog) {
    return Card(
      margin: EdgeInsets.all(10.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (blog.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
              child: Image.network(
                '${ApiService.baseUrl}/medegdel/${blog.images.first}',
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200.h,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(blog.createdAt),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 10.h),
                Text(
                  blog.content,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 15.h),
                _buildReactions(blog),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BlogModel blog) {
    final emojis = ['🔥', '👍', '❤️', '👏', '😮'];
    
    return Wrap(
      spacing: 8.w,
      children: [
        ...emojis.map((emoji) {
          final reaction = blog.reactions.firstWhere(
            (r) => r.emoji == emoji,
            orElse: () => ReactionModel(emoji: emoji, count: 0, users: []),
          );
          final isSelected = _userId != null && reaction.users.contains(_userId);

          return FilterChip(
            label: Text('${reaction.emoji} ${reaction.count > 0 ? reaction.count : ""}'),
            selected: isSelected,
            onSelected: (_) => _toggleReaction(blog.id, emoji),
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
          );
        }),
      ],
    );
  }
}
