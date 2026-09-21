/// Серверийн хаяг — аппын ЦОР ЦОРЫН эх сурвалж.
///
/// Өмнө нь хаяг 7 газар хатуу бичигдсэн байсан тул зөвхөн хоёр нь (`ApiService`,
/// `ApiEndpoints`) dev рүү шилжсэн ч socket, хувилбар шалгалт, чатын файл нь
/// production дээр үлдэж, туршилт хагас байдалд ажилладаг байв.
///
/// Одоо dev ↔ production сэлгэхэд доорх `devEsekh` НЭГ мөрийг л өөрчилнө.
class ApiHost {
  const ApiHost._();

  /// `true` бол dev сервер, `false` бол production.
  ///
  /// Release болгохын өмнө `false` болгоно.
  static const bool devEsekh = false;

  static const String _productionOrigin = 'https://amarhome.mn';
  static const String _devOrigin = 'https://dev.amarhome.mn';

  /// Сайтын үндэс — socket.io, статик файл (`/medegdel/...`) энд холбогдоно.
  ///
  /// Socket.io нь сайтын үндэс дээр байрладаг (`/api` ДООР биш) — nginx
  /// `/socket.io`-г тэгж проксилдог.
  static const String origin = devEsekh ? _devOrigin : _productionOrigin;

  /// REST API-ийн үндэс.
  static const String api = '$origin/api';

  /// `/medegdel/...` доорх файлын бүтэн хаягийг бүтээнэ.
  static String medegdeliinFile(String zam) => '$origin/medegdel/$zam';
}
