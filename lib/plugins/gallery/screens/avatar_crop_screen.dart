import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart'; // ignore: unnecessary_import

/// A full-screen 1:1 ratio image crop screen.
///
/// Shows the picked image inside an [InteractiveViewer] with a fixed square
/// crop overlay. On confirm, captures the square region to a file and returns
/// the path via [Navigator.pop].
class AvatarCropScreen extends StatefulWidget {
  final XFile pickedFile;
  const AvatarCropScreen({super.key, required this.pickedFile});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _repaintKey = GlobalKey();
  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cropSize = size.width; // square = full width

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('裁剪头像', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _confirmCrop,
            child: const Text('确定', style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crop area
            RepaintBoundary(
              key: _repaintKey,
              child: ClipRRect(
                child: SizedBox(
                  width: cropSize,
                  height: cropSize,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale: 1.0,
                        maxScale: 8.0,
                        child: Image.file(
                          File(widget.pickedFile.path),
                          width: cropSize,
                          height: cropSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Crop frame border
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '缩放并拖动图片，使主体位于框内',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCrop() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Use pixelRatio 2.0 — enough for sharp avatar, half the bytes
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      // Encode as JPEG (not PNG) for much smaller file size
      final rawBytes = byteData.buffer.asUint8List();
      final jpgBytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        quality: 85,
        minWidth: 512,
        minHeight: 512,
        format: CompressFormat.jpeg,
        inSampleSize: 1,
      );

      // Write to a temp file
      final tempDir = Directory.systemTemp;
      final outputFile = File(
          '${tempDir.path}/avatar_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outputFile.writeAsBytes(Uint8List.fromList(jpgBytes));

      if (mounted) {
        Navigator.of(context).pop(outputFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('裁剪失败: $e')),
        );
      }
    }
  }
}
