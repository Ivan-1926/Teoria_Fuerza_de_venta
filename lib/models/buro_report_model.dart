/// Resultado de consulta_buro (M6 — Buró de crédito).
class BuroReportModel {
  final String dni;
  final String clientName;
  final int calificacionSbs; // puntaje numérico SBS
  final String calificacionSbsLabel; // A, B, C, etc.
  final double deudaTotal;
  final double mayorDeuda;
  final int diasMora;
  final bool inBlacklist;
  final String? blacklistReason;
  final DateTime consultedAt;
  final String? supabaseId;

  const BuroReportModel({
    required this.dni,
    required this.clientName,
    required this.calificacionSbs,
    required this.calificacionSbsLabel,
    required this.deudaTotal,
    required this.mayorDeuda,
    required this.diasMora,
    this.inBlacklist = false,
    this.blacklistReason,
    required this.consultedAt,
    this.supabaseId,
  });

  bool get isCleared => !inBlacklist;

  String get ratingLabel => calificacionSbsLabel;

  BuroReportModel copyWith({String? supabaseId, bool? inBlacklist}) {
    return BuroReportModel(
      dni: dni,
      clientName: clientName,
      calificacionSbs: calificacionSbs,
      calificacionSbsLabel: calificacionSbsLabel,
      deudaTotal: deudaTotal,
      mayorDeuda: mayorDeuda,
      diasMora: diasMora,
      inBlacklist: inBlacklist ?? this.inBlacklist,
      blacklistReason: blacklistReason,
      consultedAt: consultedAt,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  factory BuroReportModel.fromMap(Map<String, dynamic> m) {
    final score = (m['calificacion_sbs'] as num?)?.toInt() ??
        (m['sbs_score'] as num?)?.toInt() ??
        (m['score'] as num?)?.toInt() ??
        650;
    return BuroReportModel(
      dni: m['dni']?.toString() ?? '',
      clientName: m['client_name']?.toString() ?? m['name']?.toString() ?? '',
      calificacionSbs: score,
      calificacionSbsLabel: m['calificacion_sbs_label']?.toString() ??
          _labelFromScore(score),
      deudaTotal: (m['deuda_total'] as num?)?.toDouble() ??
          (m['total_debt'] as num?)?.toDouble() ??
          0,
      mayorDeuda: (m['mayor_deuda'] as num?)?.toDouble() ??
          (m['max_debt'] as num?)?.toDouble() ??
          0,
      diasMora: (m['dias_mora'] as num?)?.toInt() ??
          (m['days_overdue'] as num?)?.toInt() ??
          0,
      inBlacklist: m['in_blacklist'] == true || m['blacklisted'] == true,
      blacklistReason: m['blacklist_reason']?.toString(),
      consultedAt: m['consulted_at'] != null
          ? DateTime.tryParse(m['consulted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      supabaseId: m['id']?.toString(),
    );
  }

  static String _labelFromScore(int score) {
    if (score >= 700) return 'A - Normal';
    if (score >= 500) return 'B - Con problemas potenciales';
    return 'C - Deficiente';
  }

  Map<String, dynamic> toSupabaseMap({
    String? clientId,
    String? officerId,
  }) =>
      {
        'dni': dni,
        'client_name': clientName,
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
        'calificacion_sbs': calificacionSbs,
        'calificacion_sbs_label': calificacionSbsLabel,
        'deuda_total': deudaTotal,
        'mayor_deuda': mayorDeuda,
        'dias_mora': diasMora,
        'in_blacklist': inBlacklist,
        'blacklist_reason': blacklistReason,
        'consulted_at': consultedAt.toIso8601String(),
        'officer_id': ?officerId,
      };
}
