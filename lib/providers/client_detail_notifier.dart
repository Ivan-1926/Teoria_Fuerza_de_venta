import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_profile_model.dart';
import '../repositories/client_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class ClientDetailState {
  final bool isLoading;
  final ClientProfileModel? profile;
  final List<Map<String, dynamic>> creditHistory;
  final String? errorMessage;

  const ClientDetailState({
    this.isLoading = false,
    this.profile,
    this.creditHistory = const [],
    this.errorMessage,
  });

  ClientDetailState copyWith({
    bool? isLoading,
    ClientProfileModel? profile,
    List<Map<String, dynamic>>? creditHistory,
    String? errorMessage,
  }) {
    return ClientDetailState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      creditHistory: creditHistory ?? this.creditHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ClientDetailNotifier extends Notifier<ClientDetailState> {
  final _repo = ClientRepository();

  @override
  ClientDetailState build() => const ClientDetailState(isLoading: false);

  /// Carga el perfil completo del cliente y su historial crediticio.
  Future<void> loadProfile(String clientId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repo.fetchClientProfile(clientId);
      final history = await _repo.fetchCreditHistory(clientId);
      state = state.copyWith(
        isLoading: false,
        profile: profile,
        creditHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar el perfil: ${e.toString()}',
      );
    }
  }

  /// Carga un perfil directamente desde un Map existente (cuando ya tenemos
  /// los datos básicos del cliente desde la cartera, evitando una llamada extra).
  Future<void> loadProfileFromMap(Map<String, dynamic> clientMap) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final clientId = clientMap['client_id']?.toString() ??
          clientMap['id']?.toString() ?? '';

      List<Map<String, dynamic>> history = [];
      ClientProfileModel profile;

      if (clientId.isNotEmpty) {
        // Intenta enriquecer desde Supabase
        try {
          profile = await _repo.fetchClientProfile(clientId);
          history = await _repo.fetchCreditHistory(clientId);
        } catch (_) {
          // Fallback: construye perfil desde el Map local
          profile = ClientProfileModel.fromMap(clientMap);
        }
      } else {
        profile = ClientProfileModel.fromMap(clientMap);
      }

      state = state.copyWith(
        isLoading: false,
        profile: profile,
        creditHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar el perfil: ${e.toString()}',
      );
    }
  }
}
