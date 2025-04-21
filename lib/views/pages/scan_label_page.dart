import 'dart:io';
import 'package:azimutree/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:azimutree/data/global_camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanLabelPage extends StatefulWidget {
  const ScanLabelPage({super.key});

  @override
  State<ScanLabelPage> createState() => _ScanLabelPageState();
}

class _ScanLabelPageState extends State<ScanLabelPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _image;
  String extractedText = "Memproses...";
  List<TextElement> textElements = [];
  String imagePath = '';
  Size imageSize = Size.zero;

  Future<void> _processImageFromAsset(XFile imageData) async {
    final inputImage = InputImage.fromFilePath(imageData.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    final file = File(imageData.path);
    final decodedImage = await decodeImageFromList(file.readAsBytesSync());
    await textRecognizer.close();

    List<TextElement> elements = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        elements.addAll(line.elements);
      }
    }

    setState(() {
      extractedText = recognizedText.text;
      textElements = elements;
      imagePath = imageData.path;
      imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      globalCameras.first, // atau pilih kamera belakang
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SingleChildScrollView(
            child: Column(
              children: [
                if (_image != null)
                  Stack(
                    children: [
                      Image.file(
                        File(_image!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final displayedWidth = constraints.maxWidth;
                          final aspectRatio =
                              imageSize.width != 0
                                  ? imageSize.height / imageSize.width
                                  : 1;
                          final displayedHeight = displayedWidth * aspectRatio;

                          return SizedBox(
                            width: displayedWidth,
                            height: displayedHeight,
                            child: CustomPaint(
                              painter: TextBoundingBoxPainter(
                                elements: textElements,
                                originalImageSize: imageSize,
                                displayedImageSize: Size(
                                  displayedWidth,
                                  displayedHeight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  CameraPreview(_controller),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Pilih gambar dari galeri
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1F4226),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload, color: Colors.white),
                          Text(
                            " Upload",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller.takePicture();
                          await _processImageFromAsset(image);
                          setState(() {
                            _image = image;
                          });
                          // Lakukan sesuatu dengan gambar yang diambil
                        } catch (e) {
                          print("Error mssg: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1F4226),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white),
                          Text(
                            " Camera",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                const Text(
                  "Hasil OCR:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(extractedText),
                ),
                SizedBox(height: 20),
                ValueListenableBuilder(
                  valueListenable: selectedPageNotifier,
                  builder: (context, selectedPage, child) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        selectedPageNotifier.value = "home";
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF1F4226),
                        minimumSize: const Size(50, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.skip_previous),
                      label: const Text("Back"),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class TextBoundingBoxPainter extends CustomPainter {
  final List<TextElement> elements;
  final Size originalImageSize;
  final Size displayedImageSize;

  TextBoundingBoxPainter({
    required this.elements,
    required this.originalImageSize,
    required this.displayedImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    double scaleX = displayedImageSize.width / originalImageSize.width;
    double scaleY = displayedImageSize.height / originalImageSize.height;

    for (final element in elements) {
      final rect = element.boundingBox;
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
