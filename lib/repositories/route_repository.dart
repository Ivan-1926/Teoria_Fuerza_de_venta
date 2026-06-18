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
      var query = _supabase.from('fv_route_visits').select().eq('visit_date', date);
      if (officerId != null && officerId.isNotEmpty && officerId != 'demo-officer-001') {
        query = query.eq('officer_id', officerId);
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
