import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineQueue {
  static const _key = 'offline_queue_items';

  Future<List<Map<String, dynamic>>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> arr = json.decode(raw);
    return arr.cast<Map<String, dynamic>>();
  }

  Future<void> enqueue(Map<String, dynamic> item) async {
    final items = await list();
    items.add(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(items));
  }

  Future<void> removeAt(int index) async {
    final items = await list();
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(items));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
