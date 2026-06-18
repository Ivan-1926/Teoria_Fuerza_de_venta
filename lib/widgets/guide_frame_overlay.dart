import 'package:flutter/material.dart';
import '../models/document_slot_model.dart';
import '../theme.dart';

/// Marco guía sobre la vista previa de la cámara.
class GuideFrameOverlay extends StatelessWidget {
  final GuideFrameType frameType;
  final String hint;

  const GuideFrameOverlay({
    super.key,
    required this.frameType,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        Rect frame;
        switch (frameType) {
          case GuideFrameType.idCard:
            frame = Rect.fromCenter(
              center: Offset(w / 2, h * 0.42),
              width: w * 0.88,
              height: h * 0.28,
            );
            break;
          case GuideFrameType.portrait:
            frame = Rect.fromCenter(
              center: Offset(w / 2, h * 0.4),
              width: w * 0.72,
              height: h * 0.52,
            );
            break;
          case GuideFrameType.landscape:
            frame = Rect.fromCenter(
              center: Offset(w / 2, h * 0.4),
              width: w * 0.9,
              height: h * 0.38,
            );
            break;
          case GuideFrameType.full:
            frame = Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.55);
            break;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _DimPainter(frame),
            ),
            Positioned(
              left: frame.left,
              top: frame.top,
              width: frame.width,
              height: frame.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kPrimaryYellow, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DimPainter extends CustomPainter {
  final Rect frame;
  _DimPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
