import 'package:flutter/material.dart';

/// Modelo enriquecido para la Ficha de Cliente (M3).
/// Extiende los campos base de ClientModel con datos de negocio y SBS.
class ClientProfileModel {
  final String id;
  final String name;
  final String dni;
  final String phone;
  final String email;
  final String address;

  // Datos del negocio
  final String businessName;
  final String businessSector;
  final String businessAddress;
  final double monthlyIncome;
  final int businessAgeYears;

  // Score crediticio / SBS
  final int creditScore;
  final double totalDebt;
  final String clientStatus; // active, blacklisted, inactive

  // Créditos activos (lista de solicitudes aprobadas)
  final List<Map<String, dynamic>> activeCredits;

  // Metadatos
  final String? officerId;
  final DateTime? createdAt;

  const ClientProfileModel({
    required this.id,
    required this.name,
    required this.dni,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.businessName = '',
    this.businessSector = '',
    this.businessAddress = '',
    this.monthlyIncome = 0,
    this.businessAgeYears = 0,
    this.creditScore = 650,
    this.totalDebt = 0,
    this.clientStatus = 'active',
    this.activeCredits = const [],
    this.officerId,
    this.createdAt,
  });

  factory ClientProfileModel.fromMap(
    Map<String, dynamic> map, {
    List<Map<String, dynamic>> activeCredits = const [],
  }) {
    return ClientProfileModel(
      id: map['id']?.toString() ??
          map['client_id']?.toString() ??
          '',
      name: map['name']?.toString() ?? map['client_name']?.toString() ?? '',
      dni: map['dni']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      businessName: map['business_name']?.toString() ?? '',
      businessSector: map['business_sector']?.toString() ?? '',
      businessAddress: map['business_address']?.toString() ?? map['address']?.toString() ?? '',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0,
      businessAgeYears: (map['business_age_years'] as num?)?.toInt() ?? 0,
      creditScore: (map['credit_score'] as num?)?.toInt() ??
          (map['sbs_score'] as num?)?.toInt() ?? 650,
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0,
      clientStatus: map['status']?.toString() ?? 'active',
      activeCredits: activeCredits,
      officerId: map['officer_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  // ── Score SBS semáforo ───────────────────────────────────────────────────────

  /// Color del semáforo SBS: Verde ≥ 700, Amarillo 500–699, Rojo < 500
  Color get semaphoreColor {
    if (creditScore >= 700) return const Color(0xFF2E7D32);
    if (creditScore >= 500) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  /// Etiqueta de riesgo SBS
  String get semaphoreLabel {
    if (creditScore >= 700) return 'Bajo Riesgo';
    if (creditScore >= 500) return 'Riesgo Medio';
    return 'Alto Riesgo';
  }

  /// Estado semáforo: 'green' | 'yellow' | 'red'
  String get semaphoreStatus {
    if (creditScore >= 700) return 'green';
    if (creditScore >= 500) return 'yellow';
    return 'red';
  }

  /// Etiqueta crediticia
  String get scoreLabel {
    if (creditScore >= 800) return 'Excelente';
    if (creditScore >= 700) return 'Muy Bueno';
    if (creditScore >= 600) return 'Bueno';
    if (creditScore >= 500) return 'Regular';
    return 'Bajo';
  }

  // ── Oferta preaprobada ───────────────────────────────────────────────────────

  bool get hasPreApprovedOffer => creditScore >= 650;

  /// Monto preaprobado estimado = ingresos mensuales × 4
  double get preApprovedAmount => monthlyIncome * 4;

  // ── Iniciales para avatar ────────────────────────────────────────────────────
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': id,
        'client_name': name,
        'name': name,
        'dni': dni,
        'phone': phone,
        'email': email,
        'address': address,
        'business_name': businessName,
        'business_sector': businessSector,
        'business_address': businessAddress,
        'monthly_income': monthlyIncome,
        'business_age_years': businessAgeYears,
        'credit_score': creditScore,
        'total_debt': totalDebt,
        'status': clientStatus,
        'officer_id': officerId,
      };
}
