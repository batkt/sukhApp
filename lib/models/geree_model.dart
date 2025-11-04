class GereeResponse {
  final int khuudasniiDugaar;
  final int khuudasniiKhemjee;
  final List<Geree> jagsaalt;
  final int niitMur;
  final int niitKhuudas;

  GereeResponse({
    required this.khuudasniiDugaar,
    required this.khuudasniiKhemjee,
    required this.jagsaalt,
    required this.niitMur,
    required this.niitKhuudas,
  });

  factory GereeResponse.fromJson(Map<String, dynamic> json) {
    return GereeResponse(
      khuudasniiDugaar: json['khuudasniiDugaar'] ?? 0,
      khuudasniiKhemjee: json['khuudasniiKhemjee'] ?? 0,
      jagsaalt:
          (json['jagsaalt'] as List<dynamic>?)
              ?.map((e) => Geree.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      niitMur: json['niitMur'] ?? 0,
      niitKhuudas: json['niitKhuudas'] ?? 0,
    );
  }
}

class Geree {
  final String id;
  final String gereeniiDugaar;
  final String gereeniiOgnoo;
  final String turul;
  final String ovog;
  final String ner;
  final List<String> suhUtas;
  final List<String> utas;

  final String tulukhOgnoo;
  final double ashiglaltiinZardal;
  final double niitTulbur;
  final String bairNer;
  final String toot;
  final String davkhar;
  final String burtgesenAjiltan;
  final String orshinSuugchId;
  final String temdeglel;
  final double baritsaaniiUldegdel;
  final List<dynamic> zardluud;
  final List<dynamic> segmentuud;
  final List<dynamic> khungulultuud;
  final String createdAt;
  final String updatedAt;

  Geree({
    required this.id,
    required this.gereeniiDugaar,
    required this.gereeniiOgnoo,
    required this.turul,
    required this.ovog,
    required this.ner,
    required this.suhUtas,
    required this.utas,

    required this.tulukhOgnoo,
    required this.ashiglaltiinZardal,
    required this.niitTulbur,
    required this.bairNer,
    required this.toot,
    required this.davkhar,
    required this.burtgesenAjiltan,
    required this.orshinSuugchId,
    required this.temdeglel,
    required this.baritsaaniiUldegdel,
    required this.zardluud,
    required this.segmentuud,
    required this.khungulultuud,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Geree.fromJson(Map<String, dynamic> json) {
    return Geree(
      id: json['_id'] ?? '',
      gereeniiDugaar: json['gereeniiDugaar'] ?? '',
      gereeniiOgnoo: json['gereeniiOgnoo'] ?? '',
      turul: json['turul'] ?? '',
      ovog: json['ovog'] ?? '',
      ner: json['ner'] ?? '',
      suhUtas:
          (json['suhUtas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      utas:
          (json['utas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],

      tulukhOgnoo: json['tulukhOgnoo'] ?? '',
      ashiglaltiinZardal: (json['ashiglaltiinZardal'] ?? 0).toDouble(),
      niitTulbur: (json['niitTulbur'] ?? 0).toDouble(),
      bairNer: json['bairNer'] ?? '',
      toot: json['toot'] ?? 0,
      davkhar: json['davkhar'] ?? '',
      burtgesenAjiltan: json['burtgesenAjiltan'] ?? '',
      orshinSuugchId: json['orshinSuugchId'] ?? '',
      temdeglel: json['temdeglel'] ?? '',
      baritsaaniiUldegdel: (json['baritsaaniiUldegdel'] ?? 0).toDouble(),
      zardluud: json['zardluud'] ?? [],
      segmentuud: json['segmentuud'] ?? [],
      khungulultuud: json['khungulultuud'] ?? [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
