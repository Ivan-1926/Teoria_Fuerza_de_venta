import 'package:flutter/material.dart';

class ApplicationModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientDni;
  final double amount;
  final int termMonths;
  final String purpose;
  final double? monthlyPayment;
  final double interestRate;
  final String? collateral;
  final String status; // enviado, comite, aprobado, desembolsado, rechazado
  final String? officerId;
  final String? notes;
  final List<String> documentUrls;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  const ApplicationModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientDni,
    required this.amount,
    this.termMonths = 12,
    this.purpose = '',
    this.monthlyPayment,
    this.interestRate = 18.0,
    this.collateral,
    this.status = 'enviado',
    this.officerId,
    this.notes,
    this.documentUrls = const [],
    this.submittedAt,
    this.updatedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    List<String> docs = [];
    final raw = map['document_urls'];
    if (raw is List) docs = raw.map((e) => e.toString()).toList();

    return ApplicationModel(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? '',
      clientDni: map['client_dni']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      termMonths: (map['term_months'] as num?)?.toInt() ?? 12,
      purpose: map['purpose']?.toString() ?? '',
      monthlyPayment: (map['monthly_payment'] as num?)?.toDouble(),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 18.0,
      collateral: map['collateral']?.toString(),
      status: map['status']?.toString() ?? 'enviado',
      officerId: map['officer_id']?.toString(),
      notes: map['notes']?.toString(),
      documentUrls: docs,
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'client_id': clientId,
        'client_name': clientName,
        'client_dni': clientDni,
        'amount': amount,
        'term_months': termMonths,
        'purpose': purpose,
        'monthly_payment': monthlyPayment,
        'interest_rate': interestRate,
        'collateral': collateral,
        'status': status,
        'officer_id': officerId,
        'notes': notes,
        'document_urls': documentUrls,
      };

  // 0=enviado, 1=comité, 2=aprobado, 3=desembolsado
  int get statusStep {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'enviado':
        return 0;
      case 'comite':
      case 'comité':
        return 1;
      case 'aprobado':
        return 2;
      case 'desembolsado':
        return 3;
      default:
        return 0;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'enviado':
        return const Color(0xFF1976D2);
      case 'comite':
      case 'comité':
        return const Color(0xFFFFA000);
      case 'aprobado':
        return const Color(0xFF2E7D32);
      case 'desembolsado':
        return const Color(0xFF6A1B9A);
      case 'rechazado':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  bool get isFinalStatus {
    final s = status.toLowerCase();
    return s == 'desembolsado' || s == 'rechazado';
  }

  bool get canBeReviewed {
    if (isFinalStatus) return false;
    final s = status.toLowerCase();
    return s == 'enviado' ||
        s == 'pendiente' ||
        s == 'comite' ||
        s == 'comité' ||
        s == 'aprobado';
  }

  bool get canDecide {
    if (isFinalStatus) return false;
    final s = status.toLowerCase();
    return s == 'enviado' ||
        s == 'pendiente' ||
        s == 'comite' ||
        s == 'comité';
  }

  bool get hasFieldActions {
    if (needsAcceptance) return true;
    if (isUnassigned) return false;
    return canSendToCommittee;
  }

  bool get awaitsSupervisorDecision {
    final s = status.toLowerCase();
    return s == 'comite' || s == 'comité';
  }

  bool get hasPendingActions => hasFieldActions || awaitsSupervisorDecision;

  ApplicationModel copyWith({String? status, String? officerId}) {
    return ApplicationModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientDni: clientDni,
      amount: amount,
      termMonths: termMonths,
      purpose: purpose,
      monthlyPayment: monthlyPayment,
      interestRate: interestRate,
      collateral: collateral,
      status: status ?? this.status,
      officerId: officerId ?? this.officerId,
      notes: notes,
      documentUrls: documentUrls,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
    );
  }

  bool get isUnassigned => officerId == null || officerId!.isEmpty;

  bool get needsAcceptance {
    if (!canBeReviewed) return false;
    final s = status.toLowerCase();
    return (s == 'enviado' || s == 'pendiente') && isUnassigned;
  }

  bool get canSendToCommittee {
    final s = status.toLowerCase();
    return s == 'enviado' || s == 'pendiente';
  }

  bool get canMarkDisbursed => status.toLowerCase() == 'aprobado';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'enviado':
        return 'Enviado';
      case 'comite':
      case 'comité':
        return 'En Comité';
      case 'aprobado':
        return 'Aprobado';
      case 'desembolsado':
        return 'Desembolsado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return status;
    }
  }
}
