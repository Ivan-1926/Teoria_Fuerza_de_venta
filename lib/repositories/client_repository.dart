import '../models/client_profile_model.dart';
import '../services/supabase_api.dart';

/// Repositorio de datos de clientes para M3.
class ClientRepository {
  /// Carga el perfil completo del cliente desde Supabase (tabla `clients`)
  /// y sus créditos activos (tabla `credit_applications`).
  Future<ClientProfileModel> fetchClientProfile(String clientId) async {
    // Fetch client data
    final clientData = await fetchClientById(clientId);
    if (clientData == null) {
      throw Exception('Cliente no encontrado: $clientId');
    }

    // Fetch active credits (status: aprobado)
    final allApps = await fetchApplications(
      clientId: clientId,
      status: 'aprobado',
    );

    return ClientProfileModel.fromMap(clientData, activeCredits: allApps);
  }

  /// Carga solo los créditos activos del cliente.
  Future<List<Map<String, dynamic>>> fetchActiveCredits(String clientId) async {
    return fetchApplications(clientId: clientId, status: 'aprobado');
  }

  /// Carga el historial completo de solicitudes (todos los estados).
  Future<List<Map<String, dynamic>>> fetchCreditHistory(String clientId) async {
    return fetchApplications(clientId: clientId);
  }
}
