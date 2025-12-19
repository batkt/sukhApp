import 'dart:core';

class MedegdelResponse {
  final bool success;
  final List<Medegdel> data;
  final int? count;

  MedegdelResponse({required this.success, required this.data, this.count});

  factory MedegdelResponse.fromJson(Map<String, dynamic> json) {
    List<Medegdel> dataList = [];

    // Handle both array and single object responses
    if (json['data'] != null) {
      if (json['data'] is List) {
        // Array format
        dataList = (json['data'] as List<dynamic>)
            .map((e) => Medegdel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (json['data'] is Map) {
        // Single object format (e.g., when updating a notification)
        dataList = [Medegdel.fromJson(json['data'] as Map<String, dynamic>)];
      }
    }

    return MedegdelResponse(
      success: json['success'] ?? false,
      data: dataList,
      count: json['count'] as int? ?? dataList.length,
    );
  }
}

class Medegdel {
  final String id;
  final String baiguullagiinId;
  final String? barilgiinId;
  final String ognoo;
  final String title;
  final String? gereeniiDugaar;
  final String message;
  final String? orshinSuugchGereeniiDugaar;
  final String? orshinSuugchId;
  final String? orshinSuugchNer;
  final String? orshinSuugchUtas;
  final bool kharsanEsekh;
  final String turul; // "gomdol", "sanal", "app", "хариу", "khariu"
  final String createdAt;
  final String updatedAt;
  final String? status; // "pending", "in_progress", "done", "cancelled"
  final String? tailbar; // Reply text from admin
  final String? repliedAt; // When admin replied

  Medegdel({
    required this.id,
    required this.baiguullagiinId,
    this.barilgiinId,
    required this.ognoo,
    required this.title,
    this.gereeniiDugaar,
    required this.message,
    this.orshinSuugchGereeniiDugaar,
    this.orshinSuugchId,
    this.orshinSuugchNer,
    this.orshinSuugchUtas,
    required this.kharsanEsekh,
    required this.turul,
    required this.createdAt,
    required this.updatedAt,
    this.status,
    this.tailbar,
    this.repliedAt,
  });

  factory Medegdel.fromJson(Map<String, dynamic> json) {
    // Handle ognoo - use createdAt if ognoo is not present
    String ognooValue = json['ognoo']?.toString() ?? '';
    if (ognooValue.isEmpty && json['createdAt'] != null) {
      ognooValue = json['createdAt'].toString();
    }

    return Medegdel(
      id: json['_id']?.toString() ?? '',
      baiguullagiinId: json['baiguullagiinId']?.toString() ?? '',
      barilgiinId: json['barilgiinId']?.toString(),
      ognoo: ognooValue,
      title: json['title']?.toString() ?? '',
      gereeniiDugaar: json['gereeniiDugaar']?.toString(),
      message: json['message']?.toString() ?? '',
      orshinSuugchGereeniiDugaar: json['orshinSuugchGereeniiDugaar']
          ?.toString(),
      orshinSuugchId: json['orshinSuugchId']?.toString(),
      orshinSuugchNer: json['orshinSuugchNer']?.toString(),
      orshinSuugchUtas: json['orshinSuugchUtas']?.toString(),
      kharsanEsekh: json['kharsanEsekh'] ?? false,
      turul: json['turul']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      status: json['status']?.toString(),
      tailbar: json['tailbar']?.toString(),
      repliedAt: json['repliedAt']?.toString(),
    );
  }

  // Helper getter to check if notification has a reply
  bool get hasReply =>
      status == 'done' && tailbar != null && tailbar!.isNotEmpty;

  // Helper getter to check if it's a reply notification
  bool get isReply {
    final turulLower = turul.toLowerCase();
    return turulLower == 'хариу' ||
        turulLower == 'hariu' ||
        turulLower == 'khariu';
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(ognoo).toLocal();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return ognoo;
    }
  }

  String get formattedDateTime {
    try {
      final date = DateTime.parse(ognoo).toLocal();
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return ognoo;
    }
  }
}
