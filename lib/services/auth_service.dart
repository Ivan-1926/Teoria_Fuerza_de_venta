import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_api.dart';
import 'supabase_config.dart';

/// Manages officer session with Supabase Auth + fallback to demo credentials.
class AuthService {
  static const _sessionKey = 'officer_session';
  static const _demoLoginFlag = 'is_demo_login';

  static Map<String, dynamic>? _currentOfficer;
  static bool _isDemoLogin = false;

  static Map<String, dynamic>? get currentOfficer => _currentOfficer;
  static String get officerName => _currentOfficer?['name'] ?? 'Oficial';
  static String get officerId => _currentOfficer?['id']?.toString() ?? '';
  static String get officerZone => _currentOfficer?['zone'] ?? '';
  static String get officerEmail => _currentOfficer?['email'] ?? '';
  static bool get isDemoLogin => _isDemoLogin;

  /// Attempt login with Supabase Auth → SQL query → Demo fallback.
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // Step 1: Check for explicit demo credentials
    if (cleanEmail == 'demo@pichincha.com' && cleanPass == 'pichincha123') {
      return await _createAndSaveDemo();
    }

    // Step 2: Try Supabase Auth
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        final officer = {
          'id': response.user!.id,
          'name': response.user!.email?.split('@').first ?? 'Usuario',
          'email': response.user!.email ?? email,
          'zone': response.user!.userMetadata?['zone'] ?? 'Agencia Principal',
          'phone': response.user!.userMetadata?['phone'] ?? '',
          'isSupabaseAuth': true,
        };
        await _saveSession(officer, isDemoMode: false);
        _isDemoLogin = false;
        return officer;
      }
    } catch (e) {
      // Supabase Auth failed, continue to SQL query
      print('Supabase Auth failed: $e');
    }

    // Step 3: Try SQL query (legacy officers table)
    try {
      final officer = await loginOfficer(cleanEmail, cleanPass);
      if (officer != null) {
        await _saveSession(officer, isDemoMode: false);
        _isDemoLogin = false;
        return officer;
      }
    } catch (e) {
      // SQL query failed
      print('SQL query failed: $e');
    }

    // Step 4: All attempts failed, fallback to demo (for testing/offline)
    print('All auth methods failed, falling back to demo mode');
    return await _createAndSaveDemo();
  }

  static Future<Map<String, dynamic>> _createAndSaveDemo() async {
    final demo = {
      'id': 'demo-officer-001',
      'name': 'Carlos Mendoza',
      'email': 'demo@pichincha.com',
      'zone': 'Zona Norte – Quito (Demo)',
      'phone': '0991234567',
      'isDemoMode': true,
    };
    await _saveSession(demo, isDemoMode: true);
    _isDemoLogin = true;
    return demo;
  }

  static Future<void> _saveSession(
    Map<String, dynamic> officer, {
    bool isDemoMode = false,
  }) async {
    _currentOfficer = officer;
    _isDemoLogin = isDemoMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, json.encode(officer));
    await prefs.setBool(_demoLoginFlag, isDemoMode);
  }

  /// Restore session from local storage on app start.
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return false;
    try {
      _currentOfficer = json.decode(raw) as Map<String, dynamic>;
      _isDemoLogin = prefs.getBool(_demoLoginFlag) ?? false;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    _currentOfficer = null;
    _isDemoLogin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_demoLoginFlag);
    // Sign out from Supabase if authenticated
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore if not authenticated
    }
  }

  static void syncWithSession(Map<String, dynamic> data) {
    _currentOfficer = data;
  }

  static void clearSession() {
    _currentOfficer = null;
  }
}
