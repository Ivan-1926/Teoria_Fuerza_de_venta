import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Servicio offline-simple que guarda borradores JSON en SharedPreferences.
class OfflineService {
  static const _draftsKey = 'offline_drafts';

  Future<void> saveDraft(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getString(_draftsKey);
    final Map<String, dynamic> map = all == null ? {} : json.decode(all);
    map[id] = data;
    await prefs.setString(_draftsKey, json.encode(map));
  }

  Future<Map<String, dynamic>?> loadDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getString(_draftsKey);
    if (all == null) return null;
    final Map<String, dynamic> map = json.decode(all);
    final entry = map[id];
    if (entry == null) return null;
    return Map<String, dynamic>.from(entry);
  }

  Future<void> removeDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getString(_draftsKey);
    if (all == null) return;
    final Map<String, dynamic> map = json.decode(all);
    map.remove(id);
    await prefs.setString(_draftsKey, json.encode(map));
  }

  Future<List<String>> listDraftIds() async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getString(_draftsKey);
    if (all == null) return [];
    final Map<String, dynamic> map = json.decode(all);
    return map.keys.toList();
  }
}
