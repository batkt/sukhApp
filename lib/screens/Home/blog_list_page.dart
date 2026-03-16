import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/Home/blog_detail_page.dart';

class BlogListPage extends StatelessWidget {
  const BlogListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Same mock data as BlogSliderSection
    final List<Map<String, String>> blogPosts = [
      {
        'title': 'Шинэ оны мэнд хүргэе!',
        'description': 'Айл өрх бүрд аз жаргал, эрүүл энхийг хүсье.',
        'content': 'Эрхэм хүндэт оршин суугчид аа,\n\nТа бүхэндээ айлан ирж буй шинэ оны гал халуун мэндийг хүргэе! Ирж буй шинэ ондоо аз жаргал, эрүүл энх, амжилт бүтээлээр дүүрэн байхыг хүсэн ерөөе.\n\nБидний хамтын ажиллагаа цаашид улам өргөжин тэлэх болтугай!',
        'date': '2025.01.01',
        'image': 'https://images.unsplash.com/photo-1546272989-40c92939c6c2?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'СӨХ-н төлбөр төлөх шинэ боломж',
        'description': 'Та одоо апп-аараа дамжуулан илүү хурдан төлөлт хийх боломжтой боллоо.',
        'content': 'Эрхэм оршин суугчид аа,\n\nТа одоо апп-аараа дамжуулан СӨХ-н төлбөр болон бусад төлбөрүүдээ улам хурдан бөгөөд хялбар аргаар төлөх боломжтой боллоо.\n\n- QPay болон банкны апп-аар шууд төлнө.\n- Төлбөр хийгдсэн даруйд баримт үүснэ.\n- Сарын хураамж болон задаргаа тодорхой харагдана.',
        'date': '2024.11.15',
        'image': 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Дулааны улирлын бэлтгэл ажил',
        'description': 'Оршин суугчдын анхааралд, дулааны улирал эхэлж буйтай холбоотой мэдээлэл.',
        'content': 'Оршин суугчдын анхааралд,\n\nЭнэ амралтын өдрүүдээр гадна пасадны дулааны болон дээврийн засварын ажлууд 2-р ээлжээр эхлэх гэж байна. \nМашины зогсоолын орчимд анхаарал болгоомжтой байхыг хүсье.\n\nБаярлалаа!',
        'date': '2024.10.23',
        'image': 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=600&auto=format&fit=crop',
      },
    ];

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          // Floating Header matching Home style
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Container(
                height: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
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
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Бүх мэдээлэл',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        'Мэдээ мэдээлэл',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB1F3B7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogDetailPage(post: post),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16.h),
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
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Image
                        Hero(
                          tag: 'blog_image_list_${post['title']}',
                          child: Container(
                            width: 110.w,
                            height: 110.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24.r),
                                bottomLeft: Radius.circular(24.r),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(post['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Right Content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.deepGreen.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        post['date']!,
                                        style: TextStyle(
                                          color: AppColors.deepGreen,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  post['title']!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimaryColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  post['description']!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: context.textSecondaryColor,
                                    height: 1.3,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
