import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class GomdolSanalProgressScreen extends StatefulWidget {
  const GomdolSanalProgressScreen({super.key});

  @override
  State<GomdolSanalProgressScreen> createState() =>
      _GomdolSanalProgressScreenState();
}

class _GomdolSanalProgressScreenState extends State<GomdolSanalProgressScreen> {
  List<Medegdel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All'; // All, Гомдол, Санал

  Function(Map<String, dynamic>)? _notificationCallback;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _setupSocketListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-establish socket listener when screen comes back into focus
    // This ensures the callback is active even after navigating away and back
    if (_notificationCallback == null) {
      _setupSocketListener();
    }
  }

  void _setupSocketListener() {
    // Listen for real-time notifications via socket
    _notificationCallback = (notification) {
      // Check if it's a reply notification or an update to gomdol/sanal
      final turul = notification['turul']?.toString().toLowerCase() ?? '';
      final isReply = turul == 'хариу' || turul == 'hariu' || turul == 'khariu';
      final isGomdolSanal = turul == 'gomdol' || turul == 'sanal';

      // Also check if it's an update notification (status changed to done with tailbar)
      // This handles the case where the backend emits the updated gomdol/sanal itself
      final hasStatus = notification['status'] != null;
      final hasTailbar =
          notification['tailbar'] != null &&
          notification['tailbar'].toString().isNotEmpty;
      final statusValue = notification['status']?.toString().toLowerCase();
      final isStatusUpdate = hasStatus && hasTailbar && statusValue == 'done';

      if (mounted) {
        // Always refresh when we receive any notification related to gomdol/sanal
        // This ensures we catch both reply notifications and status updates
        if (isReply || isGomdolSanal || isStatusUpdate) {
          // Use a small delay to ensure the backend has updated the data
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadItems();
            }
          });
        }
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
  }

  @override
  void dispose() {
    // Remove socket callback when screen is disposed
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.fetchUserGomdolSanal();
      final medegdelResponse = MedegdelResponse.fromJson(response);

      setState(() {
        _items = medegdelResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Medegdel> get _filteredItems {
    if (_selectedFilter == 'All') {
      return _items;
    }
    return _items
        .where(
          (item) => item.turul.toLowerCase() == _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Гомдол, Санал'),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Action Button for adding new gomdol/sanal
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 6.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.deepGreen,
                      size: 22.sp,
                    ),
                    onPressed: () {
                      context.push('/gomdol-sanal-form');
                    },
                  ),
                ],
              ),
            ),
            // Filter tabs
            Container(
              height: 40.h,
              margin: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 6.h,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterTab('All', 'Бүгд'),
                  _buildFilterTab('gomdol', 'Гомдол'),
                  _buildFilterTab('sanal', 'Санал'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.deepGreen,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.textSecondaryColor,
                            size: 36.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadItems,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            color: context.textSecondaryColor,
                            size: 48.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Гомдол, санал байхгүй',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Шинэ гомдол эсвэл санал илгээхийн тулд\nдээрх + товчийг дарна уу',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 11.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      color: AppColors.deepGreen,
                      child: ListView.builder(
                        padding: EdgeInsets.all(14.w),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildItemCard(item);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    final count = filterKey == 'All'
        ? _items.length
        : _items.where((item) => item.turul == filterKey).length;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepGreen
              : (context.isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.deepGreen
                : (context.isDarkMode
                    ? AppColors.deepGreen.withOpacity(0.2)
                    : AppColors.deepGreen.withOpacity(0.15)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textPrimaryColor,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 5.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.deepGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.deepGreen,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisplayTurul(String turul) {
    final turulLower = turul.toLowerCase();
    if (turulLower == 'gomdol') return 'Гомдол';
    if (turulLower == 'sanal') return 'Санал';
    if (turulLower == 'khariu' ||
        turulLower == 'hariu' ||
        turulLower == 'хариу')
      return 'Хариу';
    if (turulLower == 'app') return 'Мэдэгдэл';
    return turul; // Return original if not recognized
  }

  String _getStatusText(Medegdel item) {
    final status = item.status?.toLowerCase().trim();
    if (status == null || status.isEmpty) {
      if (item.hasReply) {
        return 'Хариу өгсөн';
      }
      return 'Хүлээгдэж байна';
    }
    if (status == 'done') {
      return 'Шийдэгдсэн';
    }
    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан') {
      return 'Татгалзсан';
    }
    if (item.hasReply) {
      return 'Хариу өгсөн';
    }
    return 'Хүлээгдэж байна';
  }

  bool _isStatusDone(Medegdel item) {
    final status = item.status?.toLowerCase().trim();
    return status == 'done';
  }

  bool _isStatusRejected(Medegdel item) {
    final status = item.status?.toLowerCase().trim();
    if (status == null || status.isEmpty) return false;
    return status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'татгалзсан';
  }

  Widget _buildItemCard(Medegdel item) {
    final isGomdol = item.turul.toLowerCase() == 'gomdol';
    final isDone = _isStatusDone(item);
    final isRejected = _isStatusRejected(item);
    return GestureDetector(
      onTap: () {
        context.push('/medegdel-detail', extra: item);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDone
                ? AppColors.success.withOpacity(0.4)
                : isRejected
                ? AppColors.error.withOpacity(0.4)
                : isGomdol
                ? Colors.orange.withOpacity(0.25)
                : AppColors.deepGreen.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isGomdol
                        ? Colors.orange.withOpacity(0.15)
                        : AppColors.deepGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGomdol
                            ? Icons.report_problem
                            : Icons.lightbulb_outline,
                        size: 12.sp,
                        color: isGomdol ? Colors.orange : AppColors.deepGreen,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getDisplayTurul(item.turul),
                        style: TextStyle(
                          color: isGomdol ? Colors.orange : AppColors.deepGreen,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isStatusDone(item)
                        ? AppColors.success.withOpacity(0.15)
                        : _isStatusRejected(item)
                        ? AppColors.error.withOpacity(0.15)
                        : item.hasReply
                        ? AppColors.success.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _getStatusText(item),
                    style: TextStyle(
                      color: _isStatusDone(item)
                          ? AppColors.success
                          : _isStatusRejected(item)
                          ? AppColors.error
                          : item.hasReply
                          ? AppColors.success
                          : Colors.orange,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              item.title,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              item.message,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 11.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.formattedDateTime,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
