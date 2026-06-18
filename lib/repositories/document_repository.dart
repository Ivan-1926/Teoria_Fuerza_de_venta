import '../models/document_slot_model.dart';
import '../services/supabase_api.dart';

class DocumentRepository {
  Future<List<Map<String, dynamic>>> loadRemote({
    String? clientId,
    String? dni,
  }) =>
      fetchClientDocuments(clientId: clientId, dni: dni);

  Future<String> uploadFile(String localPath, String dni, DocumentSlotId slot) {
    final dest =
        '$dni/${slot.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadDocumentFile(localPath, 'documents', dest);
  }

  Future<Map<String, dynamic>> saveMetadata(
    CapturedDocument doc, {
    required String clientId,
    required String dni,
    String? officerId,
    String? applicationId,
  }) {
    return saveClientDocument(
      doc.toSupabaseMap(
        clientId: clientId,
        dni: dni,
        officerId: officerId,
        applicationId: applicationId,
      ),
    );
  }
}
