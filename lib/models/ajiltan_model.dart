class AjiltanResponse {
  final int khuudasniiDugaar;
  final int khuudasniiKhemjee;
  final List<Ajiltan> jagsaalt;
  final int niitMur;
  final int niitKhuudas;

  AjiltanResponse({
    required this.khuudasniiDugaar,
    required this.khuudasniiKhemjee,
    required this.jagsaalt,
    required this.niitMur,
    required this.niitKhuudas,
  });

  factory AjiltanResponse.fromJson(Map<String, dynamic> json) {
    return AjiltanResponse(
      khuudasniiDugaar: json['khuudasniiDugaar'] ?? 0,
      khuudasniiKhemjee: json['khuudasniiKhemjee'] ?? 0,
      jagsaalt: (json['jagsaalt'] as List<dynamic>?)
              ?.map((e) => Ajiltan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      niitMur: json['niitMur'] ?? 0,
      niitKhuudas: json['niitKhuudas'] ?? 0,
    );
  }
}

class Ajiltan {
  final String id;
  final String ner;
  final String ovog;
  final String utas;
  final String mail;
  final String register;
  final List<dynamic> tsonkhniiErkhuud;
  final List<String> barilguud;
  final List<dynamic> zogsoolKhaalga;
  final String ajildOrsonOgnoo;
  final String baiguullagiinId;
  final String nevtrekhNer;
  final List<dynamic> tuukh;
  final String createdAt;
  final String updatedAt;
  final Tokhirgoo tokhirgoo;

  Ajiltan({
    required this.id,
    required this.ner,
    required this.ovog,
    required this.utas,
    required this.mail,
    required this.register,
    required this.tsonkhniiErkhuud,
    required this.barilguud,
    required this.zogsoolKhaalga,
    required this.ajildOrsonOgnoo,
    required this.baiguullagiinId,
    required this.nevtrekhNer,
    required this.tuukh,
    required this.createdAt,
    required this.updatedAt,
    required this.tokhirgoo,
  });

  factory Ajiltan.fromJson(Map<String, dynamic> json) {
    return Ajiltan(
      id: json['_id'] ?? '',
      ner: json['ner'] ?? '',
      ovog: json['ovog'] ?? '',
      utas: json['utas'] ?? '',
      mail: json['mail'] ?? '',
      register: json['register'] ?? '',
      tsonkhniiErkhuud: json['tsonkhniiErkhuud'] ?? [],
      barilguud: (json['barilguud'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      zogsoolKhaalga: json['zogsoolKhaalga'] ?? [],
      ajildOrsonOgnoo: json['ajildOrsonOgnoo'] ?? '',
      baiguullagiinId: json['baiguullagiinId'] ?? '',
      nevtrekhNer: json['nevtrekhNer'] ?? '',
      tuukh: json['tuukh'] ?? [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      tokhirgoo: json['tokhirgoo'] != null
          ? Tokhirgoo.fromJson(json['tokhirgoo'])
          : Tokhirgoo.empty(),
    );
  }
}

class Tokhirgoo {
  final List<dynamic> gereeKharakhErkh;
  final List<dynamic> gereeZasakhErkh;
  final List<dynamic> gereeSungakhErkh;
  final List<dynamic> gereeSergeekhErkh;
  final List<dynamic> gereeTsutslakhErkh;
  final List<dynamic> umkhunSaraarKhungulultEsekh;
  final List<dynamic> guilgeeUstgakhErkh;
  final List<dynamic> guilgeeKhiikhEsekh;
  final List<dynamic> aldangiinUldegdelZasakhEsekh;

  Tokhirgoo({
    required this.gereeKharakhErkh,
    required this.gereeZasakhErkh,
    required this.gereeSungakhErkh,
    required this.gereeSergeekhErkh,
    required this.gereeTsutslakhErkh,
    required this.umkhunSaraarKhungulultEsekh,
    required this.guilgeeUstgakhErkh,
    required this.guilgeeKhiikhEsekh,
    required this.aldangiinUldegdelZasakhEsekh,
  });

  factory Tokhirgoo.fromJson(Map<String, dynamic> json) {
    return Tokhirgoo(
      gereeKharakhErkh: json['gereeKharakhErkh'] ?? [],
      gereeZasakhErkh: json['gereeZasakhErkh'] ?? [],
      gereeSungakhErkh: json['gereeSungakhErkh'] ?? [],
      gereeSergeekhErkh: json['gereeSergeekhErkh'] ?? [],
      gereeTsutslakhErkh: json['gereeTsutslakhErkh'] ?? [],
      umkhunSaraarKhungulultEsekh: json['umkhunSaraarKhungulultEsekh'] ?? [],
      guilgeeUstgakhErkh: json['guilgeeUstgakhErkh'] ?? [],
      guilgeeKhiikhEsekh: json['guilgeeKhiikhEsekh'] ?? [],
      aldangiinUldegdelZasakhEsekh: json['aldangiinUldegdelZasakhEsekh'] ?? [],
    );
  }

  factory Tokhirgoo.empty() {
    return Tokhirgoo(
      gereeKharakhErkh: [],
      gereeZasakhErkh: [],
      gereeSungakhErkh: [],
      gereeSergeekhErkh: [],
      gereeTsutslakhErkh: [],
      umkhunSaraarKhungulultEsekh: [],
      guilgeeUstgakhErkh: [],
      guilgeeKhiikhEsekh: [],
      aldangiinUldegdelZasakhEsekh: [],
    );
  }
}
