/// Modelo completo del borrador de solicitud de crédito (M5).
/// Cubre los 4 pasos del wizard y la firma digital.
class CreditApplicationDraftModel {
  final String? id; // UUID SQLite local

  // Paso 1 — Datos del cliente
  final String clientName;
  final String clientDni;
  final String clientPhone;
  final String clientEmail;
  final String clientAddress;

  // Paso 2 — Datos del negocio
  final String businessName;
  final String businessSector;
  final String businessAddress;
  final double monthlyIncome;
  final int businessAgeYears;

  // Paso 3 — Condiciones del crédito
  final double amount;
  final int termMonths;
  final double tea; // Tasa Efectiva Anual

  // Calculados (simulador)
  final double? monthlyPayment;
  final double? totalInterest;
  final double? totalAmount;

  // Paso 4 — Firma y estado
  final String? signatureBase64;
  final String status; // 'draft' | 'submitted'

  // Metadatos
  final String? officerId;
  final String? supabaseId; // id una vez enviado
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditApplicationDraftModel({
    this.id,
    this.clientName = '',
    this.clientDni = '',
    this.clientPhone = '',
    this.clientEmail = '',
    this.clientAddress = '',
    this.businessName = '',
    this.businessSector = '',
    this.businessAddress = '',
    this.monthlyIncome = 0,
    this.businessAgeYears = 0,
    this.amount = 0,
    this.termMonths = 12,
    this.tea = 18.0,
    this.monthlyPayment,
    this.totalInterest,
    this.totalAmount,
    this.signatureBase64,
    this.status = 'draft',
    this.officerId,
    this.supabaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory CreditApplicationDraftModel.fromMap(Map<String, dynamic> m) {
    return CreditApplicationDraftModel(
      id: m['id']?.toString(),
      clientName: m['client_name']?.toString() ?? '',
      clientDni: m['client_dni']?.toString() ?? '',
      clientPhone: m['client_phone']?.toString() ?? '',
      clientEmail: m['client_email']?.toString() ?? '',
      clientAddress: m['client_address']?.toString() ?? '',
      businessName: m['business_name']?.toString() ?? '',
      businessSector: m['business_sector']?.toString() ?? '',
      businessAddress: m['business_address']?.toString() ?? '',
      monthlyIncome: (m['monthly_income'] as num?)?.toDouble() ?? 0,
      businessAgeYears: (m['business_age_years'] as num?)?.toInt() ?? 0,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      termMonths: (m['term_months'] as num?)?.toInt() ?? 12,
      tea: (m['tea'] as num?)?.toDouble() ?? 18.0,
      monthlyPayment: (m['monthly_payment'] as num?)?.toDouble(),
      totalInterest: (m['total_interest'] as num?)?.toDouble(),
      totalAmount: (m['total_amount'] as num?)?.toDouble(),
      signatureBase64: m['signature_base64']?.toString(),
      status: m['status']?.toString() ?? 'draft',
      officerId: m['officer_id']?.toString(),
      supabaseId: m['supabase_id']?.toString(),
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: m['updated_at'] != null
          ? DateTime.tryParse(m['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'client_name': clientName,
        'client_dni': clientDni,
        'client_phone': clientPhone,
        'client_email': clientEmail,
        'client_address': clientAddress,
        'business_name': businessName,
        'business_sector': businessSector,
        'business_address': businessAddress,
        'monthly_income': monthlyIncome,
        'business_age_years': businessAgeYears,
        'amount': amount,
        'term_months': termMonths,
        'tea': tea,
        'monthly_payment': monthlyPayment,
        'total_interest': totalInterest,
        'total_amount': totalAmount,
        'signature_base64': signatureBase64,
        'status': status,
        'officer_id': officerId,
        'supabase_id': supabaseId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Genera el payload para enviar a Supabase credit_applications
  Map<String, dynamic> toSupabasePayload() => {
        'client_name': clientName,
        'client_dni': clientDni,
        'amount': amount,
        'term_months': termMonths,
        'tea': tea,
        'monthly_payment': monthlyPayment,
        'purpose': businessSector.isNotEmpty ? businessSector : 'Capital de trabajo',
        'business_name': businessName,
        'monthly_income': monthlyIncome,
        'status': 'pendiente',
        'officer_id': officerId,
        'submitted_at': DateTime.now().toIso8601String(),
      };

  CreditApplicationDraftModel copyWith({
    String? id,
    String? clientName,
    String? clientDni,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
    String? businessName,
    String? businessSector,
    String? businessAddress,
    double? monthlyIncome,
    int? businessAgeYears,
    double? amount,
    int? termMonths,
    double? tea,
    double? monthlyPayment,
    double? totalInterest,
    double? totalAmount,
    String? signatureBase64,
    String? status,
    String? officerId,
    String? supabaseId,
  }) {
    return CreditApplicationDraftModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientDni: clientDni ?? this.clientDni,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      businessName: businessName ?? this.businessName,
      businessSector: businessSector ?? this.businessSector,
      businessAddress: businessAddress ?? this.businessAddress,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      businessAgeYears: businessAgeYears ?? this.businessAgeYears,
      amount: amount ?? this.amount,
      termMonths: termMonths ?? this.termMonths,
      tea: tea ?? this.tea,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalInterest: totalInterest ?? this.totalInterest,
      totalAmount: totalAmount ?? this.totalAmount,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      status: status ?? this.status,
      officerId: officerId ?? this.officerId,
      supabaseId: supabaseId ?? this.supabaseId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
