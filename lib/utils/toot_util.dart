/// Профайлын хаягуудаас сервер `nuukhTootuud`-аар заасан давхардлыг хасна.
///
/// Нэг байр OWN_ORG болон төлбөрийн хаягаар хоёр удаа харагдахаас сэргийлнэ.
/// ЗӨВХӨН харуулахад ашиглана — хаалга, зочин, камер, барилга сонголт бүх
/// хаягийг (`user['toots']`) хэвээр ашигласаар.
List harakhTootuud(Map? user) {
  final toots = (user?['toots'] is List) ? List.from(user!['toots']) : [];
  final nuukh = (user?['nuukhTootuud'] is List)
      ? (user!['nuukhTootuud'] as List).map((e) => e.toString()).toSet()
      : <String>{};
  if (nuukh.isEmpty) return toots;
  return toots
      .where((t) => !(t is Map && nuukh.contains(t['_id']?.toString())))
      .toList();
}
