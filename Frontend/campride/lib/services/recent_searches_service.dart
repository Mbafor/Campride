import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'stops_repository.dart';

/// Persists the student's recently-searched destination stops locally,
/// most-recent-first, deduplicated by stop id.
class RecentSearchesService {
  static const String _key = 'recent_destination_stops';
  static const int _maxEntries = 5;

  Future<List<StopInfo>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => StopInfo.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecent(StopInfo stop) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecents();

    final updated = [
      stop,
      ...current.where((s) => s.id != stop.id),
    ].take(_maxEntries).toList();

    await prefs.setStringList(
      _key,
      updated.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }
}
