import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/screens/Home/blog_detail_page.dart';
import 'package:sukh_app/screens/Home/blog_list_page.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/blog_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/models/blog_model.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:intl/intl.dart';

class BlogSliderSection extends StatefulWidget {
  const BlogSliderSection({super.key});

  /// Trigger a refresh of all active BlogSliderSection instances
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void refresh() {
    refreshNotifier.value++;
  }

  @override
  State<BlogSliderSection> createState() => _BlogSliderSectionState();
}

class _BlogSliderSectionState extends State<BlogSliderSection> {
  List<BlogModel> _blogs = [];
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _loadBlogs();

    // Listen to manual refreshes (from pull-to-refresh on Home or app resume)
    BlogSliderSection.refreshNotifier.addListener(_onRefresh);

    // Listen to real-time socket events when new blogs are added from web
    SocketService.instance.addBlogUpdateListener(_onRefresh);
  }

  void _onRefresh() {
    if (mounted) {
      _loadBlogs(isBackground: true);
    }
  }

  @override
  void dispose() {
    BlogSliderSection.refreshNotifier.removeListener(_onRefresh);
    SocketService.instance.removeBlogUpdateListener(_onRefresh);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs({bool isBackground = false}) async {
    if (!isBackground && _blogs.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (baiguullagiinId == null || baiguullagiinId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final blogs = await BlogService.getBlogs(baiguullagiinId);
      if (mounted) {
        final bool shouldResetPage = _blogs.length != blogs.length;
        setState(() {
          _blogs = blogs;
          _isLoading = false;
        });
        
        // If more than 2 blogs, set initial page to middle for cyclic feel
        if (shouldResetPage && _blogs.length > 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_blogs.length * 500);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 175.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_blogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Мэдээ мэдээлэл',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlogListPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Бүгд',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14.sp,
                        color: AppColors.deepGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 185.h,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: _blogs.length > 2 ? 10000 : _blogs.length,
            itemBuilder: (context, index) {
              final realIndex = _blogs.length > 0 ? index % _blogs.length : 0;
              final blog = _blogs[realIndex];
              final imageUrl = blog.images.isNotEmpty
                  ? (blog.images.first.startsWith('http')
                      ? blog.images.first
                      : '${ApiService.baseUrl}/${blog.images.first}')
                  : '';
              
              // Create compatible map for BlogDetailPage (for now)
              final postMap = {
                'title': blog.title,
                'description': blog.content.length > 100 
                    ? '${blog.content.substring(0, 100)}...' 
                    : blog.content,
                'content': blog.content,
                'date': DateFormat('yyyy.MM.dd').format(blog.createdAt),
                'image': imageUrl,
              };

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailPage(
                        blogs: _blogs,
                        initialIndex: realIndex,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F26) : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : AppColors.deepGreen.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.4)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Hero(
                                tag: 'blog_image_${blog.id}',
                                child: SizedBox(
                                  height: 95.h,
                                  width: double.infinity,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            color: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: isDark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: isDark
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 10.h,
                                left: 10.w,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    postMap['date']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    blog.title,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: context.textPrimaryColor,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5.h),
                                  Text(
                                    postMap['description']!,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: context.textSecondaryColor.withOpacity(0.8),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
