import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_slot_model.dart';
import '../providers/document_capture_notifier.dart';
import '../theme.dart';
import 'camera_capture_page.dart';
import 'photo_viewer_screen.dart';

class DocumentCaptureScreen extends ConsumerStatefulWidget {
  final String? clientId;
  final String? clientDni;
  final String? clientName;
  final String? officerId;
  final String? applicationId;

  const DocumentCaptureScreen({
    super.key,
    this.clientId,
    this.clientDni,
    this.clientName,
    this.officerId,
    this.applicationId,
  });

  @override
  ConsumerState<DocumentCaptureScreen> createState() =>
      _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends ConsumerState<DocumentCaptureScreen> {
  DocumentSession get _session => DocumentSession(
        clientId: widget.clientId ?? '',
        dni: widget.clientDni ?? '',
        clientName: widget.clientName ?? '',
        officerId: widget.officerId,
        applicationId: widget.applicationId,
      );

  Future<void> _openCamera(DocumentSlotDefinition slot) async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraCapturePage(slot: slot),
      ),
    );
    if (path == null || !mounted) return;
    await ref
        .read(documentCaptureNotifierProvider(_session).notifier)
        .captureFromFile(slot.id, path);
  }

  void _openViewer(DocumentSlotDefinition slot, CapturedDocument doc) {
    final notifier = ref.read(documentCaptureNotifierProvider(_session).notifier);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          title: slot.label,
          localPath: doc.localPath.isNotEmpty ? doc.localPath : null,
          remoteUrl: doc.remoteUrl,
          onRetake: () => _openCamera(slot),
          onDelete: () => notifier.removeDocument(slot.id),
        ),
      ),
    );
  }

  void _onSlotTap(DocumentSlotDefinition slot) {
    final state = ref.read(documentCaptureNotifierProvider(_session));
    final doc = state.doc(slot.id);
    if (doc != null &&
        (doc.localPath.isNotEmpty ||
            (doc.remoteUrl != null && doc.remoteUrl!.isNotEmpty))) {
      _openViewer(slot, doc);
    } else {
      _openCamera(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentCaptureNotifierProvider(_session));

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Captura de documentos'),
        actions: [
          if (state.isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimaryYellow,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Sincronizar Supabase',
              onPressed: () => ref
                  .read(documentCaptureNotifierProvider(_session).notifier)
                  .syncAllToSupabase(),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.clientName != null && widget.clientName!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: kPrimaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.clientDni != null && widget.clientDni!.isNotEmpty)
                    Text(
                      'DNI: ${widget.clientDni}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Obligatorios: ${state.requiredListo}/${state.requiredTotal} LISTOS',
                    style: TextStyle(
                      color: state.allRequiredListo
                          ? Colors.greenAccent
                          : kPrimaryYellow,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          if (state.successMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                state.successMessage!,
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Obligatorios',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            height: 168,
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: DocumentSlotDefinition.all
                        .where((s) => s.required)
                        .length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final slot = DocumentSlotDefinition.all
                          .where((s) => s.required)
                          .elementAt(i);
                      return _DocGalleryCard(
                        slot: slot,
                        doc: state.doc(slot.id),
                        onTap: () => _onSlotTap(slot),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Opcionales',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  DocumentSlotDefinition.all.where((s) => !s.required).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final slot = DocumentSlotDefinition.all
                    .where((s) => !s.required)
                    .elementAt(i);
                return _DocGalleryCard(
                  slot: slot,
                  doc: state.doc(slot.id),
                  onTap: () => _onSlotTap(slot),
                );
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryYellow,
                foregroundColor: kPrimaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: state.allRequiredListo
                  ? () {
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expediente documental completo'),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Finalizar expediente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocGalleryCard extends StatelessWidget {
  final DocumentSlotDefinition slot;
  final CapturedDocument? doc;
  final VoidCallback onTap;

  const _DocGalleryCard({
    required this.slot,
    required this.doc,
    required this.onTap,
  });

  bool get _hasImage {
    if (doc == null) return false;
    if (doc!.localPath.isNotEmpty && File(doc!.localPath).existsSync()) {
      return true;
    }
    return doc!.remoteUrl != null && doc!.remoteUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final status = doc?.status ?? DocumentCaptureStatus.pendiente;
    final isListo = status == DocumentCaptureStatus.listo && _hasImage;
    final label = isListo ? 'LISTO' : 'PENDIENTE';
    final badgeColor = isListo ? const Color(0xFF2E7D32) : Colors.orange.shade800;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 128,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: 128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isListo ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    width: isListo ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: _hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            if (doc!.localPath.isNotEmpty &&
                                File(doc!.localPath).existsSync())
                              Image.file(
                                File(doc!.localPath),
                                fit: BoxFit.cover,
                              )
                            else if (doc!.remoteUrl != null)
                              Image.network(
                                doc!.remoteUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _placeholder(slot),
                              ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 20,
                              ),
                            ),
                          ],
                        )
                      : _placeholder(slot),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              slot.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(DocumentSlotDefinition slot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(slot.icon, size: 36, color: kPrimaryBlue.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        const Icon(Icons.add_a_photo, size: 18, color: kPrimaryBlue),
      ],
    );
  }
}
