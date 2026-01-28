import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class MedegdelPage extends StatefulWidget {
  const MedegdelPage({super.key});

  @override
  State<MedegdelPage> createState() => _MedegdelPageState();
}

class _MedegdelPageState extends State<MedegdelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Мэдэгдэл'),
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            Container(
              height: 40.h,
              margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.isDarkMode
                      ? AppColors.deepGreen.withOpacity(0.2)
                      : AppColors.deepGreen.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: context.textSecondaryColor,
                indicator: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Бүгд'),
                  Tab(text: 'Санал'),
                  Tab(text: 'Гомдол'),
                  Tab(text: 'Мэдэгдэл'),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(),
                  _buildNotificationList(),
                  _buildNotificationList(),
                  _buildNotificationList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      children: [
        _buildNotificationItem(
          title: 'Санал',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:28',
          status: 'pending',
        ),
        SizedBox(height: 8.h),
        _buildNotificationItem(
          title: 'Шаардлага',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:21',
          status: 'done',
        ),
        SizedBox(height: 8.h),
        _buildNotificationItem(
          title: 'Шаардлага',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:12',
          status: 'done',
        ),
        SizedBox(height: 8.h),
        _buildNotificationItem(
          title: 'Санал',
          description: 'hiuhujdqwldjqdjwdqwdqdq',
          timestamp: '2025-08-29 14:36:15',
          status: 'pending',
        ),
        SizedBox(height: 8.h),
        _buildNotificationItem(
          title: 'Санал',
          description: 'dqwdqw',
          timestamp: '2025-08-26 12:01:06',
          status: 'pending',
        ),
        SizedBox(height: 8.h),
        _buildNotificationItem(
          title: 'Санал',
          description: 'lp',
          timestamp: '2025-08-26 12:00:58',
          status: 'replied',
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String timestamp,
    required String status,
  }) {
    final isPending = status == 'pending';
    final isReplied = status == 'replied';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Хүлээгдэж байна';
      statusIcon = Icons.access_time;
    } else if (isReplied) {
      statusColor = AppColors.success;
      statusText = 'Хариу өгсөн';
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = AppColors.deepGreen;
      statusText = 'Шийдэгдсэн';
      statusIcon = Icons.done_all;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 14.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
