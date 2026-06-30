import '../models/buro_report_model.dart';
import 'buro_por_dni.dart';
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
    if (normalized.length < 8) {
      throw Exception('DNI inválido para consulta de buró');
    }

    final blacklist = await fetchBlacklistEntry(normalized);
    final client = await fetchClientByDni(normalized);
    final perfilDni = PerfilBuroPorDni.fromDni(normalized);

    final name = clientName ??
        client?['name']?.toString() ??
        client?['client_name']?.toString() ??
        'Cliente';

    final score = (client?['credit_score'] as num?)?.toInt() ??
        (client?['sbs_score'] as num?)?.toInt() ??
        perfilDni.scoreNumerico;

    final deudaTotal = (client?['total_debt'] as num?)?.toDouble() ??
        (client?['loan_balance'] as num?)?.toDouble() ??
        perfilDni.deudaTotal;

    final mayorDeuda = (client?['max_debt'] as num?)?.toDouble() ??
        (client?['mayor_deuda'] as num?)?.toDouble() ??
        (deudaTotal * 0.6);

    final diasMora = (client?['days_overdue'] as num?)?.toInt() ??
        (client?['dias_mora'] as num?)?.toInt() ??
        perfilDni.diasMora;

    final inBlacklist = blacklist != null ||
        client?['status']?.toString().toLowerCase() == 'blacklisted' ||
        perfilDni.enListaInhabilitados;

    final calificacion = client?['buro_rating']?.toString() ?? perfilDni.calificacion;

    final reason = blacklist?['reason']?.toString() ??
        blacklist?['motivo']?.toString() ??
        (perfilDni.enListaInhabilitados
            ? 'Registrado en lista de inhabilitados del sistema financiero'
            : null);

    final report = BuroReportModel(
      dni: normalized,
      clientName: name,
      calificacionSbs: score,
      calificacionSbsLabel: _labelFromCalificacion(calificacion, score),
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

  static String _labelFromCalificacion(String calificacion, int score) {
    switch (calificacion.toUpperCase()) {
      case 'NORMAL':
        return 'NORMAL — Sin mora relevante';
      case 'CPP':
        return 'CPP — Con problemas de pago';
      case 'DEFICIENTE':
        return 'DEFICIENTE — Morosidad significativa';
      case 'DUDOSO':
        return 'DUDOSO — Alto riesgo';
      case 'PERDIDA':
        return 'PERDIDA — Cartera castigada';
      default:
        if (score >= 700) return 'A - Normal';
        if (score >= 500) return 'B - Con problemas potenciales';
        return 'C - Deficiente';
    }
  }
}
