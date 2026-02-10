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

      // Also check if it's an update notification (status changed to done/rejected with tailbar)
      // This handles the case where the backend emits the updated gomdol/sanal itself
      final hasStatus = notification['status'] != null;
      final hasTailbar =
          notification['tailbar'] != null &&
          notification['tailbar'].toString().isNotEmpty;
      final statusValue = notification['status']?.toString().toLowerCase();
      final isStatusUpdate = hasStatus &&
          hasTailbar &&
          (statusValue == 'done' || statusValue == 'rejected');

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
            // Filter tabs
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
                            size: context.responsiveFontSize(
                              small: 36,
                              medium: 40,
                              large: 42,
                              tablet: 48,
                              veryNarrow: 32,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 16,
                            veryNarrow: 10,
                          )),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 17,
                                veryNarrow: 13,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          )),
                          ElevatedButton(
                            onPressed: _loadItems,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsiveSpacing(
                                  small: 16,
                                  medium: 18,
                                  large: 20,
                                  tablet: 24,
                                  veryNarrow: 14,
                                ),
                                vertical: context.responsiveSpacing(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 8,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 10,
                                    medium: 11,
                                    large: 12,
                                    tablet: 14,
                                    veryNarrow: 8,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: TextStyle(fontSize: context.responsiveFontSize(
                                small: 13,
                                medium: 14,
                                large: 15,
                                tablet: 16,
                                veryNarrow: 12,
                              )),
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
                            size: context.responsiveFontSize(
                              small: 48,
                              medium: 52,
                              large: 56,
                              tablet: 64,
                              veryNarrow: 40,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          )),
                          Text(
                            'Гомдол, санал байхгүй',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 12,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 4,
                          )),
                          Text(
                            'Шинэ гомдол эсвэл санал илгээхийн тулд\nдоорх товчийг дарна уу',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 13,
                                medium: 14,
                                large: 15,
                                tablet: 16,
                                veryNarrow: 12,
                              ),
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
                        padding: EdgeInsets.all(context.responsiveSpacing(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 12,
                        )),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildItemCard(item);
                        },
                      ),
                    ),
            ),

            // Fixed bottom button - always visible
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing(
                small: 14,
                medium: 15,
                large: 16,
                tablet: 18,
                veryNarrow: 12,
              )),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/gomdol-sanal-form');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 18,
                        veryNarrow: 12,
                      )),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 10,
                            medium: 11,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 8,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Хүсэлт илгээх',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 12,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
        margin: EdgeInsets.only(right: context.responsiveSpacing(
          small: 6,
          medium: 7,
          large: 8,
          tablet: 10,
          veryNarrow: 5,
        )),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing(
            small: 10,
            medium: 12,
            large: 14,
            tablet: 16,
            veryNarrow: 8,
          ),
          vertical: context.responsiveSpacing(
            small: 6,
            medium: 7,
            large: 8,
            tablet: 10,
            veryNarrow: 5,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepGreen
              : (context.isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white),
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            ),
          ),
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
                fontSize: context.responsiveFontSize(
                  small: 13,
                  medium: 14,
                  large: 15,
                  tablet: 16,
                  veryNarrow: 12,
                ),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: context.responsiveSpacing(
                small: 4,
                medium: 5,
                large: 6,
                tablet: 8,
                veryNarrow: 3,
              )),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing(
                    small: 5,
                    medium: 5,
                    large: 6,
                    tablet: 8,
                    veryNarrow: 4,
                  ),
                  vertical: context.responsiveSpacing(
                    small: 2,
                    medium: 2,
                    large: 3,
                    tablet: 4,
                    veryNarrow: 2,
                  ),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.deepGreen.withOpacity(0.15),
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
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.deepGreen,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
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
        margin: EdgeInsets.only(bottom: context.responsiveSpacing(
          small: 10,
          medium: 11,
          large: 12,
          tablet: 14,
          veryNarrow: 8,
        )),
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
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
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
                    color: isGomdol
                        ? Colors.orange.withOpacity(0.15)
                        : AppColors.deepGreen.withOpacity(0.15),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGomdol
                            ? Icons.report_problem
                            : Icons.lightbulb_outline,
                        size: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 12,
                        ),
                        color: isGomdol ? Colors.orange : AppColors.deepGreen,
                      ),
                      SizedBox(width: context.responsiveSpacing(
                        small: 4,
                        medium: 5,
                        large: 6,
                        tablet: 8,
                        veryNarrow: 3,
                      )),
                      Text(
                        _getDisplayTurul(item.turul),
                        style: TextStyle(
                          color: isGomdol ? Colors.orange : AppColors.deepGreen,
                          fontSize: context.responsiveFontSize(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 15,
                            veryNarrow: 11,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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
                    color: _isStatusDone(item)
                        ? AppColors.success.withOpacity(0.15)
                        : _isStatusRejected(item)
                        ? AppColors.error.withOpacity(0.15)
                        : item.hasReply
                        ? AppColors.success.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
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
                    _getStatusText(item),
                    style: TextStyle(
                      color: _isStatusDone(item)
                          ? AppColors.success
                          : _isStatusRejected(item)
                          ? AppColors.error
                          : item.hasReply
                          ? AppColors.success
                          : Colors.orange,
                      fontSize: context.responsiveFontSize(
                        small: 11,
                        medium: 12,
                        large: 13,
                        tablet: 14,
                        veryNarrow: 10,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            )),
            Text(
              item.title,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: context.responsiveFontSize(
                  small: 15,
                  medium: 16,
                  large: 17,
                  tablet: 18,
                  veryNarrow: 14,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.responsiveSpacing(
              small: 6,
              medium: 7,
              large: 8,
              tablet: 10,
              veryNarrow: 4,
            )),
            Text(
              item.message,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: context.responsiveFontSize(
                  small: 13,
                  medium: 14,
                  large: 15,
                  tablet: 16,
                  veryNarrow: 12,
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.formattedDateTime,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 15,
                      veryNarrow: 11,
                    ),
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
