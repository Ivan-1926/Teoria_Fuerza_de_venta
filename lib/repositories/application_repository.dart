import '../models/application_model.dart';
import '../services/demo_data_service.dart';
import '../services/supabase_api.dart';

class ApplicationsLoadResult {
  final List<ApplicationModel> applications;
  final bool isDemo;
  final bool supabaseReachable;

  const ApplicationsLoadResult({
    required this.applications,
    required this.isDemo,
    required this.supabaseReachable,
  });
}

class ApplicationRepository {
  Future<ApplicationsLoadResult> loadApplications({String? officerId}) async {
    final reachable = await pingSupabase();
    if (reachable) {
      try {
        final raw = await fetchApplications(officerId: officerId);
        if (raw.isNotEmpty) {
          return ApplicationsLoadResult(
            applications:
                raw.map((m) => ApplicationModel.fromMap(m)).toList(),
            isDemo: false,
            supabaseReachable: true,
          );
        }
      } catch (_) {}
    }

    return ApplicationsLoadResult(
      applications: DemoDataService.demoApplications()
          .map((m) => ApplicationModel.fromMap(m))
          .toList(),
      isDemo: true,
      supabaseReachable: reachable,
    );
  }

  Future<({List<Map<String, dynamic>> clients, bool isDemo})> loadClientsForPicker() async {
    if (await pingSupabase()) {
      try {
        final list = await fetchClients();
        if (list.isNotEmpty) {
          return (clients: list, isDemo: false);
        }
      } catch (_) {}
    }
    return (clients: DemoDataService.demoClients(), isDemo: true);
  }
}
