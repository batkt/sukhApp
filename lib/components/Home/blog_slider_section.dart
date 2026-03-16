import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/screens/Home/blog_detail_page.dart';
import 'package:sukh_app/screens/Home/blog_list_page.dart';
import 'package:sukh_app/constants/constants.dart';

class BlogSliderSection extends StatelessWidget {
  const BlogSliderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Mock data for blog posts
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
                      fontWeight: FontWeight.w800,
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
                          fontWeight: FontWeight.w700,
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
          height: 175.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: blogPosts.length,
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
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
                  width: 250.w,
                  margin: EdgeInsets.only(
                    right: 16.w,
                  ),
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
                        // Image with gradient and date tag
                        Stack(
                          children: [
                            Hero(
                              tag: 'blog_image_${post['title']}',
                              child: SizedBox(
                                height: 95.h,
                                width: double.infinity,
                                child: Image.network(
                                  post['image']!,
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
                                  post['date']!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w600,
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
                                  post['title']!,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimaryColor,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  post['description']!,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
