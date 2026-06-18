class RouteVisitModel {
  final String id;
  final String officerId;
  final String clientId;
  final String clientName;
  final String visitDate; // stored as string format 'YYYY-MM-DD'
  final int visitOrder;
  final String address;
  final double? lat;
  final double? lng;
  final String? estimatedTime;
  final String visitStatus; // pending | visited | skipped
  final String? notes;

  const RouteVisitModel({
    required this.id,
    required this.officerId,
    required this.clientId,
    required this.clientName,
    required this.visitDate,
    required this.visitOrder,
    required this.address,
    this.lat,
    this.lng,
    this.estimatedTime,
    required this.visitStatus,
    this.notes,
  });

  RouteVisitModel copyWith({
    String? id,
    String? officerId,
    String? clientId,
    String? clientName,
    String? visitDate,
    int? visitOrder,
    String? address,
    double? lat,
    double? lng,
    String? estimatedTime,
    String? visitStatus,
    String? notes,
  }) {
    return RouteVisitModel(
      id: id ?? this.id,
      officerId: officerId ?? this.officerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      visitDate: visitDate ?? this.visitDate,
      visitOrder: visitOrder ?? this.visitOrder,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      visitStatus: visitStatus ?? this.visitStatus,
      notes: notes ?? this.notes,
    );
  }

  factory RouteVisitModel.fromMap(Map<String, dynamic> map) {
    return RouteVisitModel(
      id: map['id']?.toString() ?? '',
      officerId: map['officer_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? '',
      visitDate: map['visit_date']?.toString() ?? '',
      visitOrder: (map['visit_order'] as num?)?.toInt() ?? 0,
      address: map['address']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      estimatedTime: map['estimated_time']?.toString(),
      visitStatus: map['visit_status']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'officer_id': officerId,
        'client_id': clientId,
        'client_name': clientName,
        'visit_date': visitDate,
        'visit_order': visitOrder,
        'address': address,
        'lat': lat,
        'lng': lng,
        'estimated_time': estimatedTime,
        'visit_status': visitStatus,
        'notes': notes,
      };
}
