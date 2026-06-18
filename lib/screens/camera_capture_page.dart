import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/document_slot_model.dart';
import '../theme.dart';
import '../widgets/guide_frame_overlay.dart';

class CameraCapturePage extends StatefulWidget {
  final DocumentSlotDefinition slot;

  const CameraCapturePage({super.key, required this.slot});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No hay cámara disponible');
        return;
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String get _hint {
    switch (widget.slot.frameType) {
      case GuideFrameType.idCard:
        return 'Encuadre el documento dentro del marco amarillo';
      case GuideFrameType.portrait:
        return 'Incluya al asesor y al cliente en el marco';
      case GuideFrameType.landscape:
        return 'Capture el frente del negocio';
      case GuideFrameType.full:
        return 'Centre el documento completo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.slot.label),
        backgroundColor: kPrimaryBlue,
      ),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: kPrimaryYellow),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    GuideFrameOverlay(
                      frameType: widget.slot.frameType,
                      hint: _hint,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kPrimaryYellow, width: 4),
                              color: Colors.white24,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
