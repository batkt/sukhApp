import 'package:sukh_app/utils/format_util.dart';

// Nekhemjlekh data models
class NekhemjlekhItem {
  final String id;
  final String baiguullagiinNer;
  final String baiguullagiinUtas;
  final String baiguullagiinKhayag;
  final String ovog;
  final String ner;
  final String register;
  final String khayag;
  final String orts;
  final String gereeniiDugaar;
  final String nekhemjlekhiinOgnoo;
  final double niitTulbur;
  final double niitTulburOriginal;
  final double uldegdel;
  final List<String> utas;
  final String dansniiDugaar;
  final String tuluv;
  final String bairNer;
  final String toot;
  final String billingId;
  final NekhemjlekhMedeelel? medeelel;

  final double? ekhniiUldegdel;
  bool isSelected;
  bool isExpanded;

  NekhemjlekhItem({
    required this.id,
    required this.baiguullagiinNer,
    this.baiguullagiinUtas = '',
    this.baiguullagiinKhayag = '',
    required this.ovog,
    required this.ner,
    required this.register,
    required this.khayag,
    this.orts = '',
    required this.gereeniiDugaar,
    required this.nekhemjlekhiinOgnoo,
    required this.niitTulbur,
    this.niitTulburOriginal = 0.0,
    this.uldegdel = 0.0,
    required this.utas,
    required this.dansniiDugaar,
    required this.tuluv,
    required this.bairNer,
    required this.toot,
    this.billingId = '',
    this.medeelel,

    this.ekhniiUldegdel,
    this.isSelected = false,
    this.isExpanded = false,
  });

  factory NekhemjlekhItem.fromJson(Map<String, dynamic> json) {
    // Check if medeelel exists, otherwise create it from root-level fields
    NekhemjlekhMedeelel? medeelel;

    if (json['medeelel'] != null) {
      medeelel = NekhemjlekhMedeelel.fromJson(json['medeelel']);
    } else {
      final rootZardluud = json['zardluud'];
      final rootToot = json['toot']?.toString() ?? '';
      final rootTemdeglel = json['temdeglel']?.toString() ?? '';
      final rootTailbar = json['tailbar']?.toString();
      final rootGuilgeenuud = json['guilgeenuud'];

      if (rootZardluud != null ||
          rootToot.isNotEmpty ||
          rootTemdeglel.isNotEmpty ||
          rootGuilgeenuud != null) {
        medeelel = NekhemjlekhMedeelel(
          zardluud: rootZardluud != null
              ? (rootZardluud as List).map((z) => Zardal.fromJson(z)).toList()
              : [],
          guilgeenuud: rootGuilgeenuud != null
              ? (rootGuilgeenuud as List)
                    .map((g) => Guilgee.fromJson(g))
                    .toList()
              : null,
          toot: rootToot,
          temdeglel: rootTemdeglel,
          tailbar: rootTailbar,
        );
      }
    }

    // Compute ekhniiUldegdel: use top-level if present, else sum from zardluud + guilgeenuud (matches web)
    double? ekhniiUldegdel;
    if (json['ekhniiUldegdel'] != null) {
      ekhniiUldegdel = (json['ekhniiUldegdel'] as num).toDouble();
    } else if (medeelel != null) {
      double fromZardluud = 0;
      for (final z in medeelel.zardluud) {
        if (z.isEkhniiUldegdel) {
          // Match web: dun ?? tulukhDun ?? undsenDun ?? tariff
          final amt = z.dun != 0
              ? z.dun
              : (z.tulukhDun ?? z.undsenDun ?? z.tariff);
          if (amt != 0) fromZardluud += amt;
        }
      }
      double fromGuilgee = 0;
      if (medeelel.guilgeenuud != null) {
        for (final g in medeelel.guilgeenuud!) {
          if (g.ekhniiUldegdelEsekh) {
            final base = g.tulukhDun ?? g.undsenDun ?? 0.0;
            final tulsun = g.tulsunDun ?? 0.0;
            final amt = base - tulsun;
            if (amt != 0) fromGuilgee += amt;
          }
        }
      }
      final total = fromZardluud + fromGuilgee;
      if (total != 0) ekhniiUldegdel = total;
    }

    return NekhemjlekhItem(
      id: json['_id']?.toString() ?? '',
      baiguullagiinNer: json['baiguullagiinNer']?.toString() ?? '',
      baiguullagiinUtas: json['baiguullagiinUtas']?.toString() ?? '',
      baiguullagiinKhayag: json['baiguullagiinKhayag']?.toString() ?? '',
      ovog: json['ovog']?.toString() ?? '',
      ner: json['ner']?.toString() ?? '',
      register: json['register']?.toString() ?? '',
      khayag: json['khayag']?.toString() ?? '',
      orts: json['orts']?.toString() ?? '',
      gereeniiDugaar: json['gereeniiDugaar']?.toString() ?? '',
      nekhemjlekhiinOgnoo:
          json['nekhemjlekhiinOgnoo']?.toString() ??
          json['ognoo']?.toString() ??
          '',
      niitTulbur: (json['niitTulbur'] ?? 0).toDouble(),
      niitTulburOriginal: (json['niitTulburOriginal'] ?? 0).toDouble(),
      uldegdel: (json['uldegdel'] ?? 0).toDouble(),
      utas: json['utas'] != null
          ? (json['utas'] as List).map((e) => e.toString()).toList()
          : [],
      dansniiDugaar: json['dansniiDugaar']?.toString() ?? '',
      tuluv: json['tuluv']?.toString() ?? 'Төлөөгүй',
      bairNer: json['bairNer']?.toString() ?? '',
      toot: json['toot']?.toString() ?? '',
      billingId: json['billingId']?.toString() ?? json['gereeniiDugaar']?.toString() ?? '',
      medeelel: medeelel,
      ekhniiUldegdel: ekhniiUldegdel,

    );
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(nekhemjlekhiinOgnoo).toLocal();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return nekhemjlekhiinOgnoo;
    }
  }

  /// Mirrors web's getPaymentStatusLabel + backend pre-save logic:
  /// When paid: backend sets niitTulbur=0, uldegdel=0, tuluv='Төлсөн'
  /// niitTulburOriginal is preserved as the original amount.
  bool get isPaid {
    // Explicit paid status from backend (most reliable)
    final t = tuluv.toLowerCase().trim();
    if (t == 'төлсөн' || t == 'paid' || t == 'paid_success') return true;
    // uldegdel==0 AND niitTulburOriginal>0 → backend has marked this as paid
    // (backend sets niitTulbur=0 too when paid, so we use niitTulburOriginal)
    if (uldegdel == 0 && niitTulburOriginal > 0) return true;
    if (uldegdel < 0) return true;
    return false;
  }

  /// The amount that needs to be paid (Remaining balance)
  double get effectiveNiitTulbur => uldegdel;

  String get formattedAmount {
    final total = effectiveNiitTulbur;
    return '${formatNumber(total, 2)}₮';
  }

  String get displayName =>
      '$ovog $ner'.trim().isNotEmpty ? '$ovog $ner' : baiguullagiinNer;
  String get phoneNumber => utas.isNotEmpty ? utas.first : '';
}

class NekhemjlekhMedeelel {
  final List<Zardal> zardluud;
  final List<Guilgee>? guilgeenuud;
  final String toot;
  final String temdeglel;
  final String? tailbar;

  NekhemjlekhMedeelel({
    required this.zardluud,
    this.guilgeenuud,
    required this.toot,
    required this.temdeglel,
    this.tailbar,
  });

  factory NekhemjlekhMedeelel.fromJson(Map<String, dynamic> json) {
    return NekhemjlekhMedeelel(
      zardluud: json['zardluud'] != null
          ? (json['zardluud'] as List).map((z) => Zardal.fromJson(z)).toList()
          : [],
      guilgeenuud: json['guilgeenuud'] != null
          ? (json['guilgeenuud'] as List)
                .map((g) => Guilgee.fromJson(g))
                .toList()
          : null,
      toot: json['toot']?.toString() ?? '',
      temdeglel: json['temdeglel']?.toString() ?? '',
      tailbar: json['tailbar']?.toString(),
    );
  }
}

class Zardal {
  final String ner;
  final String turul;
  final double tariff;
  final String tariffUsgeer;
  final String zardliinTurul;
  final double dun;
  final double? tulukhDun;
  final double? undsenDun;
  final double? zaaltDefaultDun;
  final double? togtmolUtga;
  final double? zaaltTariff;
  final bool isEkhniiUldegdel;
  final bool zaalt; // цахилгаан (electricity) - variable charge

  Zardal({
    required this.ner,
    required this.turul,
    required this.tariff,
    required this.tariffUsgeer,
    required this.zardliinTurul,
    required this.dun,
    this.tulukhDun,
    this.undsenDun,
    this.zaaltDefaultDun,
    this.togtmolUtga,
    this.zaaltTariff,
    this.isEkhniiUldegdel = false,
    this.zaalt = false,
  });

  factory Zardal.fromJson(Map<String, dynamic> json) {
    final ner = (json['ner']?.toString() ?? '').toLowerCase();
    return Zardal(
      ner: json['ner']?.toString() ?? '',
      turul: json['turul']?.toString() ?? '',
      tariff: (json['tariff'] ?? 0).toDouble(),
      tariffUsgeer: json['tariffUsgeer']?.toString() ?? '₮',
      zardliinTurul: json['zardliinTurul']?.toString() ?? '',
      dun: (json['dun'] ?? 0).toDouble(),
      tulukhDun: json['tulukhDun'] != null
          ? (json['tulukhDun'] as num).toDouble()
          : null,
      undsenDun: json['undsenDun'] != null
          ? (json['undsenDun'] as num).toDouble()
          : null,
      zaaltDefaultDun: json['zaaltDefaultDun'] != null
          ? (json['zaaltDefaultDun'] as num).toDouble()
          : null,
      togtmolUtga: json['togtmolUtga'] != null
          ? (json['togtmolUtga'] as num).toDouble()
          : null,
      zaaltTariff: json['zaaltTariff'] != null
          ? (json['zaaltTariff'] as num).toDouble()
          : null,
      isEkhniiUldegdel:
          json['isEkhniiUldegdel'] == true ||
          ner.contains('эхний үлдэгдэл') ||
          ner.contains('ekhniuldegdel') ||
          ner.contains('ekhnii uldegdel'),
      zaalt: json['zaalt'] == true || ner.contains('цахилгаан'),
    );
  }

  /// Whether this zardal should be shown in invoice breakdown (Show everything with an amount)
  bool get isDisplayable {
    // Show everything that has a positive amount, unless it's a zero-sum system field
    if (displayAmount != 0) return true;

    // Fallback for names we know should be shown
    final t = turul.toLowerCase();
    if (t == 'тогтмол' || t == 'дурын') return true;
    if (isEkhniiUldegdel) return true;
    if (zaalt) return true;
    if (ner.toLowerCase().contains('цахилгаан')) return true;
    
    return false;
  }

  String get formattedTariff {
    return '${formatNumber(tariff, 2)}$tariffUsgeer';
  }

  // Get the actual amount to display (matches web: dun, tulukhDun, undsenDun, tariff)
  double get displayAmount {
    if (zaaltDefaultDun != null && zaaltDefaultDun! > 0)
      return zaaltDefaultDun!;
    if (togtmolUtga != null && togtmolUtga! > 0) return togtmolUtga!;
    if (dun > 0) return dun;
    // For ekhniiUldegdel, API may send amount in tulukhDun/undsenDun/tariff when dun=0
    if (isEkhniiUldegdel) {
      final amt = tulukhDun ?? undsenDun ?? (tariff > 0 ? tariff : 0.0);
      if (amt > 0) return amt;
    }
    if (tariff > 0) return tariff;
    // For zaalt (цахилгаан), fallback to zaaltTariff if dun/tariff are 0
    if (zaalt && zaaltTariff != null && zaaltTariff! > 0) return zaaltTariff!;
    return 0;
  }

  String get formattedDisplayAmount {
    return '${formatNumber(displayAmount, 2)}₮';
  }
}

class Guilgee {
  final String? ognoo;
  final double? tulukhDun;
  final double? undsenDun;
  final double? tulsunDun;
  final double? dun;
  final String? tailbar;
  final String? zardliinNer;
  final String? turul;
  final String? gereeniiId;
  final String? guilgeeKhiisenOgnoo;
  final String? guilgeeKhiisenAjiltniiNer;
  final String? guilgeeKhiisenAjiltniiId;
  final int? avlagaGuilgeeIndex;
  final String? id;
  final bool ekhniiUldegdelEsekh;
  final bool isLinked;

  Guilgee({
    this.ognoo,
    this.tulukhDun,
    this.undsenDun,
    this.tulsunDun,
    this.dun,
    this.tailbar,
    this.zardliinNer,
    this.turul,
    this.gereeniiId,
    this.guilgeeKhiisenOgnoo,
    this.guilgeeKhiisenAjiltniiNer,
    this.guilgeeKhiisenAjiltniiId,
    this.avlagaGuilgeeIndex,
    this.id,
    this.ekhniiUldegdelEsekh = false,
    this.isLinked = false,
  });

  factory Guilgee.fromJson(Map<String, dynamic> json) {
    return Guilgee(
      ognoo: json['ognoo']?.toString(),
      tulukhDun: json['tulukhDun'] != null
          ? (json['tulukhDun'] as num).toDouble()
          : null,
      undsenDun: json['undsenDun'] != null
          ? (json['undsenDun'] as num).toDouble()
          : null,
      tulsunDun: json['tulsunDun'] != null
          ? (json['tulsunDun'] as num).toDouble()
          : null,
      dun: json['dun'] != null ? (json['dun'] as num).toDouble() : null,
      tailbar: json['tailbar']?.toString() ?? json['zardliinNer']?.toString(),
      zardliinNer: json['zardliinNer']?.toString(),
      turul: json['turul']?.toString(),
      gereeniiId: json['gereeniiId']?.toString(),
      guilgeeKhiisenOgnoo: json['guilgeeKhiisenOgnoo']?.toString(),
      guilgeeKhiisenAjiltniiNer: json['guilgeeKhiisenAjiltniiNer']?.toString(),
      guilgeeKhiisenAjiltniiId: json['guilgeeKhiisenAjiltniiId']?.toString(),
      avlagaGuilgeeIndex: json['avlagaGuilgeeIndex'] as int?,
      id: json['_id']?.toString(),
      ekhniiUldegdelEsekh:
          json['ekhniiUldegdelEsekh'] == true ||
          (json['zardliinNer']?.toString().toLowerCase().contains('эхний үлдэгдэл') ?? false),
      isLinked: json['isLinked'] == true,
    );
  }
}

class QPayBank {
  final String name;
  final String description;
  final String logo;
  final String link;

  QPayBank({
    required this.name,
    required this.description,
    required this.logo,
    required this.link,
  });

  factory QPayBank.fromJson(Map<String, dynamic> json) {
    return QPayBank(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

// VAT Receipt data models
class VATReceipt {
  final String id;
  final String qrData;
  final String? lottery;
  final double totalAmount;
  final double totalVAT;
  final double totalCityTax;
  final String districtCode;
  final String merchantTin;
  final String branchNo;
  final String posNo;
  final String type;
  final String date;
  final List<VATReceiptItem> receipts;
  final List<VATPayment> payments;
  final String nekhemjlekhiinId;
  final String gereeniiDugaar;
  final int utas;
  final String? receiptId;
  final String? status;

  VATReceipt({
    required this.id,
    required this.qrData,
    this.lottery,
    required this.totalAmount,
    required this.totalVAT,
    required this.totalCityTax,
    required this.districtCode,
    required this.merchantTin,
    required this.branchNo,
    required this.posNo,
    required this.type,
    required this.date,
    required this.receipts,
    required this.payments,
    required this.nekhemjlekhiinId,
    required this.gereeniiDugaar,
    required this.utas,
    this.receiptId,
    this.status,
  });

  factory VATReceipt.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double (handles both string and number)
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely convert to int (handles both string and number)
    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return VATReceipt(
      id: json['id'] ?? json['_id'] ?? '',
      qrData: json['qrData'] ?? '',
      lottery: json['lottery'],
      totalAmount: safeToDouble(json['totalAmount']),
      totalVAT: safeToDouble(json['totalVAT']),
      totalCityTax: safeToDouble(json['totalCityTax']),
      districtCode: json['districtCode'] ?? '',
      merchantTin: json['merchantTin'] ?? '',
      branchNo: json['branchNo'] ?? '',
      posNo: json['posNo'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      receipts: json['receipts'] != null
          ? (json['receipts'] as List)
                .map((r) => VATReceiptItem.fromJson(r))
                .toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List)
                .map((p) => VATPayment.fromJson(p))
                .toList()
          : [],
      nekhemjlekhiinId: json['nekhemjlekhiinId'] ?? '',
      gereeniiDugaar: json['gereeniiDugaar'] ?? '',
      utas: safeToInt(json['utas']),
      receiptId: json['receiptId'],
      status: json['status']?.toString(),
    );
  }

  factory VATReceipt.fromWalletPayment(Map<String, dynamic> json) {
    final vat = json['vatInformation'] as Map<String, dynamic>?;
    
    // Try to get date from various possible fields
    String dateStr = json['ognoo']?.toString() ?? 
                     json['date']?.toString() ?? 
                     DateTime.now().toIso8601String();

    // In this API, vatAmount often represents the total amount of the receipt
    final totalAmountValue = (json['totalAmount'] ?? json['amount'] ?? vat?['vatAmount'] ?? 0).toDouble();

    return VATReceipt(
      id: vat?['vatDdtd'] ?? '',
      qrData: vat?['vatQrData'] ?? '',
      lottery: vat?['vatLotteryNo'],
      totalAmount: totalAmountValue,
      totalVAT: totalAmountValue / 11, // Standard VAT calculation if not provided separately
      totalCityTax: 0,
      districtCode: '',
      merchantTin: '',
      branchNo: '001',
      posNo: '0001',
      type: 'B2C_RECEIPT',
      date: dateStr,
      receipts: [],
      payments: [],
      nekhemjlekhiinId: json['paymentId'] ?? json['walletPaymentId'] ?? '',
      gereeniiDugaar: json['invoiceNo'] ?? '',
      utas: 0,
      receiptId: vat?['vatDdtd'] ?? '',
      status: vat?['vatStatus']?.toString() ?? vat?['status']?.toString(),
    );
  }

  String get formattedAmount {
    return '${formatNumber(totalAmount, 2)}₮';
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date.replaceAll(' ', 'T')).toLocal();
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}

class VATReceiptItem {
  final double totalAmount;
  final double totalVAT;
  final double totalCityTax;
  final String taxType;
  final String merchantTin;
  final List<VATItem> items;

  VATReceiptItem({
    required this.totalAmount,
    required this.totalVAT,
    required this.totalCityTax,
    required this.taxType,
    required this.merchantTin,
    required this.items,
  });

  factory VATReceiptItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double (handles both string and number)
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return VATReceiptItem(
      totalAmount: safeToDouble(json['totalAmount']),
      totalVAT: safeToDouble(json['totalVAT']),
      totalCityTax: safeToDouble(json['totalCityTax']),
      taxType: json['taxType'] ?? '',
      merchantTin: json['merchantTin'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => VATItem.fromJson(i)).toList()
          : [],
    );
  }
}

class VATItem {
  final String name;
  final String barCodeType;
  final String classificationCode;
  final String measureUnit;
  final String qty;
  final String unitPrice;
  final String totalCityTax;
  final String totalAmount;

  VATItem({
    required this.name,
    required this.barCodeType,
    required this.classificationCode,
    required this.measureUnit,
    required this.qty,
    required this.unitPrice,
    required this.totalCityTax,
    required this.totalAmount,
  });

  factory VATItem.fromJson(Map<String, dynamic> json) {
    return VATItem(
      name: json['name'] ?? '',
      barCodeType: json['barCodeType'] ?? '',
      classificationCode: json['classificationCode'] ?? '',
      measureUnit: json['measureUnit'] ?? '',
      qty: json['qty']?.toString() ?? '0',
      unitPrice: json['unitPrice']?.toString() ?? '0',
      totalCityTax: json['totalCityTax']?.toString() ?? '0',
      totalAmount: json['totalAmount']?.toString() ?? '0',
    );
  }
}

class VATPayment {
  final String code;
  final String paidAmount;
  final String status;

  VATPayment({
    required this.code,
    required this.paidAmount,
    required this.status,
  });

  factory VATPayment.fromJson(Map<String, dynamic> json) {
    return VATPayment(
      code: json['code'] ?? '',
      paidAmount: json['paidAmount']?.toString() ?? '0',
      status: json['status'] ?? '',
    );
  }
}
