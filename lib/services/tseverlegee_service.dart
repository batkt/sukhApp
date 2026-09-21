import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/logger.dart';

/// Цэвэрлэгээний захиалгын API.
///
/// Сервер нь `baiguullagiinId`-гаар тухайн байгууллагын баазыг олдог тул
/// `tukhainBaaziinKholbolt` дамжуулах шаардлагагүй — санал асуулгатай ижил.
class TseverlegeeService {
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

  /// Шинэ захиалга үүсгэнэ.
  ///
  /// Оршин суугчийн мэдээллийг (байгууллага, барилга, тоот, нэр) хадгалагдсан
  /// профайлаас нь өөрөө нөхнө — дуудагч нь зөвхөн маягтын талбаруудыг өгнө.
  static Future<Map<String, dynamic>> zakhialgaUusgeye({
    required String utasniiDugaar,
    required DateTime khusesenOgnoo,
    String? nemelttMedeelel,
  }) async {
    final baiguullagiinId = await StorageService.getBaiguullagiinId();
    if (baiguullagiinId == null || baiguullagiinId.isEmpty) {
      throw Exception('Байгууллага сонгогдоогүй байна');
    }

    final headers = await ApiService.getAuthHeaders();

    // OWN_ORG хаягтай хэрэглэгчийн хадгалсан "тоот" нь жинхэнэ тоот биш,
    // "OWN_ORG" гэсэн орлуулагч текст байдаг (burtguulekh_signup.dart).
    // Түүнийг явуулбал админ дээр "OWN_ORG тоот" гэж харагдана. Сервер нь
    // оршин суугчийн бичлэгээс жинхэнэ тоотыг нь олдог тул энд илгээхгүй.
    final khadgalsanToot = await StorageService.getWalletDoorNo();
    final toot = (khadgalsanToot == null || khadgalsanToot == 'OWN_ORG')
        ? null
        : khadgalsanToot;

    // bpay (хэтэвчний) хэрэглэгч нь байгууллагынхаа биш, нэгдсэн баазад
    // хадгалагддаг. Тэдний baiguullagiinId-гаар сервер холболтоо олж чадахгүй
    // тул баазынх нь нэрийг хамт явуулна (GerBulService-тэй ижил зарчим).
    final baaziinNer = await ApiService.getEffectiveKholbolt(isOther: true);

    // Серверийн `tokenShalgakh` нь body доторх `baiguullagiinId`-г токеныхоор
    // дарж бичдэг. bpay хэрэглэгчийн токенд байгууллага байдаггүй тул утга нь
    // устаж алга болдог. Query параметрийг хөнддөггүй тул давхар тэндүүр
    // явуулж, сервер дээр нөхөж авна.
    final uri = Uri.parse('${ApiService.baseUrl}/tseverlegee').replace(
      queryParameters: {
        'baiguullagiinId': baiguullagiinId,
        if (baaziinNer != null) 'baaziinNer': baaziinNer,
      },
    );

    final biy = {
      'baiguullagiinId': baiguullagiinId,
      'baaziinNer': baaziinNer,
      'barilgiinId': await StorageService.getBarilgiinId(),
      'toot': toot,
      'orshinSuugchiinId': await StorageService.getUserId(),
      'orshinSuugchiinNer': await StorageService.getUserName(),
      'uilchilgeeniiTurul': 'Өрхийн цэвэрлэгээ',
      'utasniiDugaar': utasniiDugaar,
      'nemelttMedeelel': nemelttMedeelel,
      // Сервер нь Date болгон уншина. Утасны цагийн бүсийг хамт явуулснаар
      // сервер дээр өөр бүс тохируулагдсан ч мөч нь зөрөхгүй.
      'khusesenOgnoo': khusesenOgnoo.toIso8601String(),
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(biy),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.api('POST', uri.toString(), response: response.statusCode);
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    }

    // Алдаа гарвал статус кодоор юу болсныг мэдэхгүй. Илгээсэн утга болон
    // серверийн хариуг хамт бичнэ — аль талбар дээр унасныг шууд харна.
    AppLogger.api(
      'POST',
      uri.toString(),
      body: biy,
      response: '${response.statusCode} ${response.body}',
    );
    throw Exception(
      _aldaaAvya(response, 'Захиалга илгээхэд алдаа гарлаа'),
    );
  }
}
