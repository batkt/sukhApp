import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';

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
          final identifier = billingData['billingId'] ?? 
                           billingData['customerId'] ?? 
                           billingData['customerCode'];
          final existingIndex = _billings.indexWhere(
            (b) => (b['billingId'] ?? b['customerId'] ?? b['customerCode']) == identifier,
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
                  billingName: billingData['billingName'] ?? billingData['customerName'],
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
      final billingData = await ApiService.getWalletBillingBills(
        billingId: _selectedBilling!['billingId'],
      );
      if (mounted) {
        setState(() {
          // Extract bills from the response
          if (billingData['newBills'] != null && billingData['newBills'] is List) {
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
      final payments = await ApiService.getWalletBillingPayments(
        billingId: _selectedBilling!['billingId'],
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
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.billerName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tabs
              Container(
                color: Colors.white.withOpacity(0.05),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.goldPrimary,
                  labelColor: AppColors.goldPrimary,
                  unselectedLabelColor: Colors.white70,
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find Billing Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(
                color: AppColors.goldPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Харилцагчийн код оруулах',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _customerCodeController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Харилцагчийн код',
                    hintStyle: TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide(
                        color: AppColors.goldPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _findBillingByCustomerCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Text(
                      'Хайх',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          Text(
            'Миний биллингууд',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          if (_isLoadingBillings)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                ),
              ),
            )
          else if (_billings.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Text(
                  'Биллинг олдсонгүй',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
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
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.goldPrimary.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: isSelected
              ? AppColors.goldPrimary
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
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
          borderRadius: BorderRadius.circular(16.w),
          child: Padding(
            padding: EdgeInsets.all(16.w),
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
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.goldPrimary,
                        size: 24.sp,
                      ),
                  ],
                ),
                if (billing['customerName'] != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Харилцагч: ${billing['customerName']}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
                if (billing['customerAddress'] != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Хаяг: ${billing['customerAddress']}',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.sp,
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
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    if (_bills.isEmpty && !_isLoadingBills) {
      _loadBills();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingBills)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                ),
              ),
            )
          else if (_bills.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Text(
                  'Билл олдсонгүй',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${billAmount.toStringAsFixed(2)}₮',
                style: TextStyle(
                  color: AppColors.goldPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (billPeriod.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Хугацаа: $billPeriod',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
          if (dueDate.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Төлөх огноо: $dueDate',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
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
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    if (_payments.isEmpty && !_isLoadingPayments) {
      _loadPayments();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPayments)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                ),
              ),
            )
          else if (_payments.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Text(
                  'Төлбөрийн түүх олдсонгүй',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${amount.toStringAsFixed(2)}₮',
                style: TextStyle(
                  color: AppColors.goldPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (paymentDate.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Огноо: $paymentDate',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
          if (status.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Төлөв: $status',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
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
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    if (_invoices.isEmpty && !_isLoadingInvoices) {
      _loadInvoices();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingInvoices)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                ),
              ),
            )
          else if (_invoices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.h),
                child: Column(
                  children: [
                    Text(
                      'Нэхэмжлэх олдсонгүй',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
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
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: Colors.black,
                      ),
                      child: Text('Нэхэмжлэх үүсгэх'),
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
    final status = invoice['invoiceStatusText']?.toString() ?? 
                  invoice['invoiceStatus']?.toString() ?? '';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${invoiceAmount.toStringAsFixed(2)}₮',
                style: TextStyle(
                  color: AppColors.goldPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (status.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Төлөв: $status',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createPayment(invoiceId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
              ),
              child: Text('Төлбөр төлөх'),
            ),
          ),
        ],
      ),
    );
  }
}

