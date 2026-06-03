import 'package:flutter/material.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/components/Home/biller_utils.dart';

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

class _BillerDetailScreenState extends State<BillerDetailScreen> {
  List<Map<String, dynamic>> _billings = [];
  bool _isLoadingBillings = true;
  bool _isSearching = false;
  final TextEditingController _customerCodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBillings();
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBillings() async {
    setState(() => _isLoadingBillings = true);
    try {
      final billings = await ApiService.getWalletBillingList();
      final filtered = billings.where((b) {
        final bCode = b['billerCode']?.toString().trim().toUpperCase() ?? '';
        final bName = b['billerName']?.toString().trim().toUpperCase() ?? '';
        final wCode = widget.billerCode.trim().toUpperCase();
        final wName = widget.billerName.trim().toUpperCase();
        return bCode == wCode ||
            bName == wName ||
            (bCode.isNotEmpty && wCode.isNotEmpty && (bCode.contains(wCode) || wCode.contains(bCode))) ||
            (bName.isNotEmpty && wName.isNotEmpty && (bName.contains(wName) || wName.contains(bName)));
      }).toList();
      if (mounted) setState(() { _billings = filtered; _isLoadingBillings = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBillings = false);
        _showSnack('Жагсаалт авахад алдаа: $e', Colors.red);
      }
    }
  }

  Future<void> _findBilling() async {
    final code = _customerCodeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Харилцагчийн код оруулна уу', Colors.orange);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await ApiService.findBillingByBillerAndCustomerCode(
        billerCode: widget.billerCode,
        customerCode: code,
      );
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        dynamic dataField = response['data'];
        Map<String, dynamic> billingData;
        if (dataField is List) {
          if (dataField.isEmpty) throw Exception('Биллинг олдсонгүй');
          billingData = Map<String, dynamic>.from(dataField[0] as Map);
        } else {
          billingData = Map<String, dynamic>.from(dataField as Map);
        }

        final identifier = billingData['billingId'] ?? billingData['customerId'] ?? billingData['customerCode'];
        final exists = _billings.any((b) => (b['billingId'] ?? b['customerId'] ?? b['customerCode']) == identifier);

        if (!exists) {
          if (billingData['customerId'] != null && billingData['billingId'] == null) {
            await ApiService.saveWalletBilling(
              billingName: billingData['billingName'] ?? billingData['customerName'] ?? 'Шинэ биллинг',
              customerId: billingData['customerId'],
              customerCode: billingData['customerCode'],
            );
          }
          setState(() => _billings.add(billingData));
          _showSnack('Биллинг амжилттай нэмэгдлээ', AppColors.deepGreen);
        } else {
          _showSnack('Биллинг аль хэдийн нэмэгдсэн байна', Colors.blue);
        }
        _customerCodeController.clear();
        _focusNode.unfocus();
      } else {
        _showSnack(response['message'] ?? 'Биллинг олдсонгүй', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _deleteBilling(Map<String, dynamic> billing) async {
    final billingId = billing['billingId'];
    if (billingId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Биллинг устгах', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Та энэ биллингийг устгахдаа итгэлтэй байна уу?', style: TextStyle(color: context.textSecondaryColor, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Устгах', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.removeWalletBilling(billingId: billingId);
      if (mounted) {
        setState(() => _billings.removeWhere((b) => b['billingId'] == billingId));
        _showSnack('Биллинг устгагдлаа', AppColors.deepGreen);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    showGlassSnackBar(context, message: msg,
        icon: color == Colors.red ? Icons.error : Icons.check_circle,
        iconColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.deepGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                ClipRect(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: BillerUtils.buildBillerLogo(
                      widget.billerName,
                      transformedName: BillerUtils.transformBillerName(widget.billerName),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    BillerUtils.transformBillerName(widget.billerName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Харилцагчийн кодоор хайх',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customerCodeController,
                                focusNode: _focusNode,
                                style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Жишээ: 123456789',
                                  hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF4F4F4),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.deepGreen, width: 1.5),
                                  ),
                                ),
                                onSubmitted: (_) => _findBilling(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _isSearching ? null : _findBilling,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.deepGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Billings header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Миний биллингууд',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      if (_billings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_billings.length}',
                              style: TextStyle(fontSize: 12, color: AppColors.deepGreen, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_isLoadingBillings)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.deepGreen, strokeWidth: 2),
                    ))
                  else if (_billings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40,
                              color: context.textSecondaryColor.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text('Биллинг байхгүй байна',
                              style: TextStyle(color: context.textSecondaryColor, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Кодоор хайж нэмнэ үү',
                              style: TextStyle(color: context.textSecondaryColor.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_billings.length, (i) => _buildBillingRow(_billings[i])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(Map<String, dynamic> billing) {
    final name = billing['billingName']?.toString() ?? billing['customerName']?.toString() ?? 'Биллинг';
    final code = billing['customerCode']?.toString() ?? billing['customerId']?.toString() ?? '';
    final address = billing['customerAddress']?.toString();
    final isDark = context.isDarkMode;

    return Dismissible(
      key: Key(billing['billingId']?.toString() ?? name),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteBilling(billing);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'Б',
                  style: TextStyle(
                    color: AppColors.deepGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Код: $code',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                  ],
                  if (address != null) ...[
                    const SizedBox(height: 1),
                    Text(address,
                        style: TextStyle(color: context.textSecondaryColor.withOpacity(0.7), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            // Delete
            GestureDetector(
              onTap: () => _deleteBilling(billing),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
