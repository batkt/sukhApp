import 'dart:core';

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
      utas: json['utas'] != null
          ? (json['utas'] as List).map((e) => e.toString()).toList()
          : [],
      dansniiDugaar: json['dansniiDugaar']?.toString() ?? '',
      tuluv: json['tuluv']?.toString() ?? 'Төлөөгүй',
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

  /// Total including ekhniiUldegdel and avlaga when backend niitTulbur may not include them (matches web)
  double get effectiveNiitTulbur {
    double total = niitTulbur + (ekhniiUldegdel ?? 0);
    // Add avlaga from guilgeenuud (merged from gereeniiTulukhAvlaga)
    if (medeelel?.guilgeenuud != null) {
      for (final g in medeelel!.guilgeenuud!) {
        final t = g.turul?.toLowerCase() ?? '';
        if ((t == 'avlaga' || t == 'авлага') && !g.ekhniiUldegdelEsekh) {
          final amt = (g.tulukhDun ?? g.undsenDun ?? 0.0) - (g.tulsunDun ?? 0.0);
          if (amt > 0) total += amt;
        }
      }
    }
    return total;
  }

  String get formattedAmount {
    final total = effectiveNiitTulbur;
    final formatted = total
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
      isEkhniiUldegdel: json['isEkhniiUldegdel'] == true ||
          ner.contains('эхний үлдэгдэл') ||
          ner.contains('ekhniuldegdel') ||
          ner.contains('ekhnii uldegdel'),
      zaalt: json['zaalt'] == true || ner.contains('цахилгаан'),
    );
  }

  /// Whether this zardal should be shown in invoice breakdown (Тогтмол, Дурын, Эхний үлдэгдэл, цахилгаан)
  bool get isDisplayable {
    final t = turul.toLowerCase();
    if (t == 'тогтмол' || t == 'дурын') return true;
    if (isEkhniiUldegdel) return true;
    if (zaalt) return true;
    if (ner.toLowerCase().contains('цахилгаан') &&
        !ner.toLowerCase().contains('дундын өмчлөл')) return true;
    return false;
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

  // Get the actual amount to display (matches web: dun, tulukhDun, undsenDun, tariff)
  double get displayAmount {
    if (zaaltDefaultDun != null && zaaltDefaultDun! > 0) return zaaltDefaultDun!;
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
    final amount = displayAmount;
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
  final double? undsenDun;
  final double? tulsunDun;
  final String? tailbar;
  final String? turul;
  final String? gereeniiId;
  final String? guilgeeKhiisenOgnoo;
  final String? guilgeeKhiisenAjiltniiNer;
  final String? guilgeeKhiisenAjiltniiId;
  final int? avlagaGuilgeeIndex;
  final String? id;
  final bool ekhniiUldegdelEsekh;

  Guilgee({
    this.ognoo,
    this.tulukhDun,
    this.undsenDun,
    this.tulsunDun,
    this.tailbar,
    this.turul,
    this.gereeniiId,
    this.guilgeeKhiisenOgnoo,
    this.guilgeeKhiisenAjiltniiNer,
    this.guilgeeKhiisenAjiltniiId,
    this.avlagaGuilgeeIndex,
    this.id,
    this.ekhniiUldegdelEsekh = false,
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
      tailbar: json['tailbar']?.toString(),
      turul: json['turul']?.toString(),
      gereeniiId: json['gereeniiId']?.toString(),
      guilgeeKhiisenOgnoo: json['guilgeeKhiisenOgnoo']?.toString(),
      guilgeeKhiisenAjiltniiNer: json['guilgeeKhiisenAjiltniiNer']?.toString(),
      guilgeeKhiisenAjiltniiId: json['guilgeeKhiisenAjiltniiId']?.toString(),
      avlagaGuilgeeIndex: json['avlagaGuilgeeIndex'] as int?,
      id: json['_id']?.toString(),
      ekhniiUldegdelEsekh: json['ekhniiUldegdelEsekh'] == true,
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
      final dateTime = DateTime.parse(date.replaceAll(' ', 'T')).toLocal();
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
