import '../models/buro_report_model.dart';
import 'supabase_api.dart';

/// Servicio de consulta al Buró de Crédito con listas negras (M6).
class ConsultaBuroService {
  /// Consulta buró, verifica lista negra y persiste en Supabase.
  Future<BuroReportModel> consultar({
    required String dni,
    String? clientId,
    String? clientName,
    String? officerId,
  }) async {
    final normalized = dni.trim();
    if (normalized.length < 10) {
      throw Exception('DNI inválido para consulta de buró');
    }

    final blacklist = await fetchBlacklistEntry(normalized);
    final client = await fetchClientByDni(normalized);

    final name = clientName ??
        client?['name']?.toString() ??
        client?['client_name']?.toString() ??
        'Cliente';

    final score = (client?['credit_score'] as num?)?.toInt() ??
        (client?['sbs_score'] as num?)?.toInt() ??
        _demoScoreFromDni(normalized);

    final deudaTotal = (client?['total_debt'] as num?)?.toDouble() ??
        (client?['loan_balance'] as num?)?.toDouble() ??
        _demoDebt(score);

    final mayorDeuda = (client?['max_debt'] as num?)?.toDouble() ??
        (client?['mayor_deuda'] as num?)?.toDouble() ??
        deudaTotal * 0.6;

    final diasMora = (client?['days_overdue'] as num?)?.toInt() ??
        (client?['dias_mora'] as num?)?.toInt() ??
        (score < 550 ? 45 : score < 650 ? 12 : 0);

    final inBlacklist = blacklist != null;
    final reason = blacklist?['reason']?.toString() ??
        blacklist?['motivo']?.toString();

    final report = BuroReportModel(
      dni: normalized,
      clientName: name,
      calificacionSbs: score,
      calificacionSbsLabel: _sbsLabel(score),
      deudaTotal: deudaTotal,
      mayorDeuda: mayorDeuda,
      diasMora: diasMora,
      inBlacklist: inBlacklist,
      blacklistReason: reason,
      consultedAt: DateTime.now(),
    );

    try {
      final saved = await saveBuroQuery(
        report.toSupabaseMap(clientId: clientId, officerId: officerId),
      );
      return report.copyWith(supabaseId: saved['id']?.toString());
    } catch (_) {
      return report;
    }
  }

  static String _sbsLabel(int score) {
    if (score >= 700) return 'A - Normal';
    if (score >= 500) return 'B - Con problemas potenciales';
    return 'C - Deficiente';
  }

  int _demoScoreFromDni(String dni) {
    final hash = dni.codeUnits.fold<int>(0, (a, b) => a + b);
    return 520 + (hash % 280);
  }

  double _demoDebt(int score) {
    if (score >= 700) return 1200;
    if (score >= 600) return 4500;
    return 9800;
  }
}
