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

    final matchesContract = (gereeniiId == null && gereeniiDugaar == '' && orshinSuugchId == null) ||
        (gereeniiId != null && itemGid == gereeniiId) ||
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
      'isLinked': nekhemjlekhId.isNotEmpty,
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

    if (targetIndex >= 0 && targetIndex < invoices.length) {
      // LINKED: Merge into existing invoice and update its total
      final inv = invoices[targetIndex];
      var medeelel = inv['medeelel'];
      if (medeelel == null) {
        medeelel = {
          'zardluud': [],
          'guilgeenuud': [],
          'toot': '',
          'temdeglel': ''
        };
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
          guilgeenuud
              .any((g) => (g['_id'] ?? g['id'])?.toString() == existingId);

      if (!alreadyHas) {
        guilgeenuud.add(guilgeeEntry);

        // Update invoice totals with this receivable amount
        final remaining = guilgeeEntry['undsenDun'] - guilgeeEntry['tulsunDun'];
        if (remaining > 0) {
          inv['niitTulbur'] = (inv['niitTulbur'] ?? 0.0).toDouble() + remaining;
          inv['uldegdel'] = (inv['uldegdel'] ?? 0.0).toDouble() + remaining;
        }
      }
    } else {
      // UNLINKED: Add as a standalone item if not already in the list
      final existingId = rec['_id']?.toString();
      final alreadyHas = existingId != null &&
          invoices.any((inv) => (inv['_id'] ?? inv['id'])?.toString() == existingId);

      if (!alreadyHas) {
        final amount = _toNum(rec['tulukhDun'] ?? rec['undsenDun'] ?? 0) - _toNum(rec['tulsunDun'] ?? 0);
        if (amount > 0) {
          invoices.add({
            '_id': rec['_id']?.toString(),
            'baiguullagiinNer': 'СӨХ / Ашиглалтын зардал',
            'ovog': rec['ovog'] ?? '',
            'ner': rec['ner'] ?? '',
            'register': rec['register'] ?? '',
            'khayag': rec['khayag'] ?? '',
            'toot': rec['toot'] ?? '',
            'gereeniiDugaar': itemDugaar,
            'ognoo': rec['ognoo']?.toString() ?? DateTime.now().toIso8601String(),
            'nekhemjlekhiinOgnoo': rec['ognoo']?.toString() ?? DateTime.now().toIso8601String(),
            'niitTulbur': amount,
            'uldegdel': amount,
            'tuluv': 'Төлөөгүй',
            'turul': turul,
            'guilgeenuud': [guilgeeEntry], // Include self in breakdown
            'isStandaloneAvlaga': true,
          });
        }
      }
    }
  }

  return invoices;
}
