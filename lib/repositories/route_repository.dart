import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_visit_model.dart';
import '../services/demo_data_service.dart';

class RouteRepository {
  final SupabaseClient _supabase;

  RouteRepository(this._supabase);

  Future<List<RouteVisitModel>> fetchRouteVisits(String date, {String? officerId}) async {
    final useDemoFallback =
        officerId == null || officerId.isEmpty || officerId == 'demo-officer-001';

    try {
      final officerIds = await _resolveOfficerIds(officerId);
      var query = _supabase.from('fv_route_visits').select().eq('visit_date', date);
      if (officerIds.isNotEmpty) {
        query = query.inFilter('officer_id', officerIds);
      }
      final data = await query.order('visit_order', ascending: true);
      final visits = data.map<RouteVisitModel>((m) => RouteVisitModel.fromMap(m)).toList();
      if (visits.isEmpty && useDemoFallback) {
        return _demoVisits(date);
      }
      return visits;
    } catch (e) {
      if (useDemoFallback) {
        return _demoVisits(date);
      }
      throw Exception('Error al obtener visitas de ruta: ${e.toString()}');
    }
  }

  /// Acepta id de asesores_negocio, uuid Auth o sesión académica.
  Future<List<String>> _resolveOfficerIds(String? officerId) async {
    if (officerId == null || officerId.isEmpty || officerId == 'demo-officer-001') {
      return const [];
    }

    final ids = <String>{officerId};

    final authId = _supabase.auth.currentUser?.id;
    if (authId != null && authId.isNotEmpty) {
      ids.add(authId);
    }

    final email = _supabase.auth.currentUser?.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      try {
        final row = await _supabase
            .from('asesores_negocio')
            .select('id')
            .eq('email', email)
            .maybeSingle();
        final dbId = row?['id']?.toString();
        if (dbId != null && dbId.isNotEmpty) {
          ids.add(dbId);
        }
      } catch (_) {}
    }

    return ids.toList();
  }

  List<RouteVisitModel> _demoVisits(String date) {
    return DemoDataService.demoRouteVisits(date)
        .map(RouteVisitModel.fromMap)
        .toList();
  }

  Future<void> updateVisitStatus(String visitId, String status) async {
    try {
      await _supabase
          .from('fv_route_visits')
          .update({'visit_status': status})
          .eq('id', visitId);
    } catch (e) {
      throw Exception('Error al actualizar estado de visita: ${e.toString()}');
    }
  }

  Future<void> saveOptimizedRouteOrder(List<RouteVisitModel> optimizedVisits) async {
    try {
      // Perform batch upsert to update visit_order for all visits
      final List<Map<String, dynamic>> payload = [];
      for (int i = 0; i < optimizedVisits.length; i++) {
        payload.add({
          'id': optimizedVisits[i].id,
          'visit_order': i + 1,
        });
      }
      if (payload.isNotEmpty) {
        await _supabase.from('fv_route_visits').upsert(payload);
      }
    } catch (e) {
      throw Exception('Error al guardar optimización de ruta: ${e.toString()}');
    }
  }
}
