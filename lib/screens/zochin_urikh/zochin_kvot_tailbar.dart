/// Зочин урих квотын тайлбар мөр.
///
/// Backend (`/zochinQuotaStatus`) хоёр горимтой:
///   • "davtamj" — өдөр/сар бүр шинэчлэгдэнэ (хуучин);
///   • "zereg"   — нэг зэрэг зогсоолд байж болох зочны дээд тоо. Уригдсан
///                 машин гармагц квот буцаж нэмэгдэнэ.
/// Хуучин backend `kvotGorim` илгээдэггүй тул тэр үед "davtamj" гэж үзнэ.
library;

int _too(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}

bool zochinKvotZeregEsekh(Map<String, dynamic>? q) =>
    q != null && (q['zereg'] == true || q['kvotGorim'] == 'zereg');

/// `_quotaStatus` map-д нэмэх горимын талбарууд.
Map<String, dynamic> zochinKvotGorimTalbaruud(Map<String, dynamic> data) {
  final zereg = data['zeregEsekh'] == true || data['kvotGorim'] == 'zereg';
  return {
    'zereg': zereg,
    'kvotGorim': zereg ? 'zereg' : 'davtamj',
    'dotorToo': _too(data['dotorToo']),
    'khuleelgendToo': _too(data['khuleelgendToo']),
  };
}

/// Жишээ: «Одоо зогсоолд 1, үлдсэн 1/2» эсвэл «Үлдсэн урилгын эрх: 3/7».
String zochinKvotTailbar(Map<String, dynamic> q) {
  final total = _too(q['total']);
  final remaining = _too(q['remaining']);
  if (!zochinKvotZeregEsekh(q)) {
    return 'Үлдсэн урилгын эрх: ${total == 0 ? "Хязгааргүй" : "$remaining/$total"}';
  }
  if (total == 0) return 'Зочин урих эрх: Хязгааргүй';
  final dotor = _too(q['dotorToo']);
  final khuleelgend = _too(q['khuleelgendToo']);
  final khesguud = <String>['Одоо зогсоолд $dotor'];
  if (khuleelgend > 0) khesguud.add('ирээгүй $khuleelgend');
  khesguud.add('үлдсэн $remaining/$total');
  return khesguud.join(', ');
}

/// Квот дууссан үеийн тайлбар.
String zochinKvotDuussanTailbar(Map<String, dynamic>? q) {
  if (zochinKvotZeregEsekh(q)) {
    return 'Нэг зэрэг ${_too(q?['total'])} зочин урих боломжтой. '
        'Уригдсан зочин зогсоолоос гарахад эрх автоматаар сэргэнэ.';
  }
  return 'Таны зочин урих эрх дууссан байна.';
}
