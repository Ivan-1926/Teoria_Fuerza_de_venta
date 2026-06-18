class DailyPortfolioModel {
  final String id;
  final String clientId;
  final String clientName;
  final String officerId;
  final String nextVisitDate; // stored as string format 'YYYY-MM-DD'
  final double loanBalance;
  final int daysOverdue;
  final String? loanNumber;
  final String? purpose;
  final String renewalType; // renovation | new | collection
  final int priority;
  final bool visited; // solved dynamically by correlating with route_visits

  const DailyPortfolioModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.officerId,
    required this.nextVisitDate,
    required this.loanBalance,
    required this.daysOverdue,
    this.loanNumber,
    this.purpose,
    required this.renewalType,
    required this.priority,
    this.visited = false,
  });

  DailyPortfolioModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? officerId,
    String? nextVisitDate,
    double? loanBalance,
    int? daysOverdue,
    String? loanNumber,
    String? purpose,
    String? renewalType,
    int? priority,
    bool? visited,
  }) {
    return DailyPortfolioModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      officerId: officerId ?? this.officerId,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      loanBalance: loanBalance ?? this.loanBalance,
      daysOverdue: daysOverdue ?? this.daysOverdue,
      loanNumber: loanNumber ?? this.loanNumber,
      purpose: purpose ?? this.purpose,
      renewalType: renewalType ?? this.renewalType,
      priority: priority ?? this.priority,
      visited: visited ?? this.visited,
    );
  }

  factory DailyPortfolioModel.fromMap(Map<String, dynamic> map, {bool visited = false}) {
    return DailyPortfolioModel(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? '',
      officerId: map['officer_id']?.toString() ?? '',
      nextVisitDate: map['next_visit_date']?.toString() ?? '',
      loanBalance: (map['loan_balance'] as num?)?.toDouble() ?? 0.0,
      daysOverdue: (map['days_overdue'] as num?)?.toInt() ?? 0,
      loanNumber: map['loan_number']?.toString(),
      purpose: map['purpose']?.toString() ?? 'Crédito',
      renewalType: map['renewal_type']?.toString() ?? 'renovation',
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      visited: visited,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'officer_id': officerId,
        'next_visit_date': nextVisitDate,
        'loan_balance': loanBalance,
        'days_overdue': daysOverdue,
        'loan_number': loanNumber,
        'purpose': purpose,
        'renewal_type': renewalType,
        'priority': priority,
      };
}
