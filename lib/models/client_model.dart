import 'package:flutter/material.dart';

class ClientModel {
  final String id;
  final String name;
  final String dni;
  final String phone;
  final String email;
  final String address;
  final double? lat;
  final double? lng;
  final int creditScore;
  final double totalDebt;
  final double monthlyIncome;
  final String occupation;
  final String businessName;
  final String status; // active, blacklisted, inactive
  final String? officerId;
  final DateTime? createdAt;

  const ClientModel({
    required this.id,
    required this.name,
    required this.dni,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.lat,
    this.lng,
    this.creditScore = 0,
    this.totalDebt = 0,
    this.monthlyIncome = 0,
    this.occupation = '',
    this.businessName = '',
    this.status = 'active',
    this.officerId,
    this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['client_name']?.toString() ?? '',
      dni: map['dni']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      creditScore: (map['credit_score'] as num?)?.toInt() ?? 650,
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0,
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0,
      occupation: map['occupation']?.toString() ?? '',
      businessName: map['business_name']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
      officerId: map['officer_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dni': dni,
        'phone': phone,
        'email': email,
        'address': address,
        'lat': lat,
        'lng': lng,
        'credit_score': creditScore,
        'total_debt': totalDebt,
        'monthly_income': monthlyIncome,
        'occupation': occupation,
        'business_name': businessName,
        'status': status,
        'officer_id': officerId,
      };

  String get creditScoreLabel {
    if (creditScore >= 800) return 'Excelente';
    if (creditScore >= 700) return 'Muy Bueno';
    if (creditScore >= 600) return 'Bueno';
    if (creditScore >= 500) return 'Regular';
    return 'Bajo';
  }

  Color get creditScoreColor {
    if (creditScore >= 800) return const Color(0xFF2E7D32);
    if (creditScore >= 700) return const Color(0xFF388E3C);
    if (creditScore >= 600) return const Color(0xFFF9A825);
    if (creditScore >= 500) return const Color(0xFFF57C00);
    return const Color(0xFFC62828);
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}
