/// Shared utility to merge gereeniiTulukhAvlaga (avlaga, ekhniiUldegdel) into invoices.
/// Used by both nekhemjlekh screen and home header total.
List<Map<String, dynamic>> mergeTulukhAvlagaIntoInvoices(
  List<dynamic> rawInvoices,
  List<Map<String, dynamic>> tulukhAvlagaList,
  String? gereeniiId,
  String gereeniiDugaar,
  String? orshinSuugchId,
) {
  final invoices = rawInvoices.map((e) {
    final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
    return Map<String, dynamic>.from(m);
  }).toList();

  if (tulukhAvlagaList.isEmpty) return invoices;

  double _toNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return (double.tryParse(v.toString()) ?? 0.0);
  }
  String _toId(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is Map && v['\$oid'] != null) return v['\$oid'].toString().trim();
    return v.toString().trim();
  }

  final unpaidIndices = <int>[];
  for (var i = 0; i < invoices.length; i++) {
    if (invoices[i]['tuluv'] != 'Төлсөн') unpaidIndices.add(i);
  }
  final latestUnpaidIndex = unpaidIndices.isNotEmpty ? unpaidIndices.first : 0;

  for (final rec in tulukhAvlagaList) {
    final itemGid = (rec['gereeniiId'] ?? '').toString().trim();
    final itemDugaar = (rec['gereeniiDugaar'] ?? '').toString().trim();
    final itemRid = (rec['orshinSuugchId'] ?? '').toString().trim();
    final nekhemjlekhId = _toId(rec['nekhemjlekhId']);
    final ekhniiUldegdelEsekh = rec['ekhniiUldegdelEsekh'] == true;
    final rawTurul = (rec['turul'] ?? 'avlaga').toString().toLowerCase();
    final turul = (rawTurul == 'авлага' || rawTurul == 'avlaga') ? 'avlaga' : rawTurul;

    final matchesContract = (gereeniiId != null && itemGid == gereeniiId) ||
        itemDugaar == gereeniiDugaar ||
        (orshinSuugchId != null && itemRid == orshinSuugchId);
    if (!matchesContract) continue;

    final guilgeeEntry = {
      'ognoo': rec['ognoo']?.toString(),
      'tulukhDun': _toNum(rec['tulukhDun'] ?? rec['undsenDun'] ?? 0),
      'undsenDun': _toNum(rec['undsenDun'] ?? rec['tulukhDun'] ?? 0),
      'tulsunDun': _toNum(rec['tulsunDun'] ?? 0),
      'tailbar': rec['zardliinNer'] ?? rec['tailbar'] ?? (ekhniiUldegdelEsekh ? 'Эхний үлдэгдэл' : 'Авлага'),
      'turul': turul,
      'ekhniiUldegdelEsekh': ekhniiUldegdelEsekh,
      '_id': rec['_id']?.toString(),
    };

    int targetIndex = -1;
    if (nekhemjlekhId.isNotEmpty) {
      for (var i = 0; i < invoices.length; i++) {
        if (_toId(invoices[i]['_id']) == nekhemjlekhId) {
          targetIndex = i;
          break;
        }
      }
    }
    if (targetIndex < 0 && ekhniiUldegdelEsekh) {
      targetIndex = latestUnpaidIndex;
    } else if (targetIndex < 0) {
      targetIndex = latestUnpaidIndex;
    }

    if (targetIndex >= 0 && targetIndex < invoices.length) {
      final inv = invoices[targetIndex];
      var medeelel = inv['medeelel'];
      if (medeelel == null) {
        medeelel = {'zardluud': [], 'guilgeenuud': [], 'toot': '', 'temdeglel': ''};
        inv['medeelel'] = medeelel;
      }
      if (medeelel is! Map<String, dynamic>) {
        medeelel = Map<String, dynamic>.from(medeelel as Map);
        inv['medeelel'] = medeelel;
      }
      var guilgeenuud = medeelel['guilgeenuud'];
      if (guilgeenuud == null) {
        guilgeenuud = [];
        medeelel['guilgeenuud'] = guilgeenuud;
      }
      if (guilgeenuud is! List) guilgeenuud = List.from(guilgeenuud);
      medeelel['guilgeenuud'] = guilgeenuud;
      final existingId = guilgeeEntry['_id']?.toString();
      final alreadyHas = existingId != null &&
          guilgeenuud.any((g) => (g['_id'] ?? g['id'])?.toString() == existingId);
      if (!alreadyHas) guilgeenuud.add(guilgeeEntry);
    }
  }

  return invoices;
}
