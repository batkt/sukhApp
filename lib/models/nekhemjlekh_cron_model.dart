class NekhemjlekhCronResponse {
  final bool success;
  final List<NekhemjlekhCron> data;

  NekhemjlekhCronResponse({
    required this.success,
    required this.data,
  });

  factory NekhemjlekhCronResponse.fromJson(Map<String, dynamic> json) {
    return NekhemjlekhCronResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => NekhemjlekhCron.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class NekhemjlekhCron {
  final String id;
  final String baiguullagiinId;
  final String? daraagiinAjillakhOgnoo;
  final bool idevkhitei;
  final int nekhemjlekhUusgekhOgnoo;
  final String shinechilsenOgnoo;
  final String suuldAjillasanOgnoo;
  final String uussenOgnoo;

  NekhemjlekhCron({
    required this.id,
    required this.baiguullagiinId,
    this.daraagiinAjillakhOgnoo,
    required this.idevkhitei,
    required this.nekhemjlekhUusgekhOgnoo,
    required this.shinechilsenOgnoo,
    required this.suuldAjillasanOgnoo,
    required this.uussenOgnoo,
  });

  factory NekhemjlekhCron.fromJson(Map<String, dynamic> json) {
    return NekhemjlekhCron(
      id: json['_id'] ?? '',
      baiguullagiinId: json['baiguullagiinId'] ?? '',
      daraagiinAjillakhOgnoo: json['daraagiinAjillakhOgnoo'],
      idevkhitei: json['idevkhitei'] ?? false,
      nekhemjlekhUusgekhOgnoo: json['nekhemjlekhUusgekhOgnoo'] ?? 1,
      shinechilsenOgnoo: json['shinechilsenOgnoo'] ?? '',
      suuldAjillasanOgnoo: json['suuldAjillasanOgnoo'] ?? '',
      uussenOgnoo: json['uussenOgnoo'] ?? '',
    );
  }
}
