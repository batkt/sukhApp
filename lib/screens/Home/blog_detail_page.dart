import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';

class BlogDetailPage extends StatefulWidget {
  final Map<String, String> post;

  const BlogDetailPage({super.key, required this.post});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  // Start with empty reactions
  final Map<String, int> _reactions = {};
  
  // Track multiple concurrent user reactions
  final Set<String> _userReactions = {};

  void _toggleReaction(String emoji) {
    setState(() {
      if (_userReactions.contains(emoji)) {
        // Remove reaction
        _userReactions.remove(emoji);
        _reactions[emoji] = (_reactions[emoji] ?? 1) - 1;
        if (_reactions[emoji] == 0) _reactions.remove(emoji);
      } else {
        // Add reaction
        _userReactions.add(emoji);
        _reactions[emoji] = (_reactions[emoji] ?? 0) + 1;
      }
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
                  fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w700,
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
                            final isSelected = _userReactions.contains(emoji);
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
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Simplified & Immersive Header
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
                        tag: 'blog_image_${widget.post['title']}',
                        child: Image.network(
                          widget.post['image'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.image_outlined,
                              size: 50.sp,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
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
                    ],
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Container(
                  color: context.surfaceColor,
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Date
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
                                fontWeight: FontWeight.w700,
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
                            widget.post['date'] ?? '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.textSecondaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Title
                      Text(
                        widget.post['title'] ?? '',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimaryColor,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Styled Divider
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
                      
                      // Content Text
                      Text(
                        widget.post['content'] ?? widget.post['description'] ?? '',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: context.textPrimaryColor.withOpacity(0.9),
                          height: 1.8,
                          letterSpacing: 0.1,
                        ),
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // Reactions Section
                      if (_reactions.isNotEmpty || _userReactions.isNotEmpty) ...[
                        const Divider(),
                        SizedBox(height: 20.h),
                        Text(
                          'Уншигчдын сэтгэгдэл',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
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
                          ..._reactions.entries.map((entry) {
                            final isSelected = _userReactions.contains(entry.key);
                            return GestureDetector(
                              onTap: () => _toggleReaction(entry.key),
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
                                      entry.key,
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        color: isSelected ? AppColors.deepGreen : context.textSecondaryColor,
                                        fontSize: 13.sp,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Add reaction button
                          GestureDetector(
                            onTap: _showEmojiPicker,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                              decoration: BoxDecoration(
                                color: _userReactions.isEmpty && _reactions.isEmpty 
                                    ? AppColors.deepGreen.withOpacity(0.1)
                                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: _userReactions.isEmpty && _reactions.isEmpty 
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
                                    color: _userReactions.isEmpty && _reactions.isEmpty 
                                        ? AppColors.deepGreen 
                                        : context.textSecondaryColor,
                                  ),
                                  if (_userReactions.isEmpty && _reactions.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: Text(
                                        'Сэтгэгдэл',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
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
          ),
          
          // Floating Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                child: Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1F26).withOpacity(0.9) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.08) 
                          : AppColors.deepGreen.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white : AppColors.deepGreen,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'Мэдээлэл',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          'Мэдээ мэдээлэл',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ),
                    ],
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
