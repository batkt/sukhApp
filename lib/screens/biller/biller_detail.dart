import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _invoices = [];

  bool _isLoadingBillings = true;
  bool _isLoadingBills = false;
  bool _isLoadingPayments = false;
  bool _isLoadingInvoices = false;
  final TextEditingController _customerCodeController = TextEditingController();
  bool _hasShownBillingNotFoundError =
      false; // Track if error was already shown

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

          // Check if billing already exists in list (use customerId or customerCode if billingId doesn't exist)
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
            setState(() {
              _billings.add(billingData);
              _selectedBilling = billingData;
              _isLoadingBillings = false;
            });

            // Save billing only if billingId exists (might need to find billing first)
            if (billingData['billingId'] != null) {
              try {
                await ApiService.saveWalletBilling(
                  billingId: billingData['billingId'],
                  billingName:
                      billingData['billingName'] ?? billingData['customerName'],
                  customerId: billingData['customerId'],
                  customerCode: billingData['customerCode'],
                );
              } catch (e) {
                // Error saving billing
              }
            }
          } else {
            setState(() {
              _selectedBilling = billingData;
              _isLoadingBillings = false;
            });
          }

          _customerCodeController.clear();
          _tabController.animateTo(1);
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
          message: 'Биллинг хайхад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadBills() async {
    if (_selectedBilling == null) return;

    setState(() {
      _isLoadingBills = true;
    });

    try {
      // Check if billingId exists, if not try to find it using customerId
      String? billingId = _selectedBilling!['billingId']?.toString();

      if (billingId == null || billingId.isEmpty) {
        // Try to find billing by customerId
        final customerId = _selectedBilling!['customerId']?.toString();
        if (customerId != null && customerId.isNotEmpty) {
          try {
            final billingResponse = await ApiService.findBillingByCustomerId(
              customerId: customerId,
            );
            if (billingResponse['success'] == true &&
                billingResponse['data'] != null) {
              final billingData = billingResponse['data'] is Map
                  ? billingResponse['data'] as Map<String, dynamic>
                  : null;
              billingId = billingData?['billingId']?.toString();

              // Update selected billing with billingId if found
              if (billingId != null && billingId.isNotEmpty) {
                setState(() {
                  _selectedBilling!['billingId'] = billingId;
                });
              }
            } else {
              // Billing not found - this is expected for new customers
              print('Billing not yet created for customerId: $customerId');
            }
          } catch (e) {
            // Check if it's a "not found" error vs actual error
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('олдсонгүй') ||
                errorMsg.contains('not found')) {
              // Expected case - billing doesn't exist yet
              print(
                'Billing not yet created for customerId: $customerId (expected)',
              );
            } else {
              // Unexpected error
              print('Unexpected error finding billingId by customerId: $e');
            }
          }
        }
      }

      // If we still don't have billingId, we can't load bills
      if (billingId == null || billingId.isEmpty) {
        // Show a user-friendly message that billing needs to be created first
        if (mounted) {
          setState(() {
            _isLoadingBills = false;
          });
          // Only show error once
          if (!_hasShownBillingNotFoundError) {
            _hasShownBillingNotFoundError = true;
            showGlassSnackBar(
              context,
              message: 'Төлбөр олдсонгүй',
              icon: Icons.info_outline,
              iconColor: Colors.orange,
            );
          }
        }
        return;
      }

      final billingData = await ApiService.getWalletBillingBills(
        billingId: billingId,
      );
      if (mounted) {
        setState(() {
          // Extract bills from the response
          if (billingData['newBills'] != null &&
              billingData['newBills'] is List) {
            _bills = List<Map<String, dynamic>>.from(billingData['newBills']);
          } else {
            _bills = [];
          }
          _isLoadingBills = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBills = false;
        });
        showGlassSnackBar(
          context,
          message: 'Биллүүд авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadPayments() async {
    if (_selectedBilling == null) return;

    setState(() {
      _isLoadingPayments = true;
    });

    try {
      // Check if billingId exists
      String? billingId = _selectedBilling!['billingId']?.toString();

      if (billingId == null || billingId.isEmpty) {
        // Try to find billing by customerId
        final customerId = _selectedBilling!['customerId']?.toString();
        if (customerId != null && customerId.isNotEmpty) {
          try {
            final billingResponse = await ApiService.findBillingByCustomerId(
              customerId: customerId,
            );
            if (billingResponse['success'] == true &&
                billingResponse['data'] != null) {
              final billingData = billingResponse['data'] is Map
                  ? billingResponse['data'] as Map<String, dynamic>
                  : null;
              billingId = billingData?['billingId']?.toString();

              // Update selected billing with billingId if found
              if (billingId != null && billingId.isNotEmpty) {
                setState(() {
                  _selectedBilling!['billingId'] = billingId;
                });
              }
            } else {
              // Billing not found - this is expected for new customers
              // Don't print - this is expected for new customers
            }
          } catch (e) {
            // Check if it's a "not found" error vs actual error
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('олдсонгүй') ||
                errorMsg.contains('not found') ||
                errorMsg.contains('төлбөр олдсонгүй')) {
              // Expected case - billing doesn't exist yet
              // Only print once to avoid spam
              if (!_hasShownBillingNotFoundError) {
                _hasShownBillingNotFoundError = true;
                // Don't print - this is expected for new customers
              }
            } else {
              // Unexpected error - only print once
              if (!_hasShownBillingNotFoundError) {
                _hasShownBillingNotFoundError = true;
                print('Unexpected error finding billingId by customerId: $e');
              }
            }
          }
        }
      }

      // If we still don't have billingId, we can't load payments
      if (billingId == null || billingId.isEmpty) {
        // Show a user-friendly message that billing needs to be created first
        if (mounted) {
          setState(() {
            _isLoadingPayments = false;
          });
          // Only show error once
          if (!_hasShownBillingNotFoundError) {
            _hasShownBillingNotFoundError = true;
            showGlassSnackBar(
              context,
              message: 'Төлбөр олдсонгүй',
              icon: Icons.info_outline,
              iconColor: Colors.orange,
            );
          }
        }
        return;
      }

      final payments = await ApiService.getWalletBillingPayments(
        billingId: billingId,
      );
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
        });
        showGlassSnackBar(
          context,
          message: 'Төлбөрийн түүх авахад алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _createInvoice(List<String> billIds) async {
    if (_selectedBilling == null || billIds.isEmpty) return;

    try {
      final response = await ApiService.createWalletInvoice(
        billingId: _selectedBilling!['billingId'],
        billIds: billIds,
        vatReceiveType: 'CITIZEN',
      );

      if (mounted) {
        if (response['success'] == true) {
          showGlassSnackBar(
            context,
            message: 'Нэхэмжлэх амжилттай үүсгэлээ',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          _tabController.animateTo(3);
          _loadInvoices();
        } else {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Нэхэмжлэх үүсгэхэд алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Нэхэмжлэх үүсгэхэд алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadInvoices() async {
    // This would need a separate endpoint to list invoices
    // For now, we'll show a placeholder
    setState(() {
      _isLoadingInvoices = false;
      _invoices = [];
    });
  }

  Future<void> _createPayment(String invoiceId) async {
    try {
      final response = await ApiService.createWalletPayment(
        invoiceId: invoiceId,
      );

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final paymentData = response['data'];
          final paymentUrl = paymentData['paymentUrl'];

          if (paymentUrl != null) {
            // Open payment URL
            // You might want to use url_launcher here
            showGlassSnackBar(
              context,
              message: 'Төлбөрийн холбоос: $paymentUrl',
              icon: Icons.payment,
              iconColor: Colors.green,
            );
          } else {
            showGlassSnackBar(
              context,
              message: 'Төлбөр амжилттай үүсгэлээ',
              icon: Icons.check_circle,
              iconColor: Colors.green,
            );
          }
        } else {
          showGlassSnackBar(
            context,
            message: response['message'] ?? 'Төлбөр үүсгэхэд алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Төлбөр үүсгэхэд алдаа гарлаа: $e',
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
                height: 40.h,
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
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Биллинг'),
                    Tab(text: 'Билл'),
                    Tab(text: 'Төлбөр'),
                    Tab(text: 'Нэхэмжлэх'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillingsTab(),
                    _buildBillsTab(),
                    _buildPaymentsTab(),
                    _buildInvoicesTab(),
                  ],
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
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find Billing Section
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12.r),
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _customerCodeController,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Харилцагчийн код',
                    hintStyle: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 10.sp,
                    ),
                    filled: true,
                    fillColor: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.deepGreen.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.deepGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _findBillingByCustomerCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Хайх',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          Text(
            'Миний биллингууд',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 10.h),

          if (_isLoadingBillings)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_billings.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'Биллинг олдсонгүй',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
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
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.deepGreen.withOpacity(0.1)
            : context.isDarkMode
                ? const Color(0xFF252525)
                : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
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
            _tabController.animateTo(1);
            _loadBills();
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
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
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.deepGreen,
                        size: 16.sp,
                      ),
                  ],
                ),
                if (billing['customerName'] != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'Харилцагч: ${billing['customerName']}',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
                if (billing['customerAddress'] != null) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Хаяг: ${billing['customerAddress']}',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 9.sp,
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

  Widget _buildBillsTab() {
    if (_selectedBilling == null) {
      return Center(
        child: Text(
          'Биллинг сонгоно уу',
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
        ),
      );
    }

    if (_bills.isEmpty && !_isLoadingBills) {
      _loadBills();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingBills)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_bills.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'Билл олдсонгүй',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            )
          else
            ..._bills.map((bill) => _buildBillCard(bill)),
        ],
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final billAmount = bill['billAmount']?.toDouble() ?? 0.0;
    final dueDate = bill['dueDate']?.toString() ?? '';
    final billNo = bill['billNo']?.toString() ?? '';
    final billPeriod = bill['billPeriod']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.1),
          width: 1,
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
                  billNo,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${billAmount.toStringAsFixed(0)}₮',
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (billPeriod.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Хугацаа: $billPeriod',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
          if (dueDate.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              'Төлөх огноо: $dueDate',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 9.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_selectedBilling == null) {
      return Center(
        child: Text(
          'Биллинг сонгоно уу',
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
        ),
      );
    }

    if (_payments.isEmpty && !_isLoadingPayments) {
      _loadPayments();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPayments)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_payments.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'Төлбөрийн түүх олдсонгүй',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            )
          else
            ..._payments.map((payment) => _buildPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final paymentDate = payment['paymentDate']?.toString() ?? '';
    final status = payment['status']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.1),
          width: 1,
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
                  'Төлбөр',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)}₮',
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (paymentDate.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Огноо: $paymentDate',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
          if (status.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              'Төлөв: $status',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 9.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    if (_selectedBilling == null) {
      return Center(
        child: Text(
          'Биллинг сонгоно уу',
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
        ),
      );
    }

    if (_invoices.isEmpty && !_isLoadingInvoices) {
      _loadInvoices();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingInvoices)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: CircularProgressIndicator(
                  color: AppColors.deepGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_invoices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      'Нэхэмжлэх олдсонгүй',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: () {
                        if (_bills.isNotEmpty) {
                          final billIds = _bills
                              .map((b) => b['billId']?.toString())
                              .where((id) => id != null)
                              .cast<String>()
                              .toList();
                          if (billIds.isNotEmpty) {
                            _createInvoice(billIds);
                          }
                        }
                      },
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
                        'Нэхэмжлэх үүсгэх',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._invoices.map((invoice) => _buildInvoiceCard(invoice)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final invoiceAmount = invoice['invoiceAmount']?.toDouble() ?? 0.0;
    final invoiceId = invoice['invoiceId']?.toString() ?? '';
    final status =
        invoice['invoiceStatusText']?.toString() ??
        invoice['invoiceStatus']?.toString() ??
        '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.1),
          width: 1,
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
                  invoiceId,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${invoiceAmount.toStringAsFixed(0)}₮',
                style: TextStyle(
                  color: AppColors.deepGreen,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (status.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Төлөв: $status',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createPayment(invoiceId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Төлбөр төлөх',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
