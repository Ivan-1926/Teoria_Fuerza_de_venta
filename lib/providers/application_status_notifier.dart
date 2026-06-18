import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

class ApplicationStatusState {
  final bool isLoading;
  final List<ApplicationModel> applications;
  final String filter; // todos | enviado | comite | aprobado | desembolsado
  final bool isDemo;
  final bool supabaseReachable;
  final String? errorMessage;

  const ApplicationStatusState({
    this.isLoading = false,
    this.applications = const [],
    this.filter = 'todos',
    this.isDemo = false,
    this.supabaseReachable = false,
    this.errorMessage,
  });

  List<ApplicationModel> get filtered {
    if (filter == 'todos') return applications;
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
  }) {
    return ApplicationStatusState(
      isLoading: isLoading ?? this.isLoading,
      applications: applications ?? this.applications,
      filter: filter ?? this.filter,
      isDemo: isDemo ?? this.isDemo,
      supabaseReachable: supabaseReachable ?? this.supabaseReachable,
      errorMessage: errorMessage,
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
}

final applicationStatusNotifierProvider =
    StateNotifierProvider<ApplicationStatusNotifier, ApplicationStatusState>(
  (ref) => ApplicationStatusNotifier(),
);
