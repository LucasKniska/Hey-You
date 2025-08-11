class LBEntry {
  final String id;
  final String name;
  final num value;

  LBEntry({required this.id, required this.name, required this.value});

  factory LBEntry.fromJson(Map<String, dynamic> j) =>
      LBEntry(id: j['id'] ?? '', name: j['name'] ?? '', value: j['value'] ?? 0);
}

class LBRankings {
  final List<LBEntry> totalConnections;
  final List<LBEntry> currentStreak;
  final List<LBEntry> longestStreak;

  LBRankings({
    required this.totalConnections,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory LBRankings.fromJson(Map<String, dynamic> j) {
    List<LBEntry> _parse(String k) =>
        ((j[k] as List?) ?? []).map((e) => LBEntry.fromJson(e)).toList();

    final total = _parse('totalConnections')..sort((a, b) => b.value.compareTo(a.value));
    final current = _parse('currentStreak')..sort((a, b) => b.value.compareTo(a.value));
    final longest = _parse('longestStreak')..sort((a, b) => b.value.compareTo(a.value));

    return LBRankings(totalConnections: total, currentStreak: current, longestStreak: longest);
  }
}
