import 'package:flutter/material.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class BillerDetailScreen extends StatefulWidget {
  final String billerCode;
  final String billerName;
  final String? description;

  const BillerDetailScreen({
    super.key,
    required this.billerCode,
    required this.billerName,
    this.description,
  });

  @override
  State<BillerDetailScreen> createState() => _BillerDetailScreenState();
}

class _BillerDetailScreenState extends State<BillerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _billings = [];
  Map<String, dynamic>? _selectedBilling;

  bool _isLoadingBillings = true;
  final TextEditingController _customerCodeController = TextEditingController();
  bool _isBillingFound = false; // Track if billing is found from search

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadBillings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBillings() async {
    setState(() {
      _isLoadingBillings = true;
    });

    try {
      final billings = await ApiService.getWalletBillingList();
      if (mounted) {
        setState(() {
          _billings = billings;
          _isLoadingBillings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillings = false;
        });
        showGlassSnackBar(
          context,
          message: 'Биллингийн жагсаалт авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _findBillingByCustomerCode() async {
    if (_customerCodeController.text.trim().isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Харилцагчийн код оруулна уу',
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoadingBillings = true;
    });

    try {
      final response = await ApiService.findBillingByBillerAndCustomerCode(
        billerCode: widget.billerCode,
        customerCode: _customerCodeController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          dynamic dataField = response['data'];

          // Handle if data is a List
          Map<String, dynamic> billingData;
          if (dataField is List) {
            if (dataField.isEmpty) {
              throw Exception('Биллингийн мэдээлэл олдсонгүй');
            }
            billingData = Map<String, dynamic>.from(dataField[0] as Map);
          } else if (dataField is Map<String, dynamic>) {
            billingData = dataField;
          } else {
            throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
          }

          // Check if billing already exists in list
          final identifier =
              billingData['billingId'] ??
              billingData['customerId'] ??
              billingData['customerCode'];
          final existingIndex = _billings.indexWhere(
            (b) =>
                (b['billingId'] ?? b['customerId'] ?? b['customerCode']) ==
                identifier,
          );

          if (existingIndex == -1) {
            // Save billing to wallet
            try {
              // If backend already returned a billingId, it means it was auto-saved
              if (billingData['billingId'] != null && billingData['billingId'].toString().isNotEmpty) {
                 showGlassSnackBar(
                  context,
                  message: 'Биллинг амжилттай нэмэгдлээ',
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );
              } else if (billingData['customerId'] != null) {
                // Otherwise manually save it, but don't send billingId if it's new
                await ApiService.saveWalletBilling(
                  billingName: billingData['billingName'] ?? billingData['customerName'] ?? 'Шинэ биллинг',
                  customerId: billingData['customerId'],
                  customerCode: billingData['customerCode'],
                );
                showGlassSnackBar(
                  context,
                  message: 'Биллинг амжилттай нэмэгдлээ',
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );
              }
            } catch (e) {
               showGlassSnackBar(
                context,
                message: 'Биллинг хадгалахад алдаа гарлаа: $e',
                icon: Icons.error,
                iconColor: Colors.red,
              );
              // Fallback to updating UI anyway, but show warning
            }

            setState(() {
              _billings.add(billingData);
              _selectedBilling = billingData;
              _isLoadingBillings = false;
            });
            
          } else {
            setState(() {
              _selectedBilling = _billings[existingIndex];
              _isLoadingBillings = false;
            });
            showGlassSnackBar(
              context,
              message: 'Биллинг аль хэдийн нэмэгдсэн байна',
              icon: Icons.info,
              iconColor: Colors.blue,
            );
          }

          _customerCodeController.clear();
        } else {
          setState(() {
            _isLoadingBillings = false;
          });
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Биллинг олдсонгүй',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillings = false;
        });
        showGlassSnackBar(
          context,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _deleteBilling(Map<String, dynamic> billing) async {
    final billingId = billing['billingId'];
    if (billingId == null) {
      showGlassSnackBar(
        context,
        message: 'Биллингийн ID байхгүй байна',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Биллинг устгах', 
          style: TextStyle(color: context.textPrimaryColor)),
        content: Text('Та энэ биллингийг устгахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor)),
        backgroundColor: context.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Тийм', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoadingBillings = true;
    });

    try {
      await ApiService.removeWalletBilling(billingId: billingId);
      
      // Update local state without fetching all billings again
      if (mounted) {
        setState(() {
          _billings.removeWhere((b) => b['billingId'] == billingId);
          if (_selectedBilling?['billingId'] == billingId) {
            _selectedBilling = null;
          }
          _isLoadingBillings = false;
        });

        showGlassSnackBar(
          context,
          message: 'Биллинг амжилттай устгагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillings = false;
        });
        showGlassSnackBar(
          context,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: widget.billerName),
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Tabs
              Container(
                height: context.responsiveSpacing(
                  small: 40,
                  medium: 42,
                  large: 44,
                  tablet: 48,
                  veryNarrow: 36,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF252525)
                      : const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.deepGreen,
                  indicatorWeight: 2,
                  labelColor: AppColors.deepGreen,
                  unselectedLabelColor: context.textSecondaryColor,
                  labelStyle: TextStyle(
                    fontSize: context.responsiveFontSize(
                      small: 13,
                      medium: 14,
                      large: 15,
                      tablet: 16,
                      veryNarrow: 12,
                    ),
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: context.responsiveFontSize(
                      small: 13,
                      medium: 14,
                      large: 15,
                      tablet: 16,
                      veryNarrow: 12,
                    ),
                  ),
                  tabs: const [Tab(text: 'Биллинг')],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildBillingsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        context.responsiveSpacing(
          small: 14,
          medium: 15,
          large: 16,
          tablet: 18,
          veryNarrow: 10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find Billing Section
          Container(
            padding: EdgeInsets.all(
              context.responsiveSpacing(
                small: 12,
                medium: 13,
                large: 14,
                tablet: 16,
                veryNarrow: 10,
              ),
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFF8F8F8),
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
                color: AppColors.deepGreen.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Харилцагчийн код оруулах',
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
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  ),
                ),
                TextField(
                  controller: _customerCodeController,
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
                  decoration: InputDecoration(
                    hintText: 'Харилцагчийн код',
                    hintStyle: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 13,
                        medium: 14,
                        large: 15,
                        tablet: 16,
                        veryNarrow: 12,
                      ),
                    ),
                    filled: true,
                    fillColor: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(
                        small: 12,
                        medium: 13,
                        large: 14,
                        tablet: 16,
                        veryNarrow: 10,
                      ),
                      vertical: context.responsiveSpacing(
                        small: 10,
                        medium: 11,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 8,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 10,
                          medium: 11,
                          large: 12,
                          tablet: 14,
                          veryNarrow: 8,
                        ),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 10,
                          medium: 11,
                          large: 12,
                          tablet: 14,
                          veryNarrow: 8,
                        ),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.deepGreen.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 10,
                          medium: 11,
                          large: 12,
                          tablet: 14,
                          veryNarrow: 8,
                        ),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.deepGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _findBillingByCustomerCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
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
                      'Хайж нэмэх',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 17,
                          veryNarrow: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: context.responsiveSpacing(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),

          Text(
            'Миний биллингууд',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: context.responsiveFontSize(
                small: 15,
                medium: 16,
                large: 17,
                tablet: 18,
                veryNarrow: 14,
              ),
            ),
          ),

          SizedBox(
            height: context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            ),
          ),

          if (_isLoadingBillings)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  context.responsiveSpacing(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 28,
                    veryNarrow: 16,
                  ),
                ),
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_billings.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  context.responsiveSpacing(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 28,
                    veryNarrow: 16,
                  ),
                ),
                child: Text(
                  'Биллинг олдсонгүй',
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
                ),
              ),
            )
          else
            ..._billings.map((billing) => _buildBillingCard(billing)),
        ],
      ),
    );
  }

  Widget _buildBillingCard(Map<String, dynamic> billing) {
    final isSelected = _selectedBilling?['billingId'] == billing['billingId'];

    return Container(
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 10,
          medium: 11,
          large: 12,
          tablet: 14,
          veryNarrow: 8,
        ),
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.deepGreen.withOpacity(0.1)
            : context.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF8F8F8),
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
          color: isSelected
              ? AppColors.deepGreen
              : AppColors.deepGreen.withOpacity(0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedBilling = billing;
            });
          },
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 13,
              large: 14,
              tablet: 16,
              veryNarrow: 10,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              context.responsiveSpacing(
                small: 12,
                medium: 13,
                large: 14,
                tablet: 16,
                veryNarrow: 10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        billing['billingName']?.toString() ?? 'Биллинг',
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
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.deepGreen,
                        size: context.responsiveFontSize(
                          small: 16,
                          medium: 17,
                          large: 18,
                          tablet: 20,
                          veryNarrow: 14,
                        ),
                      ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteBilling(billing),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (billing['customerName'] != null) ...[
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 6,
                      medium: 7,
                      large: 8,
                      tablet: 10,
                      veryNarrow: 4,
                    ),
                  ),
                  Text(
                    'Харилцагч: ${billing['customerName']}',
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
                if (billing['customerAddress'] != null) ...[
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 3,
                      medium: 4,
                      large: 5,
                      tablet: 6,
                      veryNarrow: 2,
                    ),
                  ),
                  Text(
                    'Хаяг: ${billing['customerAddress']}',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 11,
                        medium: 12,
                        large: 13,
                        tablet: 14,
                        veryNarrow: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
