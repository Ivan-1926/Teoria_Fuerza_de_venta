import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/format_utils.dart';
import '../models/daily_portfolio_model.dart';

class PortfolioRepository {
  final SupabaseClient _supabase;

  PortfolioRepository(this._supabase);

  Future<List<DailyPortfolioModel>> fetchDailyPortfolio(String officerId) async {
    try {
      // 1. Fetch daily portfolio rows
      var query = _supabase.from('fv_daily_portfolio').select();
      if (officerId.isNotEmpty && officerId != 'demo-officer-001') {
        query = query.eq('officer_id', officerId);
      }
      final portfolioData = await query.order('priority', ascending: false);

      // 2. Fetch today's route visits to check visited status
      final todayStr = FormatUtils.dateYmd(DateTime.now());
      var visitsQuery = _supabase.from('fv_route_visits').select('client_id, visit_status').eq('visit_date', todayStr);
      if (officerId.isNotEmpty && officerId != 'demo-officer-001') {
        visitsQuery = visitsQuery.eq('officer_id', officerId);
      }
      final visitsData = await visitsQuery;

      // 3. Create a set of visited client IDs
      final visitedClientIds = visitsData
          .where((v) => v['visit_status'] == 'visited')
          .map((v) => v['client_id']?.toString())
          .whereType<String>()
          .toSet();

      // 4. Map to models
      return portfolioData.map<DailyPortfolioModel>((map) {
        final clientId = map['client_id']?.toString() ?? '';
        final isVisited = visitedClientIds.contains(clientId);
        return DailyPortfolioModel.fromMap(map, visited: isVisited);
      }).toList();
    } catch (e) {
      throw Exception('Error al consultar cartera: ${e.toString()}');
    }
  }
}
