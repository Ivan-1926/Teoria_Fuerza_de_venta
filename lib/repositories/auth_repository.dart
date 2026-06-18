import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asesor_negocio_model.dart';
import '../services/secure_session_service.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  static const _demoSessionKey = 'demo_officer_session';

  AuthRepository(this._supabase);

  Future<AsesorNegocioModel?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final isDemoCredential =
        cleanEmail == 'demo@pichincha.com' && password == 'pichincha123';
    final isAcademicCredential =
        (cleanEmail == 'asesor@pichincha.com' ||
            cleanEmail == 'supervisor@pichincha.com') &&
        password == 'Docente2025!';

    // Bloqueo por 5 intentos fallidos (rúbrica Criterio 4)
    if (!isDemoCredential && !isAcademicCredential) {
      await _verificarBloqueo(cleanEmail);
    }

    // Autenticación con Supabase Auth (JWT)
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (response.user != null) {
        final profile = await _resolveAdvisorProfile(response.user!);
        if (profile == null) {
          await signOut();
          throw Exception(
            'Perfil de asesor no encontrado. Ejecuta 03_usuarios_demo_docente.sql '
            'y crea el usuario en Supabase Auth con el mismo correo.',
          );
        }

        if (!profile.activo) {
          await signOut();
          throw Exception('El asesor de negocio no está activo. Comuníquese con el administrador.');
        }

        // Éxito: reinicia contador y guarda sesión segura
        await _registrarIntento(cleanEmail, true);
        final session = response.session;
        if (session != null) {
          await SecureSessionService.saveSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            email: cleanEmail,
            rol: profile.rol,
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_demoSessionKey);

        return profile;
      }
    } on AuthException catch (authErr) {
      if (isDemoCredential) {
        return await _createDemoSession();
      }
      if (isAcademicCredential) {
        return await _createAcademicSession(cleanEmail);
      }
      // Credenciales inválidas → registra intento fallido
      await _registrarIntento(cleanEmail, false);
      throw Exception(_traducirError(authErr.message));
    } catch (e) {
      if (isDemoCredential) {
        return await _createDemoSession();
      }
      if (isAcademicCredential) {
        return await _createAcademicSession(cleanEmail);
      }
      rethrow;
    }

    return null;
  }

  /// Consulta el estado de bloqueo del email antes de autenticar.
  Future<void> _verificarBloqueo(String email) async {
    try {
      final res = await _supabase.rpc(
        'rpc_fv_login_estado',
        params: {'p_email': email},
      );
      final row = res is List && res.isNotEmpty
          ? Map<String, dynamic>.from(res.first)
          : (res is Map ? Map<String, dynamic>.from(res) : null);
      if (row != null && row['bloqueado'] == true) {
        throw Exception(
            'Cuenta bloqueada por 5 intentos fallidos. Intenta nuevamente en 15 minutos.');
      }
    } on Exception {
      rethrow;
    } catch (_) {
      // Si la RPC no existe o falla la red, no bloquear el flujo demo/offline.
    }
  }

  Future<void> _registrarIntento(String email, bool exitoso) async {
    try {
      await _supabase.rpc(
        'rpc_fv_registrar_intento',
        params: {'p_email': email, 'p_exitoso': exitoso},
      );
    } catch (_) {
      // No interrumpir el login si la RPC no está disponible.
    }
  }

  String _traducirError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    return message;
  }

  Future<AsesorNegocioModel> _createAcademicSession(String email) async {
    final profile = _knownAcademicProfile(email, 'academic-${email.split('@').first}');
    if (profile == null) {
      throw Exception('Credenciales académicas no reconocidas.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_demoSessionKey);
    await prefs.setString(_demoSessionKey, json.encode(profile.toMap()));
    return profile;
  }

  Future<AsesorNegocioModel> _createDemoSession() async {
    const demoAdvisor = AsesorNegocioModel(
      id: 'demo-officer-001',
      codigoEmpleado: 'EMP-001',
      nombres: 'Carlos',
      apellidos: 'Mendoza',
      agenciaId: '101',
      perfil: 'Oficial de Crédito Principal',
      activo: true,
      rol: 'asesor',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_demoSessionKey, json.encode(demoAdvisor.toMap()));
    return demoAdvisor;
  }

  Future<AsesorNegocioModel?> getAdvisorProfile(String id) async {
    try {
      final data = await _supabase
          .from('asesores_negocio')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return AsesorNegocioModel.fromMap(data);
    } catch (e) {
      throw Exception('Error al consultar asesor: ${e.toString()}');
    }
  }

  /// Resuelve el perfil por correo (esquema real: id entero + email en asesores_negocio).
  Future<AsesorNegocioModel?> getAdvisorProfileByEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      final data = await _supabase
          .from('asesores_negocio')
          .select()
          .eq('email', clean)
          .maybeSingle();
      if (data != null) {
        return AsesorNegocioModel.fromMap(data);
      }
      // Fallback: comparación case-insensitive si el correo en BD tiene mayúsculas
      final list = await _supabase
          .from('asesores_negocio')
          .select()
          .ilike('email', clean);
      if (list is List && list.isNotEmpty) {
        return AsesorNegocioModel.fromMap(
          Map<String, dynamic>.from(list.first as Map),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error al consultar asesor por correo: ${e.toString()}');
    }
  }

  Future<AsesorNegocioModel?> _resolveAdvisorProfile(User user) async {
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final byEmail = await getAdvisorProfileByEmail(email);
      if (byEmail != null) return byEmail;
    }
    final byId = await getAdvisorProfile(user.id);
    if (byId != null) return byId;

    // Auth válido pero sin fila en asesores_negocio (demo académica).
    return _knownAcademicProfile(email, user.id);
  }

  AsesorNegocioModel? _knownAcademicProfile(String? email, String userId) {
    switch (email) {
      case 'asesor@pichincha.com':
        return AsesorNegocioModel(
          id: userId,
          codigoEmpleado: 'ASE-001',
          nombres: 'Carlos',
          apellidos: 'Mendoza',
          agenciaId: '101',
          perfil: 'Oficial de Crédito Principal',
          activo: true,
          rol: 'asesor',
        );
      case 'supervisor@pichincha.com':
        return AsesorNegocioModel(
          id: userId,
          codigoEmpleado: 'SUP-001',
          nombres: 'María',
          apellidos: 'Supervisor',
          agenciaId: '101',
          perfil: 'Supervisor de Crédito',
          activo: true,
          rol: 'supervisor',
        );
      default:
        return null;
    }
  }

  Future<AsesorNegocioModel?> checkCurrentSession() async {
    // 1. Check for demo session first
    final prefs = await SharedPreferences.getInstance();
    final demoRaw = prefs.getString(_demoSessionKey);
    if (demoRaw != null) {
      try {
        return AsesorNegocioModel.fromMap(json.decode(demoRaw));
      } catch (_) {}
    }

    // 2. Check standard Supabase Auth session
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return null;
    }
    
    // Check if the advisor profile is still active
    try {
      final profile = await _resolveAdvisorProfile(session.user!);
      if (profile == null || !profile.activo) {
        await signOut();
        return null;
      }
      return profile;
    } catch (_) {
      final email = session.user!.email?.trim();
      if (email != null && email.isNotEmpty) {
        try {
          final profile = await getAdvisorProfileByEmail(email);
          if (profile != null && profile.activo) return profile;
        } catch (_) {}
      }
      // Sin red: perfil mínimo desde JWT (rol asesor por defecto)
      return AsesorNegocioModel(
        id: session.user!.id,
        codigoEmpleado: 'EMP-REC',
        nombres: session.user!.email?.split('@').first ?? 'Asesor',
        apellidos: 'Recuperado',
        agenciaId: '1',
        perfil: 'Oficial',
        activo: true,
        rol: 'asesor',
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await SecureSessionService.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_demoSessionKey);
  }
}
