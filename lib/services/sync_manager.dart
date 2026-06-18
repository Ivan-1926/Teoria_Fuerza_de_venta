import 'dart:io';
import 'package:flutter/foundation.dart';
import 'offline_queue.dart';
import 'supabase_api.dart';

class SyncManager {
  final OfflineQueue _queue = OfflineQueue();

  /// Intenta sincronizar todos los elementos en cola. Cada item puede contener
  /// 'document_path' (ruta local) y 'payload' (map para la tabla credit_applications).
  Future<void> syncAll() async {
    final items = await _queue.list();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        final payload = Map<String, dynamic>.from(item['payload'] ?? {});
        // Si tiene documento local, subir primero
        if (item.containsKey('document_path') && (item['document_path'] as String).isNotEmpty) {
          final local = item['document_path'] as String;
          if (File(local).existsSync()) {
            final bucket = item['document_bucket'] ?? 'documents';
            final dest = item['document_remote_path'] ?? DateTime.now().millisecondsSinceEpoch.toString();
            final publicUrl = await uploadDocumentFile(local, bucket, dest);
            payload['document_url'] = publicUrl;
          }
        }
        await createCreditApplication(payload);
        // si todo OK, remover item (ojo: removemos por índice actual - cuidado con reindex)
        await _queue.removeAt(i);
        // decrement index to account for removed
        i--;
      } catch (e) {
        if (kDebugMode) print('Sync error for item $i: $e');
        // No remover, seguir con el siguiente
      }
    }
  }
}
