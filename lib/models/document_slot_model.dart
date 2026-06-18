import 'package:flutter/material.dart';

/// Tipos de documento M6 — captura obligatoria y opcional.
enum DocumentSlotId {
  dniAnverso,
  dniReverso,
  fotoNegocio,
  fotoAsesorCliente,
  ruc,
  reciboServicios,
  contrato,
}

enum GuideFrameType { idCard, portrait, landscape, full }

enum DocumentCaptureStatus { pendiente, listo }

class DocumentSlotDefinition {
  final DocumentSlotId id;
  final String label;
  final String shortLabel;
  final bool required;
  final GuideFrameType frameType;
  final IconData icon;

  const DocumentSlotDefinition({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.required,
    required this.frameType,
    required this.icon,
  });

  String get storageKey => id.name;

  static const List<DocumentSlotDefinition> all = [
    DocumentSlotDefinition(
      id: DocumentSlotId.dniAnverso,
      label: 'DNI anverso',
      shortLabel: 'DNI A',
      required: true,
      frameType: GuideFrameType.idCard,
      icon: Icons.credit_card,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.dniReverso,
      label: 'DNI reverso',
      shortLabel: 'DNI R',
      required: true,
      frameType: GuideFrameType.idCard,
      icon: Icons.credit_card_outlined,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.fotoNegocio,
      label: 'Foto negocio',
      shortLabel: 'Negocio',
      required: true,
      frameType: GuideFrameType.landscape,
      icon: Icons.storefront,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.fotoAsesorCliente,
      label: 'Asesor con cliente',
      shortLabel: 'Visita',
      required: true,
      frameType: GuideFrameType.portrait,
      icon: Icons.people_alt,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.ruc,
      label: 'RUC',
      shortLabel: 'RUC',
      required: false,
      frameType: GuideFrameType.idCard,
      icon: Icons.description,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.reciboServicios,
      label: 'Recibo servicios',
      shortLabel: 'Recibo',
      required: false,
      frameType: GuideFrameType.full,
      icon: Icons.receipt_long,
    ),
    DocumentSlotDefinition(
      id: DocumentSlotId.contrato,
      label: 'Contrato',
      shortLabel: 'Contrato',
      required: false,
      frameType: GuideFrameType.full,
      icon: Icons.article,
    ),
  ];

  static DocumentSlotDefinition byId(DocumentSlotId id) =>
      all.firstWhere((s) => s.id == id);
}

class CapturedDocument {
  final DocumentSlotId slotId;
  final String localPath;
  final String? remoteUrl;
  final double sharpnessScore;
  final bool isSharp;
  final DocumentCaptureStatus status;
  final DateTime capturedAt;

  const CapturedDocument({
    required this.slotId,
    required this.localPath,
    this.remoteUrl,
    required this.sharpnessScore,
    required this.isSharp,
    required this.status,
    required this.capturedAt,
  });

  bool get isListo => status == DocumentCaptureStatus.listo;

  CapturedDocument copyWith({
    String? localPath,
    String? remoteUrl,
    double? sharpnessScore,
    bool? isSharp,
    DocumentCaptureStatus? status,
  }) {
    return CapturedDocument(
      slotId: slotId,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      sharpnessScore: sharpnessScore ?? this.sharpnessScore,
      isSharp: isSharp ?? this.isSharp,
      status: status ?? this.status,
      capturedAt: capturedAt,
    );
  }

  factory CapturedDocument.fromMap(Map<String, dynamic> m) {
    final slotName = m['doc_type']?.toString() ?? m['slot_id']?.toString() ?? '';
    DocumentSlotId slot = DocumentSlotId.dniAnverso;
    for (final s in DocumentSlotId.values) {
      if (s.name == slotName) {
        slot = s;
        break;
      }
    }
    final st = m['status']?.toString() ?? 'pendiente';
    return CapturedDocument(
      slotId: slot,
      localPath: m['local_path']?.toString() ?? '',
      remoteUrl: m['file_url']?.toString() ?? m['remote_url']?.toString(),
      sharpnessScore: (m['sharpness_score'] as num?)?.toDouble() ?? 0,
      isSharp: m['is_sharp'] == true || st == 'listo',
      status: st == 'listo'
          ? DocumentCaptureStatus.listo
          : DocumentCaptureStatus.pendiente,
      capturedAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabaseMap({
    required String clientId,
    required String dni,
    String? officerId,
    String? applicationId,
  }) =>
      {
        'client_id': clientId.isNotEmpty ? clientId : null,
        'dni': dni,
        'doc_type': slotId.name,
        'file_url': remoteUrl,
        'status': status.name,
        'sharpness_score': sharpnessScore,
        'is_sharp': isSharp,
        'application_id': applicationId,
        'officer_id': officerId,
        'captured_at': capturedAt.toIso8601String(),
      };
}
