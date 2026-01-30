import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

/// Show help modal with frequently asked questions
Future<void> showHelpModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return HelpModal();
    },
  ).then((_) {
    // Modal was closed
  });
}

class HelpModal extends StatefulWidget {
  const HelpModal({super.key});

  @override
  State<HelpModal> createState() => _HelpModalState();
}

class _HelpModalState extends State<HelpModal> {
  final TextEditingController _searchController = TextEditingController();
  List<FAQItem> _filteredFAQs = [];

  final List<FAQItem> faqs = [
    FAQItem(
      question: 'Нэхэмжлэх хэрхэн төлөх вэ?',
      answer:
          'Нэхэмжлэх хуудсанд ороод төлөх нэхэмжлэлээ сонгоод "Төлбөр төлөх" товч дараад банкны аппликешнээр төлнө. QPay хэтэвч ашиглах бол QR кодыг уншуулна уу.',
    ),
    FAQItem(
      question: 'И-Баримт хэрхэн харах вэ?',
      answer:
          'Төлөгдсөн нэхэмжлэх дээр "Баримт харах" товч дараад И-Баримтыг харж болно. QR код болон бүх мэдээлэл харагдана.',
    ),
    FAQItem(
      question: 'Гэрээний мэдээлэл хэрхэн харах вэ?',
      answer:
          'Гол цэснээс "Гэрээ" сонгоод бүх гэрээний мэдээллийг харж болно. Хэрэв олон гэрээ байвал бүгдийг харах боломжтой.',
    ),
    FAQItem(
      question: 'Нууц үгээ мартсан бол яах вэ?',
      answer:
          'Нэвтрэх хуудас дээр "Нууц үг сэргээх" товч дараад утасны дугаараа оруулна уу. Нууц үг сэргээх код илгээгдэнэ.',
    ),
    FAQItem(
      question: 'Төлбөрийн мэдээлэл хэрхэн шалгах вэ?',
      answer:
          'Гол хуудас дээр "Төлөх" товч дараад төлбөрийн мэдээллийг харж болно. Төлөх ёстой дүн, огноо зэрэг мэдээлэл харагдана.',
    ),
    FAQItem(
      question: 'Банкны апп суулгаагүй бол яах вэ?',
      answer:
          'Банкны апп суулгаагүй бол QR кодыг хуулж авах эсвэл апп татах боломжтой. QPay хэтэвч ашиглах бол QR кодыг уншуулна уу.',
    ),
    FAQItem(
      question: 'Төлбөр төлсөн боловч статус шинэчлэгдээгүй бол?',
      answer:
          'Төлбөр төлсний дараа "Төлбөр шалгах" товч дараад статусыг шинэчлэнэ. Хэрэв асуудал гарвал СӨХ-тэй холбогдоно уу.',
    ),
    FAQItem(
      question: 'Олон гэрээ байвал хэрхэн солих вэ?',
      answer:
          'Нэхэмжлэх хуудас дээр гэрээний дугаарын хажууд солих товч байна. Түүнийг дараад өөр гэрээ сонгоно уу.',
    ),
    FAQItem(
      question: 'Хувийн мэдээлэл хэрхэн засах вэ?',
      answer:
          'Гол цэснээс "Хувийн мэдээлэл" сонгоно уу. Гэхдээ одоогоор мэдээлэл засах боломжгүй байна. СӨХ-тэй холбогдоод засах хэрэгтэй.',
    ),
    FAQItem(
      question: 'Мэдэгдэл хэрхэн идэвхжүүлэх вэ?',
      answer:
          'Тохиргоо хуудас дээр мэдэгдлийн тохиргоог идэвхжүүлнэ. Төлбөрийн мэдэгдэл, нэхэмжлэх мэдэгдэл зэрэг сонгох боломжтой.',
    ),
    FAQItem(
      question: 'Утасны дугаар хэрхэн засах вэ?',
      answer:
          'Одоогоор утасны дугаар засах боломжгүй байна. СӨХ-тэй холбогдоод утасны дугаараа засах хэрэгтэй.',
    ),
    FAQItem(
      question: 'Төлбөр төлсний дараа хэр удаан шинэчлэгдэх вэ?',
      answer:
          'Төлбөр төлсний дараа "Төлбөр шалгах" товч дараад шууд шинэчлэгдэнэ. Хэрэв шинэчлэгдэхгүй бол хэдэн минут хүлээгээд дахин оролдоно уу.',
    ),
    FAQItem(
      question: 'QPay хэтэвч ашиглахдаа яах вэ?',
      answer:
          'QPay хэтэвч сонгоод QR кодыг уншуулна уу. Төлбөр төлсний дараа "Төлбөр шалгах" товч дараад статусыг шинэчлэнэ.',
    ),
    FAQItem(
      question: 'Апп ажиллахгүй байвал яах вэ?',
      answer:
          'Аппыг дахин ачааллаад үзнэ үү. Хэрэв асуудал үргэлжилвэл СӨХ-тэй холбогдоно уу. Интернэт холболт шалгана уу.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = faqs;
    _searchController.addListener(_filterFAQs);
    // Haptic feedback when help modal opens
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {}
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFAQs);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFAQs = faqs;
      } else {
        _filteredFAQs = faqs.where((faq) {
          return faq.question.toLowerCase().contains(query) ||
              faq.answer.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // For tablets/iPads, limit width and center the modal
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return Center(
      child: Container(
        width: modalWidth,
        height: context.responsiveModalHeight(
          small: 0.85,
          medium: 0.80,
          large: 0.75,
          tablet: 0.70,
        ),
        constraints: BoxConstraints(
          maxHeight: context.isTablet ? 800.h : double.infinity,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0e27),
          borderRadius: isTablet
              ? BorderRadius.circular(context.responsiveBorderRadius(
                  small: 30,
                  medium: 35,
                  large: 40,
                  tablet: 45,
                ))
              : BorderRadius.only(
                  topLeft: Radius.circular(context.responsiveBorderRadius(
                    small: 30,
                    medium: 35,
                    large: 40,
                    tablet: 45,
                  )),
                  topRight: Radius.circular(context.responsiveBorderRadius(
                    small: 30,
                    medium: 35,
                    large: 40,
                    tablet: 45,
                  )),
                ),
          boxShadow: isTablet
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
      child: OptimizedGlass(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
        opacity: 0.06,
        child: Column(
          children: [
            // Handle bar
            Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.w),
                ),
            ),
            // Header
            Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe6ff00).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                          child: Icon(
                            Icons.help_outline,
                            color: const Color(0xFFe6ff00),
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Тусламж',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Түгээмэл асуултууд',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            // Search bar
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Хайх...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.6),
                      size: 20.sp,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.6),
                              size: 20.sp,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.w,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.w,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide(
                        color: const Color(0xFFe6ff00),
                        width: 2.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // FAQ List
              Expanded(
                child: _filteredFAQs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 48.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Хайлтын үр дүн олдсонгүй',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Өөр түлхүүр үг ашиглаж үзнэ үү',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        itemCount: _filteredFAQs.length,
                        itemBuilder: (context, index) {
                          return _buildFAQItem(_filteredFAQs[index]);
                        },
                      ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        iconColor: const Color(0xFFe6ff00),
        collapsedIconColor: Colors.white.withOpacity(0.6),
        title: Text(
          faq.question,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          SizedBox(height: 12.h),
          Text(
            faq.answer,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
