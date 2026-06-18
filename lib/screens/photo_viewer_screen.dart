import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../theme.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String title;
  final String? localPath;
  final String? remoteUrl;
  final VoidCallback? onRetake;
  final VoidCallback? onDelete;

  const PhotoViewerScreen({
    super.key,
    required this.title,
    this.localPath,
    this.remoteUrl,
    this.onRetake,
    this.onDelete,
  });

  ImageProvider? get _provider {
    if (localPath != null &&
        localPath!.isNotEmpty &&
        File(localPath!).existsSync()) {
      return FileImage(File(localPath!));
    }
    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      return NetworkImage(remoteUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kPrimaryBlue,
        actions: [
          if (onRetake != null)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Retomar',
              onPressed: () {
                Navigator.pop(context);
                onRetake!();
              },
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar foto'),
                    content: const Text('¿Desea eliminar esta captura?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.pop(context);
                  onDelete!();
                }
              },
            ),
        ],
      ),
      body: provider == null
          ? const Center(
              child: Text(
                'Sin imagen',
                style: TextStyle(color: Colors.white),
              ),
            )
          : PhotoView(
              imageProvider: provider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
    );
  }
}
