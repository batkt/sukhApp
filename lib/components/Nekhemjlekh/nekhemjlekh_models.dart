import 'dart:core';

// Nekhemjlekh data models
class NekhemjlekhItem {
  final String id;
  final String baiguullagiinNer;
  final String ovog;
  final String ner;
  final String register;
  final String khayag;
  final String gereeniiDugaar;
  final String nekhemjlekhiinOgnoo;
  final double niitTulbur;
  final List<String> utas;
  final String dansniiDugaar;
  final String tuluv;
  final NekhemjlekhMedeelel? medeelel;
  final double? ekhniiUldegdel;
  bool isSelected;
  bool isExpanded;

  NekhemjlekhItem({
    required this.id,
    required this.baiguullagiinNer,
    required this.ovog,
    required this.ner,
    required this.register,
    required this.khayag,
    required this.gereeniiDugaar,
    required this.nekhemjlekhiinOgnoo,
    required this.niitTulbur,
    required this.utas,
    required this.dansniiDugaar,
    required this.tuluv,
    this.medeelel,
    this.ekhniiUldegdel,
    this.isSelected = false,
    this.isExpanded = false,
  });

  factory NekhemjlekhItem.fromJson(Map<String, dynamic> json) {
    // Check if medeelel exists, otherwise create it from root-level fields
    NekhemjlekhMedeelel? medeelel;
    
    if (json['medeelel'] != null) {
      // Use medeelel if it exists
      medeelel = NekhemjlekhMedeelel.fromJson(json['medeelel']);
    } else {
      // Check if zardluud exists at root level
      final rootZardluud = json['zardluud'];
      final rootToot = json['toot']?.toString() ?? '';
      final rootTemdeglel = json['temdeglel']?.toString() ?? '';
      final rootTailbar = json['tailbar']?.toString();
      final rootGuilgeenuud = json['guilgeenuud'];
      
      // If zardluud or other medeelel fields exist at root, create medeelel
      if (rootZardluud != null || rootToot.isNotEmpty || rootTemdeglel.isNotEmpty || rootGuilgeenuud != null) {
        medeelel = NekhemjlekhMedeelel(
          zardluud: rootZardluud != null
              ? (rootZardluud as List).map((z) => Zardal.fromJson(z)).toList()
              : [],
          guilgeenuud: rootGuilgeenuud != null
              ? (rootGuilgeenuud as List).map((g) => Guilgee.fromJson(g)).toList()
              : null,
          toot: rootToot,
          temdeglel: rootTemdeglel,
          tailbar: rootTailbar,
        );
      }
    }
    
    return NekhemjlekhItem(
      id: json['_id']?.toString() ?? '',
      baiguullagiinNer: json['baiguullagiinNer']?.toString() ?? '',
      ovog: json['ovog']?.toString() ?? '',
      ner: json['ner']?.toString() ?? '',
      register: json['register']?.toString() ?? '',
      khayag: json['khayag']?.toString() ?? '',
      gereeniiDugaar: json['gereeniiDugaar']?.toString() ?? '',
      nekhemjlekhiinOgnoo:
          json['nekhemjlekhiinOgnoo']?.toString() ??
          json['ognoo']?.toString() ??
          '',
      niitTulbur: (json['niitTulbur'] ?? 0).toDouble(),
      utas: json['utas'] != null
          ? (json['utas'] as List).map((e) => e.toString()).toList()
          : [],
      dansniiDugaar: json['dansniiDugaar']?.toString() ?? '',
      tuluv: json['tuluv']?.toString() ?? 'Төлөөгүй',
      medeelel: medeelel,
      ekhniiUldegdel: json['ekhniiUldegdel'] != null
          ? (json['ekhniiUldegdel'] as num).toDouble()
          : null,
    );
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(nekhemjlekhiinOgnoo);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return nekhemjlekhiinOgnoo;
    }
  }

  String get formattedAmount {
    final formatted = niitTulbur
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted₮';
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
  final double? zaaltDefaultDun;
  final double? togtmolUtga;
  final double? zaaltTariff;

  Zardal({
    required this.ner,
    required this.turul,
    required this.tariff,
    required this.tariffUsgeer,
    required this.zardliinTurul,
    required this.dun,
    this.zaaltDefaultDun,
    this.togtmolUtga,
    this.zaaltTariff,
  });

  factory Zardal.fromJson(Map<String, dynamic> json) {
    return Zardal(
      ner: json['ner']?.toString() ?? '',
      turul: json['turul']?.toString() ?? '',
      tariff: (json['tariff'] ?? 0).toDouble(),
      tariffUsgeer: json['tariffUsgeer']?.toString() ?? '₮',
      zardliinTurul: json['zardliinTurul']?.toString() ?? '',
      dun: (json['dun'] ?? 0).toDouble(),
      zaaltDefaultDun: json['zaaltDefaultDun'] != null
          ? (json['zaaltDefaultDun'] as num).toDouble()
          : null,
      togtmolUtga: json['togtmolUtga'] != null
          ? (json['togtmolUtga'] as num).toDouble()
          : null,
      zaaltTariff: json['zaaltTariff'] != null
          ? (json['zaaltTariff'] as num).toDouble()
          : null,
    );
  }

  String get formattedTariff {
    final formatted = tariff
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted$tariffUsgeer';
  }

  // Get the actual amount to display (prioritize zaaltDefaultDun, then togtmolUtga, then dun)
  double get displayAmount {
    // Debug logging for amount decision
    print(
      '🔎 ZARDAL displayAmount calc for "$ner": '
      'dun=$dun, zaaltDefaultDun=$zaaltDefaultDun, '
      'togtmolUtga=$togtmolUtga, tariff=$tariff',
    );

    if (zaaltDefaultDun != null && zaaltDefaultDun! > 0) {
      print('🔎 ZARDAL "$ner": using zaaltDefaultDun=$zaaltDefaultDun');
      return zaaltDefaultDun!;
    }
    if (togtmolUtga != null && togtmolUtga! > 0) {
      print('🔎 ZARDAL "$ner": using togtmolUtga=$togtmolUtga');
      return togtmolUtga!;
    }
    // If dun is explicitly set and > 0, use it
    if (dun > 0) {
      print('🔎 ZARDAL "$ner": using dun=$dun');
      return dun;
    }
    // Backend sometimes sends dun = 0 but tariff > 0 (e.g. "Хог" fixed fee).
    // In that case, fall back to tariff so the user doesn't see 0.00₮.
    if (tariff > 0) {
      print('🔎 ZARDAL "$ner": using tariff fallback=$tariff');
      return tariff;
    }
    print('🔎 ZARDAL "$ner": all values 0, returning 0');
    return 0;
  }

  String get formattedDisplayAmount {
    final amount = displayAmount;
    print('🔎 ZARDAL "$ner": final displayAmount=$amount');
    final formatted = amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted₮';
  }
}

class Guilgee {
  final String? ognoo;
  final double? tulukhDun;
  final double? tulsunDun;
  final String? tailbar;
  final String? turul;
  final String? gereeniiId;
  final String? guilgeeKhiisenOgnoo;
  final String? guilgeeKhiisenAjiltniiNer;
  final String? guilgeeKhiisenAjiltniiId;
  final int? avlagaGuilgeeIndex;
  final String? id;

  Guilgee({
    this.ognoo,
    this.tulukhDun,
    this.tulsunDun,
    this.tailbar,
    this.turul,
    this.gereeniiId,
    this.guilgeeKhiisenOgnoo,
    this.guilgeeKhiisenAjiltniiNer,
    this.guilgeeKhiisenAjiltniiId,
    this.avlagaGuilgeeIndex,
    this.id,
  });

  factory Guilgee.fromJson(Map<String, dynamic> json) {
    return Guilgee(
      ognoo: json['ognoo']?.toString(),
      tulukhDun: json['tulukhDun'] != null
          ? (json['tulukhDun'] as num).toDouble()
          : null,
      tulsunDun: json['tulsunDun'] != null
          ? (json['tulsunDun'] as num).toDouble()
          : null,
      tailbar: json['tailbar']?.toString(),
      turul: json['turul']?.toString(),
      gereeniiId: json['gereeniiId']?.toString(),
      guilgeeKhiisenOgnoo: json['guilgeeKhiisenOgnoo']?.toString(),
      guilgeeKhiisenAjiltniiNer: json['guilgeeKhiisenAjiltniiNer']?.toString(),
      guilgeeKhiisenAjiltniiId: json['guilgeeKhiisenAjiltniiId']?.toString(),
      avlagaGuilgeeIndex: json['avlagaGuilgeeIndex'] as int?,
      id: json['_id']?.toString(),
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
  });

  factory VATReceipt.fromJson(Map<String, dynamic> json) {
    return VATReceipt(
      id: json['_id'] ?? json['id'] ?? '',
      qrData: json['qrData'] ?? '',
      lottery: json['lottery'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalVAT: (json['totalVAT'] ?? 0).toDouble(),
      totalCityTax: (json['totalCityTax'] ?? 0).toDouble(),
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
      utas: json['utas'] ?? '',
      receiptId: json['receiptId'],
    );
  }

  String get formattedAmount {
    final formatted = totalAmount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted₮';
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date.replaceAll(' ', 'T'));
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
    return VATReceiptItem(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalVAT: (json['totalVAT'] ?? 0).toDouble(),
      totalCityTax: (json['totalCityTax'] ?? 0).toDouble(),
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
