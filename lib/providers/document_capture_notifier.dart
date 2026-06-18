import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_slot_model.dart';
import '../repositories/document_repository.dart';
import '../services/document_image_processor.dart';

class DocumentSession {
  final String clientId;
  final String dni;
  final String clientName;
  final String? officerId;
  final String? applicationId;

  const DocumentSession({
    this.clientId = '',
    required this.dni,
    this.clientName = '',
    this.officerId,
    this.applicationId,
  });
}

class DocumentCaptureState {
  final Map<DocumentSlotId, CapturedDocument> captures;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final String? successMessage;

  const DocumentCaptureState({
    this.captures = const {},
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
    this.successMessage,
  });

  CapturedDocument? doc(DocumentSlotId id) => captures[id];

  int get requiredTotal =>
      DocumentSlotDefinition.all.where((s) => s.required).length;

  int get requiredListo => DocumentSlotDefinition.all
      .where((s) => s.required)
      .where((s) => captures[s.id]?.isListo == true)
      .length;

  bool get allRequiredListo => requiredListo >= requiredTotal;

  DocumentCaptureState copyWith({
    Map<DocumentSlotId, CapturedDocument>? captures,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return DocumentCaptureState(
      captures: captures ?? this.captures,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class DocumentCaptureNotifier extends StateNotifier<DocumentCaptureState> {
  final DocumentSession session;
  final DocumentRepository _repo = DocumentRepository();

  DocumentCaptureNotifier(this.session) : super(const DocumentCaptureState()) {
    _loadRemote();
  }

  Future<void> _loadRemote() async {
    if (session.dni.isEmpty && session.clientId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final rows = await _repo.loadRemote(
        clientId: session.clientId,
        dni: session.dni,
      );
      final map = <DocumentSlotId, CapturedDocument>{...state.captures};
      for (final row in rows) {
        final doc = CapturedDocument.fromMap(row);
        if (doc.remoteUrl != null || doc.localPath.isNotEmpty) {
          map[doc.slotId] = doc;
        }
      }
      state = state.copyWith(isLoading: false, captures: map);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<CapturedDocument?> captureFromFile(
    DocumentSlotId slotId,
    String rawPath,
  ) async {
    state = state.copyWith(isUploading: true, clearMessages: true);
    try {
      final processed = await DocumentImageProcessor.process(rawPath);
      final status = processed.isSharp
          ? DocumentCaptureStatus.listo
          : DocumentCaptureStatus.pendiente;

      var doc = CapturedDocument(
        slotId: slotId,
        localPath: processed.path,
        sharpnessScore: processed.sharpnessScore,
        isSharp: processed.isSharp,
        status: status,
        capturedAt: DateTime.now(),
      );

      if (session.dni.isNotEmpty) {
        try {
          final url = await _repo.uploadFile(
            processed.path,
            session.dni,
            slotId,
          );
          doc = doc.copyWith(remoteUrl: url);
          await _repo.saveMetadata(
            doc,
            clientId: session.clientId,
            dni: session.dni,
            officerId: session.officerId,
            applicationId: session.applicationId,
          );
        } catch (_) {
          // Mantiene local si falla Supabase
        }
      }

      final updated = {...state.captures, slotId: doc};
      state = state.copyWith(
        isUploading: false,
        captures: updated,
        successMessage: processed.isSharp
            ? 'Documento LISTO'
            : 'Guardado — imagen borrosa (PENDIENTE)',
        errorMessage: processed.isSharp
            ? null
            : 'La foto no es suficientemente nítida. Retome la captura.',
      );
      return doc;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Error al procesar: $e',
      );
      return null;
    }
  }

  void removeDocument(DocumentSlotId slotId) {
    final existing = state.captures[slotId];
    if (existing != null && existing.localPath.isNotEmpty) {
      try {
        File(existing.localPath).deleteSync();
      } catch (_) {}
    }
    final updated = Map<DocumentSlotId, CapturedDocument>.from(state.captures);
    updated.remove(slotId);
    state = state.copyWith(
      captures: updated,
      successMessage: 'Documento eliminado',
      clearMessages: false,
    );
  }

  Future<void> syncAllToSupabase() async {
    if (session.dni.isEmpty) return;
    state = state.copyWith(isUploading: true, clearMessages: true);
    try {
      for (final entry in state.captures.entries) {
        final doc = entry.value;
        if (doc.remoteUrl != null) continue;
        final url = await _repo.uploadFile(
          doc.localPath,
          session.dni,
          entry.key,
        );
        final updated = doc.copyWith(remoteUrl: url);
        await _repo.saveMetadata(
          updated,
          clientId: session.clientId,
          dni: session.dni,
          officerId: session.officerId,
          applicationId: session.applicationId,
        );
        state = state.copyWith(
          captures: {...state.captures, entry.key: updated},
        );
      }
      state = state.copyWith(
        isUploading: false,
        successMessage: 'Documentos sincronizados con Supabase',
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Error al sincronizar: $e',
      );
    }
  }
}

final documentCaptureNotifierProvider = StateNotifierProvider.autoDispose
    .family<DocumentCaptureNotifier, DocumentCaptureState, DocumentSession>(
  (ref, session) => DocumentCaptureNotifier(session),
);
