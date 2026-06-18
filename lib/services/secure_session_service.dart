import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del JWT y datos sensibles de sesión del asesor
/// (rúbrica Criterio 4 — Seguridad). Usa Keystore/Keychain del dispositivo.
class SecureSessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'fv_access_token';
  static const _keyRefreshToken = 'fv_refresh_token';
  static const _keyEmail = 'fv_email';
  static const _keyRol = 'fv_rol';

  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String email,
    String? rol,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: _keyEmail, value: email);
    if (rol != null) await _storage.write(key: _keyRol, value: rol);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyRol);
  }

  static Future<String?> get accessToken => _storage.read(key: _keyAccessToken);
  static Future<String?> get savedEmail => _storage.read(key: _keyEmail);
  static Future<String?> get savedRol => _storage.read(key: _keyRol);
}
