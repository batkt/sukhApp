import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sukh_app/models/ger_buliin_gishuun_model.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/logger.dart';

/// Гэр бүлийн гишүүний API.
///
/// Серверийн тал гишүүний хүсэлт дэх `orshinSuugchId`-г үндсэн эзэмшигчийнх рүү
/// автоматаар хөрвүүлдэг тул гэрээ, нэхэмжлэх, төлбөрийн дуудлагууд ямар ч
/// өөрчлөлтгүйгээр ажиллана. Энд зөвхөн гишүүнчлэлийг удирдах дуудлагууд байна.
class GerBulService {
  /// Серверийн алдааны мессежийг гаргаж авна
  static String _aldaaAvya(http.Response response, String undsenMessage) {
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        final msg = body['message'] ?? body['aldaa'] ?? body['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString().replaceAll('Exception: ', '');
        }
      }
    } catch (_) {}
    return undsenMessage;
  }

  /// Гишүүд болон хүлээгдэж буй урилгуудын жагсаалт
  static Future<GerBuliinJagsaalt> gishuudAvya() async {
    final headers = await ApiService.getAuthHeaders();
    final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

    final uri = Uri.parse('${ApiService.baseUrl}/gerBuliinGishuud').replace(
      queryParameters: {
        if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final response = await http.get(uri, headers: headers);
    AppLogger.api('GET', uri.toString(), response: response.statusCode);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return GerBuliinJagsaalt.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception(
      _aldaaAvya(response, 'Гэр бүлийн гишүүдийг татахад алдаа гарлаа'),
    );
  }

  /// Гишүүн урих — уригдсан дугаар руу SMS-ээр баталгаажуулах код явна
  static Future<void> gishuunUriya({
    required String utas,
    required String ovog,
    required String ner,
    required String kholboo,
    required String erkh,
  }) async {
    final headers = await ApiService.getAuthHeaders();
    final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/gerBuliinGishuunUrikh'),
      headers: headers,
      body: json.encode({
        'utas': utas,
        'ovog': ovog,
        'ner': ner,
        'kholboo': kholboo,
        'erkh': erkh,
        if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
      }),
    );

    AppLogger.api('POST', '/gerBuliinGishuunUrikh', response: response.body);

    if (response.statusCode != 200) {
      throw Exception(_aldaaAvya(response, 'Урилга илгээхэд алдаа гарлаа'));
    }
  }

  /// Хүлээгдэж буй урилгын кодыг дахин илгээх
  static Future<void> kodDakhinIlgeeye(String utas) async {
    final headers = await ApiService.getAuthHeaders();
    final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/gerBuliinGishuunDakhinIlgeeye'),
      headers: headers,
      body: json.encode({
        'utas': utas,
        if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_aldaaAvya(response, 'Код дахин илгээхэд алдаа гарлаа'));
    }
  }

  /// Гишүүний эрх солих
  static Future<void> erkhSoliyo({
    required String gishuuniiId,
    required String erkh,
  }) async {
    final headers = await ApiService.getAuthHeaders();
    final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/gerBuliinGishuunErkh'),
      headers: headers,
      body: json.encode({
        'gishuuniiId': gishuuniiId,
        'erkh': erkh,
        if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_aldaaAvya(response, 'Эрх солиход алдаа гарлаа'));
    }
  }

  /// Гишүүн хасах, эсвэл хүлээгдэж буй урилга цуцлах.
  /// `gishuuniiId` нь баталгаажсан гишүүнд, `utas` нь урилгад тохирно.
  static Future<void> gishuunKhasya({String? gishuuniiId, String? utas}) async {
    final headers = await ApiService.getAuthHeaders();
    final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/gerBuliinGishuunUstgakh'),
      headers: headers,
      body: json.encode({
        if (gishuuniiId != null) 'gishuuniiId': gishuuniiId,
        if (utas != null) 'utas': utas,
        if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_aldaaAvya(response, 'Хасахад алдаа гарлаа'));
    }
  }

  /// Гишүүн өөрөө гишүүнчлэлээсээ гарах. Дараа нь заавал системээс гарна.
  static Future<void> gishuunchleleesGarya() async {
    await gishuunKhasya();
    await StorageService.clearAuthData();
    await SessionService.logout();
  }

  /// Гишүүн хэний дансыг харж байгаа — үндсэн эзэмшигчийн мэдээлэл
  static Future<Map<String, dynamic>?> undsenEzemshigchAvya() async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final kholbolt = await ApiService.getEffectiveKholbolt(isOther: true);

      final uri = Uri.parse('${ApiService.baseUrl}/gerBuliinUndsenEzemshigch')
          .replace(
            queryParameters: {
              if (kholbolt != null) 'tukhainBaaziinKholbolt': kholbolt,
            },
          );

      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map) return null;
      if (data['gishuunEsekh'] != true) return null;

      final undsen = data['undsenEzemshigch'];
      return undsen is Map ? Map<String, dynamic>.from(undsen) : null;
    } catch (e) {
      AppLogger.error('undsenEzemshigchAvya', e);
      return null;
    }
  }

  /// Уригдсан хүн кодоо оруулж, нууц үгээ тохируулж гишүүнчлэлээ
  /// баталгаажуулна. Амжилттай бол шууд нэвтэрсэн байдалтай болно.
  ///
  /// Токен хадгалахгүй байх бол [nevtrekh] -г false болгоно.
  static Future<Map<String, dynamic>> batalgaajuulya({
    required String utas,
    required String code,
    required String nuutsUg,
    String? ovog,
    String? ner,
    bool nevtrekh = true,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/gerBuliinGishuunBatalgaajuulya'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'utas': utas,
        'code': code,
        'nuutsUg': nuutsUg,
        if (ovog != null && ovog.isNotEmpty) 'ovog': ovog,
        if (ner != null && ner.isNotEmpty) 'ner': ner,
      }),
    );

    AppLogger.api(
      'POST',
      '/gerBuliinGishuunBatalgaajuulya',
      response: response.statusCode,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _aldaaAvya(response, 'Баталгаажуулахад алдаа гарлаа'),
      );
    }

    final data = Map<String, dynamic>.from(json.decode(response.body));

    if (nevtrekh && data['token'] != null) {
      await StorageService.saveToken(data['token'].toString());
      await StorageService.saveUserData(data);
      await StorageService.savePhoneNumber(utas);
      await SessionService.saveLoginTimestamp();
    }

    return data;
  }
}
