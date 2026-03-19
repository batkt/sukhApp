import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/models/blog_model.dart';
import 'package:sukh_app/services/blog_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:intl/intl.dart';

class BlogDetailPage extends StatefulWidget {
  final List<BlogModel> blogs;
  final int initialIndex;

  const BlogDetailPage({
    super.key,
    required this.blogs,
    required this.initialIndex,
  });

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  late BlogModel _currentBlog;
  String? _userId;
  String? _baiguullagiinId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentBlog = widget.blogs[_currentIndex];
    
    // Initializing PageController with infinite loop start if needed
    final initialPage = widget.blogs.length > 2 
        ? (widget.blogs.length * 500) + _currentIndex 
        : _currentIndex;
    _pageController = PageController(initialPage: initialPage);
    
    _initializeData();
    _setupSocketListener();
  }

  Future<void> _initializeData() async {
    _userId = await StorageService.getUserId();
    _baiguullagiinId = await StorageService.getBaiguullagiinId();
    setState(() {});
  }

  void _setupSocketListener() {
    SocketService.instance.setBaiguullagiinMedegdelCallback((payload) {
      if (!mounted) return;
      
      final type = payload['type']?.toString();
      if (type == 'blogReactionUpdate') {
        final data = payload['data'];
        if (data != null && data['blogId']?.toString() == _currentBlog.id) {
          final reactions = (data['reactions'] as List)
              .map((e) => ReactionModel.fromJson(e))
              .toList();
          
          setState(() {
            _currentBlog = _currentBlog.copyWith(reactions: reactions);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.setBaiguullagiinMedegdelCallback(null);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleReaction(String emoji) async {
    if (_userId == null || _baiguullagiinId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нэвтрэх шаардлагатай')),
      );
      return;
    }

    try {
      final updatedBlog = await BlogService.toggleReaction(
        blogId: _currentBlog.id,
        baiguullagiinId: _baiguullagiinId!,
        emoji: emoji,
        orshinSuugchId: _userId!,
      );
      
      setState(() {
        _currentBlog = updatedBlog;
      });
    } catch (e) {
      if (e.toString().contains('Өгөгдөл шинэчлэгдсэнгүй')) {
         _manuallyToggleReaction(emoji);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Алдаа гарлаа: $e')),
        );
      }
    }
  }

  void _manuallyToggleReaction(String emoji) {
     final reactions = List<ReactionModel>.from(_currentBlog.reactions);
     final index = reactions.indexWhere((r) => r.emoji == emoji);
     
     if (index >= 0) {
       final reaction = reactions[index];
       if (reaction.users.contains(_userId)) {
         final updatedUsers = List<String>.from(reaction.users)..remove(_userId);
         if (updatedUsers.isEmpty && reaction.count <= 1) {
           reactions.removeAt(index);
         } else {
           reactions[index] = ReactionModel(emoji: emoji, count: reaction.count - 1, users: updatedUsers);
         }
       } else {
         final updatedUsers = List<String>.from(reaction.users)..add(_userId!);
         reactions[index] = ReactionModel(emoji: emoji, count: reaction.count + 1, users: updatedUsers);
       }
     } else {
       reactions.add(ReactionModel(emoji: emoji, count: 1, users: [_userId!]));
     }
     
     setState(() {
       _currentBlog = _currentBlog.copyWith(reactions: reactions);
     });
  }

  void _showEmojiPicker() {
    final Map<String, List<String>> emojiGroups = {
      'Түгээмэл': ['❤️', '👍', '🔥', '👏', '😮', '😢', '🙌', '⭐', '✨', '💯', '✅', '🚀'],
      'Инээмсэглэл': ['😀', '😂', '🤣', '😊', '😍', '😎', '🤩', '🥳', '😉', '🥰', '😏', '😇'],
      'Үйлдлүүд': ['✌️', '👌', '💪', '🤝', '🙏', '✋', '👊', '🤜', '🎉', '🎊', '🎈', '🎁'],
      'Бусад': ['💡', '📌', '🔔', '💬', '📢', '🌈', '🍀', '🍎', '🏠', '🚗', '📱', '💻'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.isDarkMode ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Сэтгэгдэл илэрхийлэх',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: emojiGroups.length,
                  itemBuilder: (context, groupIndex) {
                    final groupName = emojiGroups.keys.elementAt(groupIndex);
                    final emojis = emojiGroups[groupName]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.textSecondaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 12.w,
                            crossAxisSpacing: 12.w,
                          ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index];
                            final reaction = _currentBlog.reactions.firstWhere(
                              (r) => r.emoji == emoji,
                              orElse: () => ReactionModel(emoji: emoji, count: 0, users: []),
                            );
                            final isSelected = _userId != null && reaction.users.contains(_userId);

                            return GestureDetector(
                              onTap: () {
                                _toggleReaction(emoji);
                                Navigator.pop(context);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.deepGreen.withOpacity(0.1) 
                                      : context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppColors.deepGreen.withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  emoji,
                                  style: TextStyle(fontSize: 22.sp),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final realIndex = widget.blogs.isNotEmpty ? index % widget.blogs.length : 0;
              setState(() {
                _currentIndex = realIndex;
                _currentBlog = widget.blogs[_currentIndex];
              });
              // Update socket listener for new blog
              _setupSocketListener();
            },
            itemCount: widget.blogs.length > 2 ? 10000 : widget.blogs.length,
            itemBuilder: (context, index) {
              final realIndex = widget.blogs.isNotEmpty ? index % widget.blogs.length : 0;
              final blog = widget.blogs[realIndex];
              
              final isDark = context.isDarkMode;
              final imageUrl = blog.images.isNotEmpty
                  ? (blog.images.first.startsWith('http')
                      ? blog.images.first
                      : '${ApiService.baseUrl}/${blog.images.first}')
                  : '';

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
  expandedHeight: 300.h,
  pinned: false,
  automaticallyImplyLeading: false,
  backgroundColor: context.surfaceColor,
  elevation: 0,
  flexibleSpace: FlexibleSpaceBar(
    centerTitle: true,
    background: Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'blog_image_${blog.id}',
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(Icons.image_outlined, size: 50.sp,
                      color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                )
              : Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.image_outlined, size: 50.sp,
                    color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // ✅ Tap overlay on top of everything
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullImageView(
                      imageUrl: imageUrl,
                      tag: 'blog_image_${blog.id}',
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  ),
),

                  SliverToBoxAdapter(
                    child: Container(
                      color: context.surfaceColor,
                      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppColors.deepGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: AppColors.deepGreen.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'Шинэ мэдээ',
                                  style: TextStyle(
                                    color: AppColors.deepGreen,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14.sp,
                                color: context.textSecondaryColor.withOpacity(0.6),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                DateFormat('yyyy.MM.dd').format(blog.createdAt),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: context.textSecondaryColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          Text(
                            blog.title,
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: context.textPrimaryColor,
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: AppColors.deepGreen,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                width: 8.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: AppColors.deepGreen.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 32.h),
                          
                          Text(
                            blog.content,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: context.textPrimaryColor.withOpacity(0.9),
                              height: 1.8,
                              letterSpacing: 0.1,
                            ),
                          ),
                          
                          SizedBox(height: 40.h),
                          
                          if (blog.reactions.any((r) => r.count > 0)) ...[
                            const Divider(),
                            SizedBox(height: 20.h),
                            Text(
                              'Уншигчдын сэтгэгдэл',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 12.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...blog.reactions.where((r) => r.count > 0).map((reaction) {
                                final isSelected = _userId != null && reaction.users.contains(_userId);
                                return GestureDetector(
                                  onTap: () => _toggleReaction(reaction.emoji),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.deepGreen.withOpacity(0.15) 
                                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppColors.deepGreen 
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          reaction.emoji,
                                          style: TextStyle(fontSize: 16.sp),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '${reaction.count}',
                                          style: TextStyle(
                                            color: isSelected ? AppColors.deepGreen : context.textSecondaryColor,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: _showEmojiPicker,
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                                  decoration: BoxDecoration(
                                    color: blog.reactions.isEmpty
                                        ? AppColors.deepGreen.withOpacity(0.1)
                                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: blog.reactions.isEmpty
                                          ? AppColors.deepGreen.withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_reaction_outlined,
                                        size: 18.sp,
                                        color: blog.reactions.isEmpty
                                            ? AppColors.deepGreen 
                                            : context.textSecondaryColor,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.w),
                                        child: Text(
                                          'Сэтгэгдэл',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1A1F26).withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.deepGreen.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back_rounded,
                color: context.isDarkMode ? Colors.white : AppColors.deepGreen,
                size: 22.sp,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
),

        ],
      ),
    );
  }
}
class _FullImageView extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const _FullImageView({required this.imageUrl, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
