import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asesor_negocio_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AsesorNegocioModel? advisor;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.advisor,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AsesorNegocioModel? advisor,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      advisor: advisor ?? this.advisor,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final advisor = await _repository.signIn(email, password);
      if (advisor != null) {
        // Adapt to legacy AuthService so that other screens don't break
        AuthService.syncWithSession({
          'id': advisor.id,
          'name': advisor.nombreCompleto,
          'email': email,
          'zone':
              'Agencia #${advisor.agenciaId} · ${advisor.perfil} · ${advisor.rol}',
          'phone': advisor.codigoEmpleado,
        });

        state = AuthState(status: AuthStatus.authenticated, advisor: advisor);
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Credenciales inválidas.',
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> recoverSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final advisor = await _repository.checkCurrentSession();
      if (advisor != null) {
        // Check if advisor is still active
        if (!advisor.activo) {
          await logout(inactiveReason: true);
          return;
        }

        // Adapt to legacy AuthService
        AuthService.syncWithSession({
          'id': advisor.id,
          'name': advisor.nombreCompleto,
          'email':
              Supabase.instance.client.auth.currentSession?.user.email ?? '',
          'zone':
              'Agencia #${advisor.agenciaId} · ${advisor.perfil} · ${advisor.rol}',
          'phone': advisor.codigoEmpleado,
        });

        state = AuthState(status: AuthStatus.authenticated, advisor: advisor);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout({bool inactiveReason = false}) async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.signOut();
    AuthService.clearSession();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: inactiveReason
          ? 'Su sesión ha sido cerrada debido a que su usuario está INACTIVO.'
          : null,
    );
  }

  // Force session checks in repositories
  Future<bool> verifyActiveStatus() async {
    if (state.advisor == null) return false;
    if (!state.advisor!.activo) {
      await logout(inactiveReason: true);
      return false;
    }
    try {
      final email =
          Supabase.instance.client.auth.currentSession?.user.email?.trim();
      if (email != null && email.isNotEmpty) {
        final profile = await _repository.getAdvisorProfileByEmail(email);
        if (profile != null && !profile.activo) {
          await logout(inactiveReason: true);
          return false;
        }
        return true;
      }
      final advisorId = state.advisor!.id;
      if (int.tryParse(advisorId) == null) {
        return true;
      }
      final profile = await _repository.getAdvisorProfile(advisorId);
      if (profile != null && !profile.activo) {
        await logout(inactiveReason: true);
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
