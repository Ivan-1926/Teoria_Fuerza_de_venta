import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProcessedImageResult {
  final String path;
  final double sharpnessScore;
  final bool isSharp;
  final int bytesAfterCompress;

  const ProcessedImageResult({
    required this.path,
    required this.sharpnessScore,
    required this.isSharp,
    required this.bytesAfterCompress,
  });
}

/// Compresión automática y validación de nitidez (varianza Laplaciana).
class DocumentImageProcessor {
  static const double minSharpness = 80.0;
  static const int maxWidth = 1920;
  static const int quality = 82;

  static Future<ProcessedImageResult> process(String sourcePath) async {
    final compressed = await _compress(sourcePath);
    final sharpness = await _laplacianVariance(compressed);
    final isSharp = sharpness >= minSharpness;
    final bytes = await File(compressed).length();
    return ProcessedImageResult(
      path: compressed,
      sharpnessScore: sharpness,
      isSharp: isSharp,
      bytesAfterCompress: bytes,
    );
  }

  static Future<String> _compress(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final out = p.join(
      dir.path,
      'doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      out,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxWidth,
      format: CompressFormat.jpeg,
    );
    return result?.path ?? sourcePath;
  }

  static Future<double> _laplacianVariance(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0;

      final gray = img.grayscale(
        img.copyResize(decoded, width: 320),
      );

      double sum = 0;
      double sumSq = 0;
      int count = 0;

      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final c = gray.getPixel(x, y).r.toDouble();
          final lap = -4 * c +
              gray.getPixel(x - 1, y).r +
              gray.getPixel(x + 1, y).r +
              gray.getPixel(x, y - 1).r +
              gray.getPixel(x, y + 1).r;
          sum += lap;
          sumSq += lap * lap;
          count++;
        }
      }

      if (count == 0) return 0;
      final mean = sum / count;
      return (sumSq / count) - (mean * mean);
    } catch (_) {
      return 50;
    }
  }
}
