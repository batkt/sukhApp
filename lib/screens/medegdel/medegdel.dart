import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
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
              height: context.responsiveSpacing(
                small: 40,
                medium: 44,
                large: 48,
                tablet: 52,
                veryNarrow: 36,
              ),
              margin: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing(
                  small: 14,
                  medium: 15,
                  large: 16,
                  tablet: 18,
                  veryNarrow: 12,
                ),
                vertical: context.responsiveSpacing(
                  small: 8,
                  medium: 10,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 6,
                ),
              ),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  ),
                ),
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
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    ),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontSize: context.responsiveFontSize(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 9,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: context.responsiveFontSize(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 9,
                  ),
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

            SizedBox(height: context.responsiveSpacing(
              small: 8,
              medium: 10,
              large: 12,
              tablet: 14,
              veryNarrow: 6,
            )),

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
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(
          small: 14,
          medium: 15,
          large: 16,
          tablet: 18,
          veryNarrow: 12,
        ),
      ),
      children: [
        _buildNotificationItem(
          title: 'Санал',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:28',
          status: 'pending',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        )),
        _buildNotificationItem(
          title: 'Шаардлага',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:21',
          status: 'done',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        )),
        _buildNotificationItem(
          title: 'Шаардлага',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:12',
          status: 'done',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        )),
        _buildNotificationItem(
          title: 'Санал',
          description: 'hiuhujdqwldjqdjwdqwdqdq',
          timestamp: '2025-08-29 14:36:15',
          status: 'pending',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        )),
        _buildNotificationItem(
          title: 'Санал',
          description: 'dqwdqw',
          timestamp: '2025-08-26 12:01:06',
          status: 'pending',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 8,
          medium: 10,
          large: 12,
          tablet: 14,
          veryNarrow: 6,
        )),
        _buildNotificationItem(
          title: 'Санал',
          description: 'lp',
          timestamp: '2025-08-26 12:00:58',
          status: 'replied',
        ),
        SizedBox(height: context.responsiveSpacing(
          small: 16,
          medium: 18,
          large: 20,
          tablet: 24,
          veryNarrow: 12,
        )),
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
      padding: EdgeInsets.all(context.responsiveSpacing(
        small: 12,
        medium: 14,
        large: 16,
        tablet: 18,
        veryNarrow: 10,
      )),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 12,
            medium: 13,
            large: 14,
            tablet: 16,
            veryNarrow: 10,
          ),
        ),
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
                padding: EdgeInsets.all(context.responsiveSpacing(
                  small: 8,
                  medium: 9,
                  large: 10,
                  tablet: 12,
                  veryNarrow: 6,
                )),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    ),
                  ),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: context.responsiveFontSize(
                    small: 14,
                    medium: 16,
                    large: 18,
                    tablet: 20,
                    veryNarrow: 12,
                  ),
                ),
              ),
              SizedBox(width: context.responsiveSpacing(
                small: 10,
                medium: 11,
                large: 12,
                tablet: 14,
                veryNarrow: 8,
              )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 16,
                          veryNarrow: 11,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing(
                      small: 2,
                      medium: 3,
                      large: 4,
                      tablet: 5,
                      veryNarrow: 2,
                    )),
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 9,
                          medium: 10,
                          large: 11,
                          tablet: 12,
                          veryNarrow: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing(
                    small: 8,
                    medium: 9,
                    large: 10,
                    tablet: 12,
                    veryNarrow: 6,
                  ),
                  vertical: context.responsiveSpacing(
                    small: 4,
                    medium: 5,
                    large: 6,
                    tablet: 8,
                    veryNarrow: 3,
                  ),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    ),
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: context.responsiveFontSize(
                      small: 9,
                      medium: 10,
                      large: 11,
                      tablet: 12,
                      veryNarrow: 8,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          )),
          Text(
            description,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: context.responsiveFontSize(
                small: 11,
                medium: 12,
                large: 13,
                tablet: 15,
                veryNarrow: 10,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
