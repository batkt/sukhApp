import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/ajiltan_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/components/Nekhemjlekh/filter_tabs.dart';
import 'package:sukh_app/components/Nekhemjlekh/payment_section.dart';
import 'package:sukh_app/components/Nekhemjlekh/invoice_card.dart';
import 'package:sukh_app/components/Nekhemjlekh/contract_selection_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/bank_selection_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/payment_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/nekhemjlekh_merge_util.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class NekhemjlekhPage extends StatefulWidget {
  const NekhemjlekhPage({super.key});

  @override
  State<NekhemjlekhPage> createState() => _NekhemjlekhPageState();
}

class _NekhemjlekhPageState extends State<NekhemjlekhPage>
    with WidgetsBindingObserver {
  List<NekhemjlekhItem> invoices = [];
  bool isLoading = true;
  String? errorMessage;
  List<QPayBank> qpayBanks = [];
  bool isLoadingQPay = false;
  List<Map<String, dynamic>> availableContracts = [];
  String? selectedGereeniiDugaar;
  String? selectedContractDisplay;
  double? _contractUldegdel; // Authoritative balance from backend (globalUldegdel)
  String selectedFilter = 'All'; // All, Overdue, Paid, Due this month, Pending
  List<String> selectedInvoiceIds = [];
  String? qpayInvoiceId;
  String? qpayQrImage;
  String? qpayQrImageOwnOrg;
  String? qpayQrImageWallet;
  String contactPhone = '';

  Function(Map<String, dynamic>)? _notificationCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('📬📬📬 NEKHEMJLEKH PAGE: initState called!');
    _loadNekhemjlekh();
    print(
      '📬📬📬 NEKHEMJLEKH PAGE: About to call _connectSocketAndSetupListener',
    );
    _connectSocketAndSetupListener();
    print('📬📬📬 NEKHEMJLEKH PAGE: _connectSocketAndSetupListener called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-establish socket listener when screen comes back into focus
    if (_notificationCallback == null) {
      _connectSocketAndSetupListener();
    }
  }

  Future<void> _connectSocketAndSetupListener() async {
    print('📬📬📬 NEKHEMJLEKH: _connectSocketAndSetupListener STARTED!');
    print('📬 Nekhemjlekh: Setting up socket connection and listener');

    // Check if socket is already connected
    if (SocketService.instance.isConnected) {
      print('📬 Nekhemjlekh: Socket already connected, setting up listener');
      _setupSocketListener();
    } else {
      print('📬 Nekhemjlekh: Socket not connected, connecting now...');
      try {
        await SocketService.instance.connect();
        // Wait a bit for connection to establish
        await Future.delayed(const Duration(milliseconds: 500));

        if (SocketService.instance.isConnected) {
          print('📬 Nekhemjlekh: Socket connected successfully');
          _setupSocketListener();
        } else {
          print('⚠️ Nekhemjlekh: Socket connection failed or pending');
          // Still set up listener in case it connects later
          _setupSocketListener();
        }
      } catch (e) {
        print('❌ Nekhemjlekh: Error connecting socket: $e');
        // Still set up listener in case it connects later
        _setupSocketListener();
      }
    }
    print('📬📬📬 NEKHEMJLEKH: _connectSocketAndSetupListener COMPLETED!');
  }

  void _setupSocketListener() {
    print('📬 Nekhemjlekh: Setting up notification callback');

    // Listen for real-time invoice notifications via socket
    _notificationCallback = (Map<String, dynamic> notification) {
      // CRITICAL: Print immediately at the start - no conditions, no try-catch, no mounted check
      print('📬📬📬 NEKHEMJLEKH CALLBACK CALLED!');
      print('📬📬📬 NEKHEMJLEKH: This is the nekhemjlekh callback!');
      print(
        '📬📬📬 NEKHEMJLEKH: Notification received: ${notification.toString()}',
      );
      print('📬📬📬 Nekhemjlekh: Socket notification received: $notification');
      print('📬 Nekhemjlekh: Notification keys: ${notification.keys.toList()}');

      if (!mounted) {
        print('📬 Nekhemjlekh: Widget not mounted, ignoring notification');
        return;
      }

      // Check if it's an invoice creation notification
      // Handle two notification formats:
      // 1. Standard notification format: {title, message, turul}
      // 2. Transaction/invoice format: {baiguullagiinId, guilgee: {turul: "avlaga", ...}}

      final title = notification['title']?.toString() ?? '';
      final message = notification['message']?.toString() ?? '';
      final turul = notification['turul']?.toString().toLowerCase() ?? '';

      // Check for guilgee (transaction/invoice) format
      final guilgee = notification['guilgee'];
      final guilgeeTurul = guilgee is Map
          ? (guilgee['turul']?.toString().toLowerCase() ?? '')
          : '';
      final baiguullagiinId = notification['baiguullagiinId']?.toString();

      print(
        '📬 Nekhemjlekh: Parsed values - title="$title", message="$message", turul="$turul", guilgeeTurul="$guilgeeTurul", baiguullagiinId="$baiguullagiinId"',
      );
      print(
        '📬 Nekhemjlekh: guilgee is Map: ${guilgee is Map}, guilgee value: $guilgee',
      );

      // Check if this is a new invoice notification
      // Based on the documentation and actual payload:
      // - Standard format: title: "Шинэ нэхэмжлэх үүссэн", turul: "мэдэгдэл"
      // - Transaction format: guilgee.turul: "avlaga" (invoice)
      final isInvoiceNotification =
          // Check for transaction/invoice format (guilgee with turul="avlaga")
          (guilgeeTurul == 'avlaga') ||
          // Check title for invoice/avlaga keywords (including "Шинэ авлага нэмэгдлээ")
          (title.toLowerCase().contains('нэхэмжлэх') ||
              title.toLowerCase().contains('нэхэмжлэл') ||
              title.toLowerCase().contains('invoice') ||
              title.toLowerCase().contains('шинэ') ||
              title.toLowerCase().contains('үүсгэ') ||
              title.toLowerCase().contains('илгээ') ||
              title.toLowerCase().contains('авлага') ||
              title.toLowerCase().contains('нэмэгдлээ')) ||
          // Check message for invoice/avlaga keywords (including manualSend, "Шинэ авлага нэмэгдлээ")
          (message.toLowerCase().contains('нэхэмжлэх') ||
              message.toLowerCase().contains('нэхэмжлэл') ||
              message.toLowerCase().contains('гэрээний дугаар') ||
              message.toLowerCase().contains('нийт төлбөр') ||
              message.toLowerCase().contains('гэрээ') ||
              message.toLowerCase().contains('үүсгэгдлээ') ||
              message.toLowerCase().contains('илгээгдлээ') ||
              message.toLowerCase().contains('авлага') ||
              message.toLowerCase().contains('нэмэгдлээ')) ||
          // Check if turul is "мэдэгдэл" (notification type for invoices)
          (turul == 'мэдэгдэл' || turul == 'medegdel' || turul == 'app');

      print(
        '📬 Nekhemjlekh: isInvoiceNotification=$isInvoiceNotification, mounted=$mounted',
      );
      print(
        '📬 Nekhemjlekh: guilgeeTurul check: "$guilgeeTurul" == "avlaga" = ${guilgeeTurul == "avlaga"}',
      );

      if (isInvoiceNotification) {
        print(
          '📬 Nekhemjlekh: ✅ Processing invoice notification, showing toast and refreshing list',
        );

        // Invoice notification detected - refresh the invoice list
        print(
          '📬 Nekhemjlekh: Invoice notification detected, refreshing invoice list',
        );

        // Refresh invoice list after a short delay to ensure backend has updated
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            print('📬 Nekhemjlekh: Refreshing invoice list');
            _loadNekhemjlekh();
          }
        });
      } else {
        print(
          '📬 Nekhemjlekh: ⚠️ Notification ignored (not an invoice notification)',
        );
        print(
          '📬 Nekhemjlekh: Debug - guilgeeTurul="$guilgeeTurul", title="$title", message="$message", turul="$turul"',
        );
      }
    };
    print('📬 Nekhemjlekh: Registering callback...');
    print(
      '📬 Nekhemjlekh: Callback function before registration: $_notificationCallback',
    );
    print('📬 Nekhemjlekh: Callback is null: ${_notificationCallback == null}');

    if (_notificationCallback == null) {
      print('❌❌❌ Nekhemjlekh: CRITICAL - Callback is NULL! Cannot register!');
      return;
    }

    SocketService.instance.setNotificationCallback(_notificationCallback!);
    print('📬 Nekhemjlekh: ✅ Socket listener callback registered');
    print(
      '📬 Nekhemjlekh: Socket connected status: ${SocketService.instance.isConnected}',
    );

    // Verify callback was registered by checking if socket service has it
    print(
      '📬 Nekhemjlekh: Callback function after registration: $_notificationCallback',
    );

    // Check socket connection status periodically
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final isConnected = SocketService.instance.isConnected;
        print('📬 Nekhemjlekh: Socket status check - connected: $isConnected');
        if (!isConnected) {
          print(
            '⚠️ Nekhemjlekh: Socket not connected, attempting to reconnect...',
          );
          _connectSocketAndSetupListener();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refetch when app resumes (e.g. user returns from notification) to show latest invoice total, ekhniiUldegdel, avlaga
    if (state == AppLifecycleState.resumed && mounted) {
      _loadNekhemjlekh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove socket callback when screen is disposed
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
    }
    super.dispose();
  }

  Future<void> _createQPayInvoice() async {
    setState(() {
      isLoadingQPay = true;
      qpayQrImageOwnOrg = null;
      qpayQrImageWallet = null;
    });

    // Fetch contact phone from baiguullaga (organization)
    try {
      print('📞 [EBARIMT] Fetching baiguullaga for contact phone...');
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      if (baiguullagiinId != null) {
        final baiguullagaResponse = await ApiService.fetchBaiguullagaById(baiguullagiinId);
        print('📞 [EBARIMT] Baiguullaga response: $baiguullagaResponse');
        if (baiguullagaResponse['utas'] != null && baiguullagaResponse['utas'] is List) {
          final utasList = baiguullagaResponse['utas'] as List;
          if (utasList.isNotEmpty) {
            contactPhone = utasList.first.toString();
            print('📞 [EBARIMT] Contact phone found from baiguullaga: $contactPhone');
          }
        }
      }
      if (contactPhone.isEmpty) {
        print('📞 [EBARIMT] No phone found in baiguullaga');
      }
    } catch (e) {
      print('❌ [EBARIMT] Error fetching baiguullaga contact: $e');
      contactPhone = '';
    }
    print('📞 [EBARIMT] Final contactPhone value: $contactPhone');

    try {
      double totalAmount = 0;
      String? turul;

      selectedInvoiceIds = [];

      for (var invoice in invoices) {
        if (invoice.isSelected) {
          totalAmount += invoice.effectiveNiitTulbur;
          selectedInvoiceIds.add(invoice.id);

          turul ??= invoice.gereeniiDugaar;
        }
      }

      // Use effective total (sum of unpaid merged invoices or contract uldegdel)
      final effective = _effectiveTotalAmount;
      if (effective > 0) totalAmount = effective;

      if (selectedInvoiceIds.isEmpty) {
        throw Exception('Нэхэмжлэх сонгоогүй байна');
      }

      if (turul == null || turul.isEmpty) {
        throw Exception('Гэрээний дугаар олдсонгүй');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'TEST-$timestamp';

      // Check if user has OWN_ORG address
      final ownOrgBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId = await StorageService.getBarilgiinId();

      final hasOwnOrg =
          ownOrgBaiguullagiinId != null && ownOrgBarilgiinId != null;

      // Get invoice details for Custom QPay (dansniiDugaar and burtgeliinDugaar)
      String? dansniiDugaar;
      String? burtgeliinDugaar;
      String? firstInvoiceId;

      if (selectedInvoiceIds.isNotEmpty) {
        final firstInvoice = invoices.firstWhere(
          (inv) => inv.id == selectedInvoiceIds.first,
          orElse: () => invoices.firstWhere((inv) => inv.isSelected),
        );
        dansniiDugaar = firstInvoice.dansniiDugaar.isNotEmpty
            ? firstInvoice.dansniiDugaar
            : null;
        burtgeliinDugaar = firstInvoice.register.isNotEmpty
            ? firstInvoice.register
            : null;
        firstInvoiceId = firstInvoice.id;
      }

      // Create OWN_ORG QPay invoice (Custom QPay)
      if (hasOwnOrg) {
        try {
          final ownOrgResponse = await ApiService.qpayGargaya(
            baiguullagiinId: ownOrgBaiguullagiinId,
            barilgiinId: ownOrgBarilgiinId,
            dun: totalAmount,
            turul: turul,
            zakhialgiinDugaar: '$orderNumber-OWN_ORG',
            nekhemjlekhiinId: firstInvoiceId,
            dansniiDugaar: dansniiDugaar,
            burtgeliinDugaar: burtgeliinDugaar,
          );

          qpayQrImageOwnOrg = ownOrgResponse['qr_image']?.toString();
          if (qpayInvoiceId == null) {
            qpayInvoiceId = ownOrgResponse['invoice_id']?.toString();
          }

          if (ownOrgResponse['urls'] != null &&
              ownOrgResponse['urls'] is List) {
            qpayBanks = (ownOrgResponse['urls'] as List)
                .map((bank) => QPayBank.fromJson(bank))
                .toList();
          }
        } catch (e) {
          print('Error creating OWN_ORG QPay invoice: $e');
        }
      }

      // Note: Wallet API QPay requires billingId + billIds, not dun + walletUserId
      // This screen is for OWN_ORG invoices, so we don't create Wallet QPay here
      // Wallet QPay should only be created from billing flow (total_balance_modal.dart)

      // Fallback to single QR if only one source or if both failed
      if (qpayQrImageOwnOrg == null && qpayQrImageWallet == null) {
        if (hasOwnOrg) {
          throw Exception(
            contactPhone.isNotEmpty
                ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
                : 'Банкны мэдээлэл олдсонгүй',
          );
        } else {
          throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
        }
      }

      // Set legacy qpayQrImage for backward compatibility
      qpayQrImage = qpayQrImageOwnOrg ?? qpayQrImageWallet;

      setState(() {
        isLoadingQPay = false;
      });
    } catch (e) {
      setState(() {
        isLoadingQPay = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNekhemjlekh() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final orshinSuugchId = await StorageService.getUserId();

      if (orshinSuugchId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final gereeResponse = await ApiService.fetchGeree(orshinSuugchId);

      if (gereeResponse['jagsaalt'] != null &&
          gereeResponse['jagsaalt'] is List &&
          (gereeResponse['jagsaalt'] as List).isNotEmpty) {
        availableContracts = List<Map<String, dynamic>>.from(
          gereeResponse['jagsaalt'],
        );

        final gereeToUse = selectedGereeniiDugaar != null
            ? availableContracts.firstWhere(
                (c) => c['gereeniiDugaar'] == selectedGereeniiDugaar,
                orElse: () => availableContracts[0],
              )
            : availableContracts[0];

        final gereeniiDugaar = gereeToUse['gereeniiDugaar'] as String?;

        if (gereeniiDugaar == null || gereeniiDugaar.isEmpty) {
          throw Exception('Гэрээний дугаар олдсонгүй');
        }

        selectedGereeniiDugaar = gereeniiDugaar;
        selectedContractDisplay = '${gereeToUse['bairNer'] ?? gereeniiDugaar}';
        // Use uldegdel first (matches HistoryModal), fallback to globalUldegdel
        final rawUldegdel = gereeToUse['uldegdel'] ?? gereeToUse['globalUldegdel'];
        _contractUldegdel = rawUldegdel != null
            ? ((rawUldegdel is num) ? rawUldegdel.toDouble() : (double.tryParse(rawUldegdel.toString()) ?? 0.0))
            : null;

        final baiguullagiinId = gereeToUse['baiguullagiinId']?.toString() ??
            await StorageService.getBaiguullagiinId();
        final barilgiinId = gereeToUse['barilgiinId']?.toString();
        final gereeniiId = gereeToUse['_id']?.toString();

        // Fetch both nekhemjlekhiinTuukh and gereeniiTulukhAvlaga in parallel (matches web Үйлчилгээний нэхэмжлэх)
        final results = await Future.wait([
          ApiService.fetchNekhemjlekhiinTuukh(
            gereeniiDugaar: gereeniiDugaar,
            khuudasniiDugaar: 1,
            khuudasniiKhemjee: 200,
          ),
          baiguullagiinId != null
              ? ApiService.fetchGereeniiTulukhAvlaga(
                  baiguullagiinId: baiguullagiinId,
                  gereeniiDugaar: gereeniiDugaar,
                  orshinSuugchId: orshinSuugchId,
                  barilgiinId: barilgiinId,
                )
              : Future.value({'jagsaalt': []}),
        ]);

        final response = results[0] as Map<String, dynamic>;
        final tulukhAvlagaResponse = results[1] as Map<String, dynamic>;

        if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
          final rawInvoices = response['jagsaalt'] as List;
          final tulukhAvlagaList = tulukhAvlagaResponse['jagsaalt'] is List
              ? (tulukhAvlagaResponse['jagsaalt'] as List)
                  .cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];

          // Merge gereeniiTulukhAvlaga into invoices (ekhniiUldegdel, avlaga) - matches web
          final mergedInvoices = mergeTulukhAvlagaIntoInvoices(
            rawInvoices,
            tulukhAvlagaList,
            gereeniiId,
            gereeniiDugaar,
            orshinSuugchId,
          );

          final previouslySelectedIds = invoices
              .where((inv) => inv.isSelected)
              .map((inv) => inv.id)
              .toSet();

          setState(() {
            invoices = mergedInvoices
                .map((item) => NekhemjlekhItem.fromJson(item))
                .toList();

            for (var invoice in invoices) {
              if (previouslySelectedIds.contains(invoice.id)) {
                invoice.isSelected = true;
              }
            }

            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Мэдээлэл олдсонгүй';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Гэрээний мэдээлэл олдсонгүй';
        });
      }
    } catch (e) {
      print('Error in _loadNekhemjlekh: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Алдаа гарлаа: $e';
      });
    }
  }

  void _showContractSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContractSelectionModal(
        availableContracts: availableContracts,
        selectedGereeniiDugaar: selectedGereeniiDugaar,
        onContractSelected: (gereeniiDugaar) {
          setState(() {
            selectedGereeniiDugaar = gereeniiDugaar;
          });
          _loadNekhemjlekh();
        },
      ),
    );
  }

  bool get allSelected {
    final unpaidInvoices = invoices
        .where((invoice) => invoice.tuluv == 'Төлөөгүй')
        .toList();
    return unpaidInvoices.isNotEmpty &&
        unpaidInvoices.every((invoice) => invoice.isSelected);
  }

  int get selectedCount =>
      invoices.where((invoice) => invoice.isSelected).length;

  /// Effective total: prefer sum of unpaid merged invoices (includes avlaga) when
  /// backend contract.uldegdel may be stale (e.g. after manualSend avlaga).
  double get _effectiveTotalAmount {
    final unpaid = invoices.where((i) => i.tuluv == 'Төлөөгүй').toList();
    if (unpaid.isNotEmpty) {
      final sum = unpaid.fold<double>(0, (s, i) => s + i.effectiveNiitTulbur);
      return sum;
    }
    return _contractUldegdel ?? 0;
  }

  String get totalSelectedAmount {
    final amount = _effectiveTotalAmount;
    if (amount >= 0) {
      final formatted = amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
      return '$formatted₮';
    }
    return '0.00₮';
  }

  void toggleSelectAll() {
    setState(() {
      bool newValue = !allSelected;
      for (var invoice in invoices) {
        // Only select/deselect invoices with status "Төлөөгүй" (Unpaid)
        if (invoice.tuluv == 'Төлөөгүй') {
          invoice.isSelected = newValue;
        }
      }
    });
  }

  List<NekhemjlekhItem> _getFilteredInvoices() {
    List<NekhemjlekhItem> filtered = invoices;

    // Apply filter
    if (selectedFilter == 'Paid') {
      // Show only paid invoices
      filtered = filtered
          .where((invoice) => invoice.tuluv == 'Төлсөн')
          .toList();
    } else if (selectedFilter == 'Avlaga') {
      // Show only invoices with avlaga (has guilgeenuud with turul="avlaga" or "Авлага")
      filtered = filtered
          .where(
            (invoice) =>
                invoice.tuluv != 'Төлсөн' &&
                invoice.medeelel != null &&
                invoice.medeelel!.guilgeenuud != null &&
                invoice.medeelel!.guilgeenuud!.any((guilgee) {
                  final t = guilgee.turul?.toLowerCase() ?? '';
                  return (t == 'avlaga' || t == 'авлага') && !guilgee.ekhniiUldegdelEsekh;
                }),
          )
          .toList();
    } else if (selectedFilter == 'AshiglaltiinZardal') {
      // Show only invoices with ashiglaltiinZardal (items with turul "Тогтмол" or "Дурын")
      filtered = filtered
          .where(
            (invoice) =>
                invoice.tuluv != 'Төлсөн' &&
                invoice.medeelel != null &&
                invoice.medeelel!.zardluud.isNotEmpty &&
                invoice.medeelel!.zardluud.any(
                  (zardal) {
                    final t = zardal.turul.toLowerCase();
                    return t == 'тогтмол' || t == 'дурын';
                  },
                ),
          )
          .toList();
    } else {
      // 'All' shows all unpaid invoices
      filtered = filtered
          .where((invoice) => invoice.tuluv != 'Төлсөн')
          .toList();
    }

    return filtered;
  }

  // _getStatusColor and _getStatusLabel moved to components/Nekhemjlekh/invoice_card.dart

  int _getFilterCount(String filterKey) {
    switch (filterKey) {
      case 'All':
        return invoices.where((invoice) => invoice.tuluv != 'Төлсөн').length;
      case 'Avlaga':
        return invoices
            .where(
              (invoice) =>
                  invoice.tuluv != 'Төлсөн' &&
                  invoice.medeelel != null &&
                  invoice.medeelel!.guilgeenuud != null &&
                  invoice.medeelel!.guilgeenuud!.any((guilgee) {
                    final t = guilgee.turul?.toLowerCase() ?? '';
                    return (t == 'avlaga' || t == 'авлага') && !guilgee.ekhniiUldegdelEsekh;
                  }),
            )
            .length;
      case 'AshiglaltiinZardal':
        return invoices
            .where(
              (invoice) =>
                  invoice.tuluv != 'Төлсөн' &&
                  invoice.medeelel != null &&
                  invoice.medeelel!.zardluud.isNotEmpty &&
                  invoice.medeelel!.zardluud.any(
                    (zardal) {
                      final t = zardal.turul.toLowerCase();
                      return t == 'тогтмол' || t == 'дурын';
                    },
                  ),
            )
            .length;
      case 'Paid':
        return invoices.where((invoice) => invoice.tuluv == 'Төлсөн').length;
      default:
        return 0;
    }
  }

  // _buildFilterTab moved to components/Nekhemjlekh/filter_tabs.dart

  void _showBankInfoModal() async {
    print('=== _showBankInfoModal called ===');
    await _createQPayInvoice();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankSelectionModal(
        qpayBanks: qpayBanks,
        isLoadingQPay: isLoadingQPay,
        contactPhone: contactPhone,
        onBankTap: (bank) {
          // Check if it's qPay wallet - show QR code
          if (bank.description.contains('qPay хэтэвч') ||
              bank.name.toLowerCase().contains('qpay wallet')) {
            _showQPayQRCodeModal();
          } else {
            _openBankAppAndShowCheckModal(bank);
          }
        },
        onQPayWalletTap: _showQPayQRCodeModal,
      ),
    );
  }

  Future<void> _showVATReceiptModal(String invoiceId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.secondaryAccent),
        ),
      );

      // Fetch VAT receipts
      final response = await ApiService.fetchEbarimtJagsaaltAvya(
        nekhemjlekhiinId: invoiceId,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      final receipts = <VATReceipt>[];
      if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
        for (var item in response['jagsaalt'] as List) {
          // Match nekhemjlekhiinId with invoice _id
          if (item['nekhemjlekhiinId'] == invoiceId) {
            receipts.add(VATReceipt.fromJson(item));
          }
        }
      }

      if (receipts.isEmpty) {
        // Find the invoice to get gereeniiDugaar
        final invoice = invoices.firstWhere(
          (inv) => inv.id == invoiceId,
          orElse: () => invoices.first,
        );

        // Try to get suhUtas from contract first
        String suhUtas = '';
        if (availableContracts.isNotEmpty &&
            invoice.gereeniiDugaar.isNotEmpty) {
          try {
            final contractMap = availableContracts.firstWhere(
              (c) => c['gereeniiDugaar']?.toString() == invoice.gereeniiDugaar,
              orElse: () => availableContracts.first,
            );

            // Convert Map to Geree model object (like in geree.dart)
            final geree = Geree.fromJson(contractMap);

            if (geree.suhUtas.isNotEmpty) {
              suhUtas = geree.suhUtas.first;
            }
          } catch (e) {
            // Silent fail
          }
        }

        // If suhUtas is still empty, get phone from baiguullaga (organization)
        if (suhUtas.isEmpty) {
          try {
            final baiguullagiinId = await StorageService.getBaiguullagiinId();
            if (baiguullagiinId != null) {
              final baiguullagaResponse = await ApiService.fetchBaiguullagaById(baiguullagiinId);
              if (baiguullagaResponse['utas'] != null && baiguullagaResponse['utas'] is List) {
                final utasList = baiguullagaResponse['utas'] as List;
                if (utasList.isNotEmpty) {
                  suhUtas = utasList.first.toString();
                }
              }
            }
          } catch (e) {
            print('Error fetching baiguullaga phone: $e');
            // Silent fail
          }
        }

        if (!mounted) return;

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: context.responsiveHorizontalPadding(
                small: 24,
                medium: 28,
                large: 32,
                tablet: 40,
                veryNarrow: 16,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 20,
                        medium: 22,
                        large: 24,
                        tablet: 28,
                        veryNarrow: 16,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDarkMode ? 0.4 : 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: context.responsivePadding(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                    veryNarrow: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(context.responsiveSpacing(
                              small: 6,
                              medium: 8,
                              large: 10,
                              tablet: 12,
                              veryNarrow: 4,
                            )),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.textSecondaryColor,
                              size: context.responsiveIconSize(
                                small: 18,
                                medium: 20,
                                large: 22,
                                tablet: 24,
                                veryNarrow: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 8,
                          medium: 12,
                          large: 16,
                          tablet: 20,
                          veryNarrow: 6,
                        ),
                      ),
                      // Warning icon
                      Container(
                        padding: EdgeInsets.all(context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 24,
                          veryNarrow: 12,
                        )),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: context.responsiveIconSize(
                            small: 32,
                            medium: 36,
                            large: 40,
                            tablet: 48,
                            veryNarrow: 28,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 16,
                          medium: 20,
                          large: 24,
                          tablet: 28,
                          veryNarrow: 12,
                        ),
                      ),
                      // Message
                      Text(
                        "И-Баримтын тохиргоо хийгдээгүй байна",
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          ),
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 8,
                          medium: 10,
                          large: 12,
                          tablet: 14,
                          veryNarrow: 6,
                        ),
                      ),
                      // Subtitle
                      Text(
                        "Тохиргоо хийлгэхийн тулд СӨХ-тэй холбогдоно уу",
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 15,
                            veryNarrow: 11,
                          ),
                          fontWeight: FontWeight.w400,
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 20,
                          medium: 24,
                          large: 28,
                          tablet: 32,
                          veryNarrow: 16,
                        ),
                      ),
                      if (suhUtas.isNotEmpty) ...[
                        // Phone number card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 16,
                              medium: 20,
                              large: 24,
                              tablet: 28,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 14,
                              medium: 16,
                              large: 18,
                              tablet: 22,
                              veryNarrow: 10,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 10,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                color: AppColors.deepGreen,
                                size: context.responsiveIconSize(
                                  small: 20,
                                  medium: 22,
                                  large: 24,
                                  tablet: 28,
                                  veryNarrow: 18,
                                ),
                              ),
                              SizedBox(width: context.responsiveSpacing(
                                small: 10,
                                medium: 12,
                                large: 14,
                                tablet: 16,
                                veryNarrow: 8,
                              )),
                              GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(ClipboardData(text: suhUtas));
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Дугаар хуулагдлаа: $suhUtas',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: AppColors.deepGreen,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  suhUtas,
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(
                                      small: 18,
                                      medium: 20,
                                      large: 22,
                                      tablet: 24,
                                      veryNarrow: 16,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.responsiveSpacing(
                          small: 16,
                          medium: 20,
                          large: 24,
                          tablet: 28,
                          veryNarrow: 12,
                        )),
                        // Call button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              final uri = Uri.parse('tel:$suhUtas');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Утас дуудах боломжгүй'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.call_rounded,
                              size: context.responsiveIconSize(
                                small: 18,
                                medium: 20,
                                large: 22,
                                tablet: 24,
                                veryNarrow: 16,
                              ),
                              color: Colors.white,
                            ),
                            label: Text(
                              'Залгах',
                              style: TextStyle(
                                color: Colors.white,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsiveSpacing(
                                  small: 14,
                                  medium: 16,
                                  large: 18,
                                  tablet: 20,
                                  veryNarrow: 12,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 12,
                                    medium: 14,
                                    large: 16,
                                    tablet: 18,
                                    veryNarrow: 10,
                                  ),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Empty state
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 16,
                              medium: 20,
                              large: 24,
                              tablet: 28,
                              veryNarrow: 12,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 20,
                              medium: 24,
                              large: 28,
                              tablet: 32,
                              veryNarrow: 16,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 10,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.phone_disabled_rounded,
                                color: context.textSecondaryColor.withOpacity(0.5),
                                size: context.responsiveIconSize(
                                  small: 32,
                                  medium: 36,
                                  large: 40,
                                  tablet: 48,
                                  veryNarrow: 28,
                                ),
                              ),
                              SizedBox(
                                height: context.responsiveSpacing(
                                  small: 8,
                                  medium: 10,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 6,
                                ),
                              ),
                              Text(
                                'Утасны дугаар олдсонгүй',
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(
                                    small: 13,
                                    medium: 14,
                                    large: 15,
                                    tablet: 16,
                                    veryNarrow: 11,
                                  ),
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VATReceiptModal(receipt: receipts[0]),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа гарлаа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // _buildVATReceiptBottomSheet, _buildReceiptInfoRow, _buildQPayBankItem moved to components

  Future<void> _openBankAppAndShowCheckModal(QPayBank bank) async {
    try {
      final Uri bankUri = Uri.parse(bank.link);

      print('Attempting to launch bank app with URL: ${bank.link}');

      // Close the bank selection modal
      Navigator.of(context).pop();

      // Try to launch the bank app
      bool launched = false;
      try {
        launched = await launchUrl(
          bankUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('Error launching bank app: $e');
        launched = false;
      }

      if (launched) {
        // Successfully opened the app
        print('Bank app launched successfully');

        // Wait a moment for the app to open, then show the check modal
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showPaymentCheckModal(bank);
        }
      } else {
        // Bank app not installed
        if (mounted) {
          _showBankAppNotInstalledDialog(bank);
        }
      }
    } catch (e) {
      print('Error in _openBankAppAndShowCheckModal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentCheckModal(QPayBank bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                context.responsiveBorderRadius(
                  small: 30,
                  medium: 32,
                  large: 34,
                  tablet: 36,
                  veryNarrow: 24,
                ),
              ),
              topRight: Radius.circular(
                context.responsiveBorderRadius(
                  small: 30,
                  medium: 32,
                  large: 34,
                  tablet: 36,
                  veryNarrow: 24,
                ),
              ),
            ),
          ),
          child: OptimizedGlass(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                context.responsiveBorderRadius(
                  small: 30,
                  medium: 32,
                  large: 34,
                  tablet: 36,
                  veryNarrow: 24,
                ),
              ),
              topRight: Radius.circular(
                context.responsiveBorderRadius(
                  small: 30,
                  medium: 32,
                  large: 34,
                  tablet: 36,
                  veryNarrow: 24,
                ),
              ),
            ),
            opacity: 0.08,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(
                    top: context.responsiveSpacing(
                      small: 12,
                      medium: 14,
                      large: 16,
                      tablet: 18,
                      veryNarrow: 8,
                    ),
                  ),
                  width: context.responsiveSpacing(
                    small: 40,
                    medium: 44,
                    large: 48,
                    tablet: 52,
                    veryNarrow: 32,
                  ),
                  height: context.responsiveSpacing(
                    small: 4,
                    medium: 5,
                    large: 6,
                    tablet: 7,
                    veryNarrow: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 2,
                        medium: 3,
                        large: 4,
                        tablet: 5,
                        veryNarrow: 1,
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: context.responsivePadding(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Төлбөр баталгаажуулах',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 24,
                              medium: 26,
                              large: 28,
                              tablet: 30,
                              veryNarrow: 20,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.textPrimaryColor,
                          size: context.responsiveIconSize(
                            small: 24,
                            medium: 26,
                            large: 28,
                            tablet: 30,
                            veryNarrow: 20,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Bank logo and info
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsiveSpacing(
                      small: 20,
                      medium: 22,
                      large: 24,
                      tablet: 26,
                      veryNarrow: 14,
                    ),
                  ),
                  child: Container(
                    padding: context.responsivePadding(
                      small: 20,
                      medium: 22,
                      large: 24,
                      tablet: 26,
                      veryNarrow: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 20,
                          medium: 22,
                          large: 24,
                          tablet: 26,
                          veryNarrow: 16,
                        ),
                      ),
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.responsiveSpacing(
                            small: 60,
                            medium: 64,
                            large: 68,
                            tablet: 72,
                            veryNarrow: 48,
                          ),
                          height: context.responsiveSpacing(
                            small: 60,
                            medium: 64,
                            large: 68,
                            tablet: 72,
                            veryNarrow: 48,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 8,
                                medium: 10,
                                large: 12,
                                tablet: 14,
                                veryNarrow: 6,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 8,
                                medium: 10,
                                large: 12,
                                tablet: 14,
                                veryNarrow: 6,
                              ),
                            ),
                            child: Image.network(
                              bank.logo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_balance,
                                  color: context.textSecondaryColor,
                                  size: context.responsiveIconSize(
                                    small: 30,
                                    medium: 32,
                                    large: 34,
                                    tablet: 36,
                                    veryNarrow: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: context.responsiveSpacing(
                            small: 16,
                            medium: 18,
                            large: 20,
                            tablet: 22,
                            veryNarrow: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bank.description,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Check payment button
                Padding(
                  padding: context.responsivePadding(
                    small: 20,
                    medium: 22,
                    large: 24,
                    tablet: 26,
                    veryNarrow: 14,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _checkPaymentStatus(bank),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepGreen,
                        foregroundColor: context.textPrimaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      child: Text(
                        'Төлбөр шалгах',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkPaymentStatus(QPayBank bank) async {
    // Close the payment check modal first
    Navigator.pop(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryAccent),
      ),
    );

    try {
      // Reload invoice data to get latest status
      await _loadNekhemjlekh();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check if the selected invoice(s) are paid
      final selectedInvoices = invoices
          .where((inv) => selectedInvoiceIds.contains(inv.id))
          .toList();

      if (selectedInvoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сонгосон нэхэмжлэл олдсонгүй'),
              backgroundColor: Colors.red,
            ),
          );
          _showBankInfoModal();
        }
        return;
      }

      // Check if all selected invoices are paid
      final allPaid = selectedInvoices.every((inv) => inv.tuluv == 'Төлсөн');

      if (allPaid) {
        // Payment successful - show success snackbar
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр амжилттай төлөгдлөө',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            textColor: context.textPrimaryColor,
            opacity: 0.3,
            blur: 15,
          );

          // Wait a bit then reload invoice data to refresh the list
          await Future.delayed(const Duration(seconds: 2));

          // Reload invoice data to get the latest status from server
          await _loadNekhemjlekh();

          // Show VAT receipts for all paid invoices
          for (var invoice in selectedInvoices) {
            await _showVATReceiptModal(invoice.id);
          }

          // Navigate back to home page to refresh the data
          context.go('/nuur');
        }
      } else {
        // Payment not completed - show error snackbar and return to bank list
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр төлөгдөөгүй байна',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            textColor: context.textPrimaryColor,
            opacity: 0.3,
            blur: 15,
          );

          // Wait a bit then show bank list again
          await Future.delayed(const Duration(seconds: 2));
          _showBankInfoModal();
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');

      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Show bank list again
        _showBankInfoModal();
      }
    }
  }

  Future<void> _checkPaymentStatusFromQR() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryAccent),
      ),
    );

    try {
      // Reload invoice data to get latest status
      await _loadNekhemjlekh();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check if the selected invoice(s) are paid
      final selectedInvoices = invoices
          .where((inv) => selectedInvoiceIds.contains(inv.id))
          .toList();

      if (selectedInvoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сонгосон нэхэмжлэл олдсонгүй'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if all selected invoices are paid
      final allPaid = selectedInvoices.every((inv) => inv.tuluv == 'Төлсөн');

      if (allPaid) {
        // Payment successful - show success snackbar
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр амжилттай төлөгдлөө',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            textColor: context.textPrimaryColor,
            opacity: 0.3,
            blur: 15,
          );

          // Wait a bit then reload invoice data to refresh the list
          await Future.delayed(const Duration(seconds: 2));

          // Reload invoice data to get the latest status from server
          await _loadNekhemjlekh();

          // Show VAT receipts for all paid invoices
          for (var invoice in selectedInvoices) {
            await _showVATReceiptModal(invoice.id);
          }

          // Navigate back to home page to refresh the data
          context.go('/nuur');
        }
      } else {
        // Payment not completed - show error snackbar
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр төлөгдөөгүй байна. Дахин оролдоно уу.',
            icon: Icons.error_outline,
            iconColor: Colors.orange,
            textColor: context.textPrimaryColor,
            opacity: 0.3,
            blur: 15,
          );
        }
      }
    } catch (e) {
      print('Error checking payment status from QR: $e');

      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _startPaymentStatusCheck() async {
    if (qpayInvoiceId == null) {
      print('No QPay invoice ID to check');
      return;
    }

    // Poll payment status every 2 seconds for up to 60 seconds
    int attempts = 0;
    const maxAttempts = 30;
    const checkInterval = Duration(seconds: 2);

    while (attempts < maxAttempts && mounted) {
      try {
        await Future.delayed(checkInterval);

        final statusResponse = await ApiService.checkPaymentStatus(
          invoiceId: qpayInvoiceId!,
        );

        print('Payment status check: $statusResponse');

        // Check if payment is successful
        if (statusResponse['paid_amount'] != null &&
            statusResponse['paid_amount'] > 0) {
          // Payment successful!
          if (mounted) {
            await _handlePaymentSuccess();
          }
          break;
        }

        attempts++;
      } catch (e) {
        print('Error checking payment status: $e');
        attempts++;
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      // Update invoice status to "Төлсөн" on the server
      if (selectedInvoiceIds.isNotEmpty) {
        await ApiService.updateNekhemjlekhiinTuluv(
          nekhemjlekhiinIds: selectedInvoiceIds,
          tuluv: 'Төлсөн',
        );
      }

      // Show success notification
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Төлбөр амжилттай төлөгдлөө',
        body: 'Дарж И-баримт аа харна уу!',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Төлбөр амжилттай төлөгдлөө'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Reload invoices to update the list
      await _loadNekhemjlekh();

      // Show VAT receipts for all paid invoices
      if (selectedInvoiceIds.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showMultipleVATReceipts(selectedInvoiceIds);
        }
      }
    } catch (e) {
      print('Error updating payment status: $e');
      // Still reload to show updated data from server
      await _loadNekhemjlekh();
    }
  }

  Future<void> _showMultipleVATReceipts(List<String> invoiceIds) async {
    for (String invoiceId in invoiceIds) {
      try {
        final response = await ApiService.fetchEbarimtJagsaaltAvya(
          nekhemjlekhiinId: invoiceId,
        );

        final receipts = <VATReceipt>[];
        if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
          for (var item in response['jagsaalt'] as List) {
            if (item['nekhemjlekhiinId'] == invoiceId) {
              receipts.add(VATReceipt.fromJson(item));
            }
          }
        }

        if (receipts.isNotEmpty && mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => VATReceiptModal(receipt: receipts[0]),
          );
        }
      } catch (e) {
        print('Error fetching VAT receipt for $invoiceId: $e');
      }
    }
  }

  void _showQPayQRCodeModal() {
    final hasOwnOrg =
        qpayQrImageOwnOrg != null && qpayQrImageOwnOrg!.isNotEmpty;
    final hasWallet =
        qpayQrImageWallet != null && qpayQrImageWallet!.isNotEmpty;

    if (!hasOwnOrg && !hasWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код олдсонгүй'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 20,
                  medium: 22,
                  large: 24,
                  tablet: 26,
                  veryNarrow: 16,
                ),
              ),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            padding: context.responsivePadding(
              small: 20,
              medium: 22,
              large: 24,
              tablet: 26,
              veryNarrow: 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      'QPay QR код',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 18,
                          medium: 20,
                          large: 22,
                          tablet: 24,
                          veryNarrow: 16,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close,
                        color: context.textSecondaryColor,
                        size: 24.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 16,
                    medium: 20,
                    large: 24,
                    tablet: 28,
                    veryNarrow: 12,
                  ),
                ),
                // Show 2 QR codes side by side if both exist, otherwise show single
                if (hasOwnOrg && hasWallet)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // OWN_ORG QR
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'OWN_ORG',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height: context.responsiveSpacing(
                                small: 8,
                                medium: 10,
                                large: 12,
                                tablet: 14,
                                veryNarrow: 6,
                              ),
                            ),
                            Container(
                              padding: context.responsivePadding(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? Colors.white
                                    : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 12,
                                    medium: 14,
                                    large: 16,
                                    tablet: 18,
                                    veryNarrow: 10,
                                  ),
                                ),
                              ),
                              child: Image.memory(
                                base64Decode(qpayQrImageOwnOrg!),
                                width: context.responsiveSpacing(
                                  small: 150,
                                  medium: 160,
                                  large: 170,
                                  tablet: 180,
                                  veryNarrow: 120,
                                ),
                                height: context.responsiveSpacing(
                                  small: 150,
                                  medium: 160,
                                  large: 170,
                                  tablet: 180,
                                  veryNarrow: 120,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: context.responsiveSpacing(
                          small: 16,
                          medium: 18,
                          large: 20,
                          tablet: 22,
                          veryNarrow: 12,
                        ),
                      ),
                      // WALLET QR
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'WALLET',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height: context.responsiveSpacing(
                                small: 8,
                                medium: 10,
                                large: 12,
                                tablet: 14,
                                veryNarrow: 6,
                              ),
                            ),
                            Container(
                              padding: context.responsivePadding(
                                small: 12,
                                medium: 14,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? Colors.white
                                    : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 12,
                                    medium: 14,
                                    large: 16,
                                    tablet: 18,
                                    veryNarrow: 10,
                                  ),
                                ),
                              ),
                              child: Image.memory(
                                base64Decode(qpayQrImageWallet!),
                                width: context.responsiveSpacing(
                                  small: 150,
                                  medium: 160,
                                  large: 170,
                                  tablet: 180,
                                  veryNarrow: 120,
                                ),
                                height: context.responsiveSpacing(
                                  small: 150,
                                  medium: 160,
                                  large: 170,
                                  tablet: 180,
                                  veryNarrow: 120,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Single QR code
                  Container(
                    padding: context.responsivePadding(
                      small: 16,
                      medium: 18,
                      large: 20,
                      tablet: 22,
                      veryNarrow: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(
                        context.responsiveBorderRadius(
                          small: 12,
                          medium: 14,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 10,
                        ),
                      ),
                    ),
                    child: Image.memory(
                      base64Decode(
                        hasOwnOrg ? qpayQrImageOwnOrg! : qpayQrImageWallet!,
                      ),
                      width: context.responsiveSpacing(
                        small: 250,
                        medium: 260,
                        large: 270,
                        tablet: 280,
                        veryNarrow: 200,
                      ),
                      height: context.responsiveSpacing(
                        small: 250,
                        medium: 260,
                        large: 270,
                        tablet: 280,
                        veryNarrow: 200,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 20,
                    medium: 24,
                    large: 28,
                    tablet: 32,
                    veryNarrow: 14,
                  ),
                ),
                Text(
                  'QPay апп-аараа QR кодыг уншуулна уу',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 14,
                      medium: 15,
                      large: 16,
                      tablet: 17,
                      veryNarrow: 12,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: context.responsiveSpacing(
                    small: 24,
                    medium: 28,
                    large: 32,
                    tablet: 36,
                    veryNarrow: 18,
                  ),
                ),
                // Check payment button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _checkPaymentStatusFromQR();
                    },
                    icon: Icon(Icons.check_circle_outline, size: 20.sp),
                    label: Text(
                      'Төлбөр шалгах',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(
                          small: 16,
                          medium: 17,
                          large: 18,
                          tablet: 19,
                          veryNarrow: 14,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsiveSpacing(
                          small: 14,
                          medium: 16,
                          large: 18,
                          tablet: 20,
                          veryNarrow: 12,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 12,
                            medium: 14,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
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
      },
    );
  }

  void _showBankAppNotInstalledDialog(QPayBank bank) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Банкны апп олдсонгүй',
            style: TextStyle(color: context.textPrimaryColor),
          ),
          content: Text(
            '${bank.description} апп суулгагдаагүй эсвэл нээгдэхгүй байна. Та апп татах эсвэл QR кодыг хуулж авах уу?',
            style: TextStyle(color: context.textSecondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Болих',
                style: TextStyle(color: context.textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyQRCodeToClipboard(bank.link);
              },
              child: Text(
                'QR код хуулах',
                style: TextStyle(color: AppColors.deepGreen),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAppStore(bank);
              },
              child: Text(
                'Апп татах',
                style: TextStyle(color: AppColors.deepGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyQRCodeToClipboard(String qrData) {
    final qrMatch = RegExp(r'qPay_QRcode=([^&]+)').firstMatch(qrData);
    if (qrMatch != null) {
      final qrCode = Uri.decodeComponent(qrMatch.group(1) ?? '');
      Clipboard.setData(ClipboardData(text: qrCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код хуулагдлаа'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код олдсонгүй'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getBankStoreUrl(QPayBank bank, bool isIOS) {
    final bankName = bank.name.toLowerCase();

    if (isIOS) {
      if (bankName.contains('qpay')) {
        return 'https://apps.apple.com/mn/app/qpay/id1441608142';
      } else if (bankName.contains('khan')) {
        return 'https://apps.apple.com/mn/app/khan-bank/id1178998998';
      } else if (bankName.contains('state')) {
        return 'https://apps.apple.com/mn/app/state-bank-mobile-bank/id1439968858';
      } else if (bankName.contains('xac')) {
        return 'https://apps.apple.com/mn/app/xacbank/id1435546747';
      } else if (bankName.contains('tdb') || bankName.contains('trade')) {
        return 'https://apps.apple.com/mn/app/tdb-online/id1341682855';
      } else if (bankName.contains('social') || bankName.contains('golomt')) {
        return 'https://apps.apple.com/mn/app/social-pay/id907732452';
      } else if (bankName.contains('most')) {
        return 'https://apps.apple.com/mn/app/most-money/id1476831658';
      } else if (bankName.contains('national')) {
        return 'https://apps.apple.com/mn/app/nib/id1477940138';
      } else if (bankName.contains('chinggis')) {
        return 'https://apps.apple.com/mn/app/ckb/id1477634968';
      } else if (bankName.contains('capitron')) {
        return 'https://apps.apple.com/mn/app/capitron-bank/id1498290326';
      } else if (bankName.contains('bogd')) {
        return 'https://apps.apple.com/mn/app/bogd-bank/id1533486058';
      } else if (bankName.contains('trans')) {
        return 'https://apps.apple.com/mn/app/tdb/id1522843170';
      } else if (bankName.contains('m bank')) {
        return 'https://apps.apple.com/mn/app/m-bank/id1538651684';
      } else if (bankName.contains('ard')) {
        return 'https://apps.apple.com/mn/app/ard-app/id1546653588';
      } else if (bankName.contains('toki')) {
        return 'https://apps.apple.com/mn/app/toki/id1568099905';
      } else if (bankName.contains('arig')) {
        return 'https://apps.apple.com/mn/app/arig-bank/id1569785167';
      } else if (bankName.contains('monpay')) {
        return 'https://apps.apple.com/mn/app/monpay/id1491424177';
      } else if (bankName.contains('hipay')) {
        return 'https://apps.apple.com/mn/app/hipay/id1451162498';
      } else if (bankName.contains('happy')) {
        return 'https://apps.apple.com/mn/app/happy-pay/id1590968412';
      }

      return 'https://apps.apple.com/mn/search?term=${Uri.encodeComponent(bank.description)}';
    } else {
      if (bankName.contains('qpay')) {
        return 'https://play.google.com/store/apps/details?id=mn.qpay.wallet';
      } else if (bankName.contains('khan')) {
        return 'https://play.google.com/store/apps/details?id=com.khanbank.khaan';
      } else if (bankName.contains('state')) {
        return 'https://play.google.com/store/apps/details?id=mn.statebank.mobile';
      } else if (bankName.contains('xac')) {
        return 'https://play.google.com/store/apps/details?id=mn.xacbank.mobile';
      } else if (bankName.contains('tdb') || bankName.contains('trade')) {
        return 'https://play.google.com/store/apps/details?id=mn.tdb.mobile';
      } else if (bankName.contains('social') || bankName.contains('golomt')) {
        return 'https://play.google.com/store/apps/details?id=com.golomtbank.mobilebank';
      } else if (bankName.contains('most')) {
        return 'https://play.google.com/store/apps/details?id=mn.most.wallet';
      } else if (bankName.contains('national')) {
        return 'https://play.google.com/store/apps/details?id=mn.nibmobilebank';
      } else if (bankName.contains('chinggis')) {
        return 'https://play.google.com/store/apps/details?id=mn.ckb.mobile';
      } else if (bankName.contains('capitron')) {
        return 'https://play.google.com/store/apps/details?id=mn.capitronbank.mobile';
      } else if (bankName.contains('bogd')) {
        return 'https://play.google.com/store/apps/details?id=mn.bogdbank.mobile';
      } else if (bankName.contains('trans')) {
        return 'https://play.google.com/store/apps/details?id=mn.transbank.mobile';
      } else if (bankName.contains('m bank')) {
        return 'https://play.google.com/store/apps/details?id=mn.mbank.mobile';
      } else if (bankName.contains('ard')) {
        return 'https://play.google.com/store/apps/details?id=mn.ard.app';
      } else if (bankName.contains('toki')) {
        return 'https://play.google.com/store/apps/details?id=com.tokipay';
      } else if (bankName.contains('arig')) {
        return 'https://play.google.com/store/apps/details?id=mn.arigbank.mobile';
      } else if (bankName.contains('monpay')) {
        return 'https://play.google.com/store/apps/details?id=mn.monpay.android';
      } else if (bankName.contains('hipay')) {
        return 'https://play.google.com/store/apps/details?id=mn.hipay';
      } else if (bankName.contains('happy')) {
        return 'https://play.google.com/store/apps/details?id=mn.tdbwallet';
      }

      return 'https://play.google.com/store/search?q=${Uri.encodeComponent(bank.description)}&c=apps';
    }
  }

  Future<void> _openAppStore(QPayBank bank) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final appStoreUrl = _getBankStoreUrl(bank, isIOS);

    try {
      final uri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        totalSelectedAmount: totalSelectedAmount,
        selectedCount: selectedCount,
        invoices: invoices,
        contractUldegdel: _effectiveTotalAmount > 0 ? _effectiveTotalAmount : _contractUldegdel,
        onPaymentTap: () async {
          // Refresh invoice list after payment check
          await _loadNekhemjlekh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // 720x1600 phone will have width ~360-400 and height ~700-850 (considering status bar)
    final isSmallScreen = screenHeight < 900 || screenWidth < 400;
    final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Нэхэмжлэх',
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: context.responsiveIconSize(
                small: 24,
                medium: 26,
                large: 28,
                tablet: 30,
                veryNarrow: 22,
              ),
            ),
            onPressed: isLoading ? null : () => _loadNekhemjlekh(),
            tooltip: 'Шинэчлэх',
          ),
          if (availableContracts.length > 1)
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: context.responsiveIconSize(
                  small: 26,
                  medium: 28,
                  large: 30,
                  tablet: 32,
                  veryNarrow: 22,
                ),
              ),
              onPressed: _showContractSelectionModal,
              tooltip: 'Гэрээ солих',
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Contract info (if multiple contracts)
              if (selectedContractDisplay != null &&
                  availableContracts.length > 1)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  child: GestureDetector(
                    onTap: _showContractSelectionModal,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.deepGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: AppColors.deepGreen,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              selectedContractDisplay!,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.deepGreen,
                            size: 14.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.deepGreen,
                          ),
                        ),
                      )
                    : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: context.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red.withOpacity(0.8),
                                    size: 36.sp,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 14.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16.h),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _loadNekhemjlekh,
                                      borderRadius: BorderRadius.circular(
                                        10.r,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.deepGreen,
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Text(
                                          'Дахин оролдох',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Filter Tabs
                          FilterTabs(
                            selectedFilter: selectedFilter,
                            onFilterChanged: (filterKey) {
                              setState(() {
                                selectedFilter = filterKey;
                              });
                            },
                            getFilterCount: _getFilterCount,
                          ),
                          // Sticky payment section at top (hidden in history mode)
                          if (selectedFilter != 'Paid')
                            PaymentSection(
                              selectedCount: selectedCount,
                              totalSelectedAmount: totalSelectedAmount,
                              onPaymentTap: selectedCount > 0
                                  ? _showPaymentModal
                                  : null,
                            ),
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 8,
                              medium: 10,
                              large: 12,
                              tablet: 14,
                              veryNarrow: 6,
                            ),
                          ),
                          // Scrollable invoice list
                          Expanded(
                            child: () {
                              final filteredInvoices = _getFilteredInvoices();

                              if (filteredInvoices.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: context.responsivePadding(
                                      small: 20,
                                      medium: 22,
                                      large: 24,
                                      tablet: 26,
                                      veryNarrow: 14,
                                    ),
                                    child: OptimizedGlass(
                                      borderRadius: BorderRadius.circular(
                                        context.responsiveBorderRadius(
                                          small: 22,
                                          medium: 24,
                                          large: 26,
                                          tablet: 28,
                                          veryNarrow: 18,
                                        ),
                                      ),
                                      opacity: 0.10,
                                      child: Padding(
                                        padding: context.responsivePadding(
                                          small: 24,
                                          medium: 26,
                                          large: 28,
                                          tablet: 30,
                                          veryNarrow: 18,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: context
                                                  .responsivePadding(
                                                    small: 24,
                                                    medium: 26,
                                                    large: 28,
                                                    tablet: 30,
                                                    veryNarrow: 18,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context
                                                    .accentBackgroundColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                selectedFilter == 'Paid'
                                                    ? Icons.history_rounded
                                                    : Icons
                                                          .receipt_long_rounded,
                                                size: context
                                                    .responsiveIconSize(
                                                      small: 48,
                                                      medium: 52,
                                                      large: 56,
                                                      tablet: 60,
                                                      veryNarrow: 40,
                                                    ),
                                                color:
                                                    context.textSecondaryColor,
                                              ),
                                            ),
                                            SizedBox(
                                              height: context.responsiveSpacing(
                                                small: 24,
                                                medium: 28,
                                                large: 32,
                                                tablet: 36,
                                                veryNarrow: 18,
                                              ),
                                            ),
                                            Text(
                                              selectedFilter == 'Paid'
                                                  ? 'Төлөгдсөн нэхэмжлэл байхгүй'
                                                  : 'Одоогоор нэхэмжлэл байхгүй',
                                              style: TextStyle(
                                                color: context.textPrimaryColor,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                              height: 6.h,
                                            ),
                                            Text(
                                              selectedFilter == 'Paid'
                                                  ? 'Төлөгдсөн нэхэмжлэлийн түүх энд харагдана'
                                                  : 'Шинэ нэхэмжлэл үүсэхэд энд харагдана',
                                              style: TextStyle(
                                                color:
                                                    context.textSecondaryColor,
                                                fontSize: 13.sp,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: _loadNekhemjlekh,
                                color: AppColors.deepGreen,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isVerySmallScreen
                                        ? 12
                                        : (isSmallScreen ? 14 : 16),
                                  ),
                                  child: Column(
                                  children: [
                                    if (selectedFilter != 'Paid' &&
                                        filteredInvoices.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: isVerySmallScreen
                                              ? 14
                                              : (isSmallScreen ? 16 : 18),
                                        ),
                                        child: OptimizedGlass(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          opacity: 0.08,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: toggleSelectAll,
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: isVerySmallScreen
                                                          ? 18
                                                          : (isSmallScreen
                                                                ? 20
                                                                : 22),
                                                      height: isVerySmallScreen
                                                          ? 18
                                                          : (isSmallScreen
                                                                ? 20
                                                                : 22),
                                                      decoration: BoxDecoration(
                                                        gradient: allSelected
                                                            ? LinearGradient(
                                                                colors: [
                                                                  AppColors
                                                                      .deepGreen,
                                                                  AppColors
                                                                      .deepGreen
                                                                      .withOpacity(
                                                                        0.8,
                                                                      ),
                                                                ],
                                                              )
                                                            : null,
                                                        color: allSelected
                                                            ? null
                                                            : Colors
                                                                  .transparent,
                                                        border: Border.all(
                                                          color: allSelected
                                                              ? AppColors
                                                                    .deepGreen
                                                              : context
                                                                    .borderColor,
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6.r,
                                                            ),
                                                      ),
                                                      child: allSelected
                                                          ? Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size:
                                                                  isVerySmallScreen
                                                                  ? 12
                                                                  : (isSmallScreen
                                                                        ? 14
                                                                        : 16),
                                                            )
                                                          : null,
                                                    ),
                                                    SizedBox(
                                                      width: isVerySmallScreen
                                                          ? 10
                                                          : (isSmallScreen
                                                                ? 12
                                                                : 14),
                                                    ),
                                                    Text(
                                                      'Бүгдийг сонгох',
                                                      style: TextStyle(
                                                        color: context
                                                            .textPrimaryColor,
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (selectedFilter != 'Paid' &&
                                        filteredInvoices.isNotEmpty)
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? 10
                                            : (isSmallScreen ? 12 : 16),
                                      ),
                                    ...filteredInvoices.map(
                                      (invoice) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: isVerySmallScreen
                                              ? 10
                                              : (isSmallScreen ? 12 : 16),
                                        ),
                                        child: InvoiceCard(
                                          invoice: invoice,
                                          isHistory: selectedFilter == 'Paid',
                                          isSmallScreen: isSmallScreen,
                                          isVerySmallScreen: isVerySmallScreen,
                                          onToggleExpand: () {
                                            setState(() {
                                              invoice.isExpanded =
                                                  !invoice.isExpanded;
                                            });
                                          },
                                          onToggleSelect:
                                              selectedFilter != 'Paid'
                                              ? () {
                                                  setState(() {
                                                    invoice.isSelected =
                                                        !invoice.isSelected;
                                                  });
                                                }
                                              : null,
                                          onShowVATReceipt:
                                              selectedFilter == 'Paid'
                                              ? () => _showVATReceiptModal(
                                                  invoice.id,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            }(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildInvoiceCard moved to components/Nekhemjlekh/invoice_card.dart
  // Removed old implementation - using InvoiceCard component instead
}
