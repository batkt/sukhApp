/// Гэр бүлийн гишүүн болон урилгын загварууд.
///
/// Гишүүн бүр өөрийн утас, нууц үгтэй тусдаа бүртгэлтэй боловч тоот, гэрээ,
/// нэхэмжлэх, төлбөрөө үндсэн эзэмшигчийнхээс хардаг.
library;

/// Гишүүний эрхийн түвшин
class GishuuniiErkh {
  static const String kharakh = 'Харах';
  static const String kharakhTuluk = 'Харах + Төлөх';

  static const List<String> bugd = [kharakhTuluk, kharakh];

  /// Эрхийн тайлбар — жагсаалт дээр харуулна
  static String tailbar(String erkh) {
    return erkh == kharakh
        ? 'Зөвхөн харах — төлбөр төлөх боломжгүй'
        : 'Харах болон төлбөр төлөх';
  }
}

/// Гэр бүлийн холбоо
class GishuuniiKholboo {
  static const List<String> bugd = [
    'Эхнэр',
    'Нөхөр',
    'Хүү',
    'Охин',
    'Аав',
    'Ээж',
    'Ах',
    'Эгч',
    'Дүү',
    'Бусад',
  ];
}

/// Баталгаажсан, идэвхтэй гэр бүлийн гишүүн
class GerBuliinGishuun {
  final String id;
  final String ovog;
  final String ner;
  final String utas;
  final String mail;
  final String kholboo;
  final String erkh;
  final String tuluv;
  final DateTime? batalgaajsanOgnoo;

  const GerBuliinGishuun({
    required this.id,
    required this.ovog,
    required this.ner,
    required this.utas,
    required this.mail,
    required this.kholboo,
    required this.erkh,
    required this.tuluv,
    this.batalgaajsanOgnoo,
  });

  factory GerBuliinGishuun.fromJson(Map<String, dynamic> json) {
    return GerBuliinGishuun(
      id: json['_id']?.toString() ?? '',
      ovog: json['ovog']?.toString() ?? '',
      ner: json['ner']?.toString() ?? '',
      utas: json['utas']?.toString() ?? '',
      mail: json['mail']?.toString() ?? '',
      kholboo: json['gishuuniiKholboo']?.toString() ?? 'Бусад',
      erkh: json['gishuuniiErkh']?.toString() ?? GishuuniiErkh.kharakhTuluk,
      tuluv: json['gishuuniiTuluv']?.toString() ?? 'Идэвхтэй',
      batalgaajsanOgnoo: _ognooParse(json['gishuunBatalgaajsanOgnoo']),
    );
  }

  /// Дэлгэц дээр харуулах бүтэн нэр
  String get buenNer {
    final buten = [ovog, ner].where((e) => e.trim().isNotEmpty).join(' ').trim();
    return buten.isEmpty ? utas : buten;
  }

  /// Дугуй товчлол (АБ)
  String get uge {
    final ekh = ovog.trim().isNotEmpty ? ovog.trim()[0] : '';
    final khoyor = ner.trim().isNotEmpty ? ner.trim()[0] : '';
    final niit = '$ekh$khoyor'.toUpperCase();
    if (niit.isNotEmpty) return niit;
    return utas.isNotEmpty ? utas[0] : '?';
  }

  bool get tulukhErkhtei => erkh != GishuuniiErkh.kharakh;
}

/// Хүлээгдэж буй урилга (утас нь код баталгаажуулаагүй байгаа)
class GerBuliinUrilga {
  final String id;
  final String utas;
  final String ovog;
  final String ner;
  final String kholboo;
  final String erkh;
  final DateTime? duusakhOgnoo;

  const GerBuliinUrilga({
    required this.id,
    required this.utas,
    required this.ovog,
    required this.ner,
    required this.kholboo,
    required this.erkh,
    this.duusakhOgnoo,
  });

  factory GerBuliinUrilga.fromJson(Map<String, dynamic> json) {
    return GerBuliinUrilga(
      id: json['_id']?.toString() ?? '',
      utas: json['utas']?.toString() ?? '',
      ovog: json['ovog']?.toString() ?? '',
      ner: json['ner']?.toString() ?? '',
      kholboo: json['kholboo']?.toString() ?? 'Бусад',
      erkh: json['erkh']?.toString() ?? GishuuniiErkh.kharakhTuluk,
      duusakhOgnoo: _ognooParse(json['expiresAt']),
    );
  }

  String get buenNer {
    final buten = [ovog, ner].where((e) => e.trim().isNotEmpty).join(' ').trim();
    return buten.isEmpty ? utas : buten;
  }

  /// Урилга дуусахад үлдсэн хугацааны товч тайлбар
  String get uldsenKhugatsaa {
    if (duusakhOgnoo == null) return '';
    final zuruu = duusakhOgnoo!.difference(DateTime.now());
    if (zuruu.isNegative) return 'Хугацаа дууссан';
    if (zuruu.inHours >= 1) return '${zuruu.inHours} цаг үлдсэн';
    if (zuruu.inMinutes >= 1) return '${zuruu.inMinutes} мин үлдсэн';
    return 'Дуусах дөхсөн';
  }
}

/// `GET /gerBuliinGishuud` хариу
class GerBuliinJagsaalt {
  final List<GerBuliinGishuun> gishuud;
  final List<GerBuliinUrilga> urilguud;
  final int khyazgaar;

  /// Хүсэлт гаргасан хүн өөрөө гишүүн үү (тийм бол урих/хасах эрхгүй)
  final bool gishuunEsekh;

  const GerBuliinJagsaalt({
    required this.gishuud,
    required this.urilguud,
    required this.khyazgaar,
    required this.gishuunEsekh,
  });

  factory GerBuliinJagsaalt.fromJson(Map<String, dynamic> json) {
    return GerBuliinJagsaalt(
      gishuud: (json['gishuud'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GerBuliinGishuun.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      urilguud: (json['khuleegdejBuiUrilguud'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GerBuliinUrilga.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      khyazgaar: (json['dundKhyazgaar'] as num?)?.toInt() ?? 5,
      gishuunEsekh: json['gishuunEsekh'] == true,
    );
  }

  /// Дахин гишүүн урих зай үлдсэн эсэх
  bool get nemekhBolomjtoi => (gishuud.length + urilguud.length) < khyazgaar;

  bool get khooson => gishuud.isEmpty && urilguud.isEmpty;
}

DateTime? _ognooParse(dynamic utga) {
  if (utga == null) return null;
  return DateTime.tryParse(utga.toString())?.toLocal();
}
