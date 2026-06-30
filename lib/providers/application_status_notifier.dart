import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

class ApplicationStatusState {
  final bool isLoading;
  final List<ApplicationModel> applications;
  final String filter; // todos | enviado | comite | aprobado | desembolsado | rechazado
  final bool isDemo;
  final bool supabaseReachable;
  final String? errorMessage;
  final String? updatingId;

  const ApplicationStatusState({
    this.isLoading = false,
    this.applications = const [],
    this.filter = 'todos',
    this.isDemo = false,
    this.supabaseReachable = false,
    this.errorMessage,
    this.updatingId,
  });

  List<ApplicationModel> get filtered {
    if (filter == 'todos') return applications;
    if (filter == 'enviado') {
      return applications.where((a) {
        final s = a.status.toLowerCase();
        return s == 'enviado' || s == 'pendiente';
      }).toList();
    }
    return applications
        .where((a) => a.status.toLowerCase() == filter.toLowerCase())
        .toList();
  }

  int countByStatus(String status) => applications
      .where((a) => a.status.toLowerCase() == status.toLowerCase())
      .length;

  ApplicationStatusState copyWith({
    bool? isLoading,
    List<ApplicationModel>? applications,
    String? filter,
    bool? isDemo,
    bool? supabaseReachable,
    String? errorMessage,
    String? updatingId,
    bool clearUpdatingId = false,
  }) {
    return ApplicationStatusState(
      isLoading: isLoading ?? this.isLoading,
      applications: applications ?? this.applications,
      filter: filter ?? this.filter,
      isDemo: isDemo ?? this.isDemo,
      supabaseReachable: supabaseReachable ?? this.supabaseReachable,
      errorMessage: errorMessage,
      updatingId: clearUpdatingId ? null : (updatingId ?? this.updatingId),
    );
  }
}

class ApplicationStatusNotifier extends StateNotifier<ApplicationStatusState> {
  final ApplicationRepository _repo = ApplicationRepository();
  String? _officerId;

  ApplicationStatusNotifier() : super(const ApplicationStatusState());

  void setOfficerId(String? id) => _officerId = id;

  Future<void> load({String? officerId}) async {
    if (officerId != null) _officerId = officerId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.loadApplications(officerId: _officerId);
      state = state.copyWith(
        isLoading: false,
        applications: result.applications,
        isDemo: result.isDemo,
        supabaseReachable: result.supabaseReachable,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<String?> updateApplication(
    String id, {
    String? status,
    String? officerId,
  }) async {
    state = state.copyWith(updatingId: id, errorMessage: null);
    try {
      final patch = <String, dynamic>{};
      if (status != null) patch['status'] = status;
      if (officerId != null) patch['officer_id'] = officerId;
      if (patch.isEmpty) {
        state = state.copyWith(clearUpdatingId: true);
        return null;
      }

      if (_isDemoApplicationId(id)) {
        state = state.copyWith(clearUpdatingId: true);
        return 'Solicitud de ejemplo: inicie sesión con datos reales de Supabase '
            'para enviar al comité.';
      }

      if (state.supabaseReachable) {
        await _repo.patchApplication(id, patch);
      } else if (state.isDemo) {
        // Sin red: solo reflejo local en modo demo offline.
      } else {
        state = state.copyWith(clearUpdatingId: true);
        return 'Sin conexión con el servidor.';
      }

      final updated = state.applications
          .map(
            (a) => a.id == id
                ? a.copyWith(
                    status: status ?? a.status,
                    officerId: officerId ?? a.officerId,
                  )
                : a,
          )
          .toList();
      state = state.copyWith(
        applications: updated,
        clearUpdatingId: true,
      );
      return null;
    } catch (e) {
      state = state.copyWith(clearUpdatingId: true);
      return e.toString();
    }
  }

  bool _isDemoApplicationId(String id) =>
      id.startsWith('app-demo-') || id.startsWith('sol-');

  Future<String?> acceptApplication(String id, String officerId) {
    return updateApplication(
      id,
      officerId: officerId,
      status: 'enviado',
    );
  }

  Future<String?> reviewApplication(String id, String newStatus) {
    return updateApplication(id, status: newStatus);
  }
}

final applicationStatusNotifierProvider =
    StateNotifierProvider<ApplicationStatusNotifier, ApplicationStatusState>(
  (ref) => ApplicationStatusNotifier(),
);
